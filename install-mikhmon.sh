#!/bin/bash

clear
echo "==========================================="
echo "   MIKHMON MULTI INSTALLER (AUTO DOMAIN)"
echo "==========================================="

# Update server
apt update -y
apt upgrade -y

# Install dependencies
apt install -y nginx mariadb-server git unzip \
  software-properties-common certbot python3-certbot-nginx

# Install PHP
apt install -y php php-fpm php-cli php-mysql php-xml php-zip php-curl php-gd php-mbstring

# Restart PHP-FPM
systemctl restart php*-fpm

# Folder base
BASE_DIR="/var/www/mikhmon"

mkdir -p $BASE_DIR

echo ""
echo "Berapa banyak instance Mikhmon yang ingin di-install?"
read -p "Jumlah: " TOTAL

for (( i=1; i<=$TOTAL; i++ ))
do
  echo ""
  echo "=== Instance $i ==="
  read -p "Masukkan nama folder (contoh: mikhmon1): " FOLDER
  read -p "Masukkan domain/subdomain (contoh: mikhmon.domain.com): " DOMAIN

  INST_DIR="$BASE_DIR/$FOLDER"

  echo ""
  echo "[*] Meng-clone repo Mikhmon..."
  git clone https://github.com/heruhendri/Mikhmon-PPPoE-Ros.6 $INST_DIR

  echo "[*] Mengatur permission..."
  chown -R www-data:www-data $INST_DIR
  chmod -R 755 $INST_DIR

  echo "[*] Membuat database..."
  DB_NAME="db_${FOLDER}"
  DB_USER="${FOLDER}_user"
  DB_PASS=$(openssl rand -hex 6)

  mysql -e "CREATE DATABASE ${DB_NAME};"
  mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
  mysql -e "FLUSH PRIVILEGES;"

  echo "Database: $DB_NAME"
  echo "User: $DB_USER"
  echo "Password: $DB_PASS"

  echo ""
  echo "[*] Membuat konfigurasi Nginx..."
  
  VHOST="/etc/nginx/sites-available/$DOMAIN"

  cat > $VHOST <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $INST_DIR;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

  ln -s $VHOST /etc/nginx/sites-enabled/

  echo "[*] Restarting Nginx..."
  systemctl restart nginx

  echo ""
  echo "[*] Instalasi SSL..."
  certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

  echo ""
  echo "==============================================="
  echo "  INSTANSI $FOLDER SELESAI"
  echo "  URL : https://$DOMAIN"
  echo "  DB  : $DB_NAME"
  echo "  USER: $DB_USER"
  echo "  PASS: $DB_PASS"
  echo "==============================================="
  echo ""
done

echo "==============================================="
echo "  SEMUA INSTAN MIKHMON BERHASIL DIINSTALL"
echo "==============================================="
