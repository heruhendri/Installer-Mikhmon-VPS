#!/usr/bin/env bash
# auto-install-mikhmon.sh
# Script auto-install MikhMon (MikhMon Multi) untuk Debian/Ubuntu
# Cara pakai: export GITHUB_REPO=https://github.com/USERNAME/REPO && bash auto-install-mikhmon.sh
# atau jalankan langsung dari raw GitHub (setelah Anda push file ini ke repo):
# curl -sSL https://raw.githubusercontent.com/USERNAME/REPO/main/auto-install-mikhmon.sh | sudo bash -s -- --domain example.com --dbpass 'Passw0rd'

set -euo pipefail
IFS=$'\n\t'

### ======= CONFIG DEFAULTS (ubah sesuai kebutuhan) =======
DOMAIN=""
REPO_URL=""        # optional: jika Anda menyimpan paket mikhmon di repo
SITE_DIR="/var/www/mikhmon"
DB_NAME="mikhmon"
DB_USER="mikhuser"
DB_PASS=""
APACHE_CONF="/etc/apache2/sites-available/mikhmon.conf"
FORCE_NO_PROMPT=0

usage(){
  cat <<EOF
Usage: sudo bash auto-install-mikhmon.sh [options]
Options:
  --domain <domain>        Optional. Domain untuk vhost (jika kosong akan pakai IP)
  --repo <git-repo-url>    Optional. Git repo URL yang berisi file MikhMon
  --dbpass <db-password>   (recommended) Password untuk DB user
  --noninteractive         Non-interactive mode (uses defaults or env vars)
  -h, --help               Show this help

Examples:
  sudo bash auto-install-mikhmon.sh --domain mikhmon.example.com --dbpass 'StrongPass123'
  curl -sSL https://raw.githubusercontent.com/USERNAME/REPO/main/auto-install-mikhmon.sh | sudo bash -s -- --domain example.com --dbpass 'pw'
EOF
}

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2;;
    --repo) REPO_URL="$2"; shift 2;;
    --dbpass) DB_PASS="$2"; shift 2;;
    --noninteractive) FORCE_NO_PROMPT=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option $1"; usage; exit 1;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "Script harus dijalankan sebagai root (sudo)." >&2
  exit 1
fi

# helper prompts
ask(){
  if [[ "$FORCE_NO_PROMPT" -eq 1 ]]; then
    echo "$2"
  else
    read -rp "$1" REPLY
    echo "$REPLY"
  fi
}

# collect missing info
if [[ -z "$DB_PASS" ]]; then
  DB_PASS=$(ask "Masukkan password untuk database user '$DB_USER' (kosong -> random): " "")
  if [[ -z "$DB_PASS" ]]; then
    DB_PASS=$(openssl rand -base64 16)
    echo "Menghasilkan password acak untuk DB: $DB_PASS"
  fi
fi

if [[ -z "$REPO_URL" ]]; then
  REPO_URL=""
fi

# detect OS
if [[ -f /etc/debian_version ]]; then
  OS_FAMILY=debian
else
  echo "Script ini hanya diuji pada Debian/Ubuntu." >&2
  exit 1
fi

echo "Memulai instalasi MikhMon..."

apt update
apt install -y apache2 mariadb-server php php-mysql php-gd php-zip php-curl unzip git curl wget

# Enable modules for Apache
a2enmod rewrite
systemctl restart apache2

# Create DB + user (assume Unix socket auth for root mysql)
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

# Deploy files
if [[ -n "$REPO_URL" ]]; then
  echo "Meng-clone repo dari $REPO_URL -> $SITE_DIR"
  rm -rf "$SITE_DIR"
  git clone --depth=1 "$REPO_URL" "$SITE_DIR"
else
  echo "Tidak ada REPO disediakan. Mengunduh paket MikhMon dari web tidak disertakan dalam script ini."
  mkdir -p "$SITE_DIR"
  chown -R www-data:www-data "$SITE_DIR"
fi

# Set permissions
chown -R www-data:www-data "$SITE_DIR"
chmod -R 755 "$SITE_DIR"

# Create Apache vhost
if [[ -n "$DOMAIN" ]]; then
  cat > "$APACHE_CONF" <<APACHE
<VirtualHost *:80>
    ServerName ${DOMAIN}
    DocumentRoot ${SITE_DIR}
    <Directory ${SITE_DIR}>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/mikhmon_error.log
    CustomLog \${APACHE_LOG_DIR}/mikhmon_access.log combined
</VirtualHost>
APACHE
  a2ensite mikhmon.conf || true
  systemctl reload apache2
fi

# Try to create a basic DB config file for MikhMon (path may vary depending on versi/packaging)
# Common locations: application/config/database.php or config.php
DB_CONFIG_CREATED=0
if [[ -d "$SITE_DIR/application/config" ]]; then
  CONF_PATH="$SITE_DIR/application/config/database.php"
  cat > "$CONF_PATH" <<PHP
<?php
\$db['default'] = array(
  'hostname' => 'localhost',
  'username' => '${DB_USER}',
  'password' => '${DB_PASS}',
  'database' => '${DB_NAME}',
  'dbdriver' => 'mysqli',
  'dbprefix' => '',
  'pconnect' => FALSE,
  'db_debug' => TRUE,
  'cache_on' => FALSE,
  'cachedir' => '',
  'char_set' => 'utf8mb4',
  'dbcollat' => 'utf8mb4_general_ci'
);
PHP
  chown www-data:www-data "$CONF_PATH"
  DB_CONFIG_CREATED=1
fi

if [[ $DB_CONFIG_CREATED -eq 0 ]]; then
  echo "Catatan: script tidak menemukan folder application/config untuk menaruh file database.php otomatis."
  echo "Silakan edit file konfigurasi MikhMon secara manual dan masukkan kredensial berikut:"
  echo "DB HOST: localhost"
  echo "DB NAME: $DB_NAME"
  echo "DB USER: $DB_USER"
  echo "DB PASS: $DB_PASS"
fi

# Create a simple index.html redirect to show installation success if repository not present
if [[ -z "$(ls -A "$SITE_DIR")" ]]; then
  cat > "$SITE_DIR/index.html" <<HTML
<html><head><meta charset="utf-8"><title>MikhMon Installed</title></head>
<body>
<h1>MikhMon siap (file web belum di-deploy)</h1>
<p>Silakan upload file MikhMon ke $SITE_DIR atau gunakan --repo untuk clone dari GitHub.</p>
</body></html>
HTML
  chown www-data:www-data "$SITE_DIR/index.html"
fi

# Restart services
systemctl restart apache2
systemctl restart mariadb

# Optionally install certbot if domain provided
if [[ -n "$DOMAIN" ]]; then
  if ! command -v certbot >/dev/null 2>&1; then
    apt install -y certbot python3-certbot-apache
  fi
  echo "Menjalankan certbot (akan meminta input untuk membuat sertifikat)..."
  certbot --apache -d "$DOMAIN" --non-interactive --agree-tos -m admin@${DOMAIN} || true
fi

# final message
cat <<EOF
Selesai.
- Web root: $SITE_DIR
- DB: $DB_NAME
- DB user: $DB_USER
- DB password: $DB_PASS

Jika Anda menaruh file MikhMon di GitHub: push file ini dan file MikhMon ke repo, lalu jalankan:
  curl -sSL https://raw.githubusercontent.com/USERNAME/REPO/main/auto-install-mikhmon.sh | sudo bash -s -- --domain yourdomain --dbpass 'yourpass'

Catatan keamanan:
- Jangan menjalankan script yang Anda dapatkan dari internet tanpa meninjau isinya.
- Gantilah password DB dengan nilai yang kuat; simpan aman.

EOF

exit 0
