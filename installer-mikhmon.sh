#!/bin/bash
set -euo pipefail

# ==========================================
#      MIKHMON MULTI-INSTALLER + HTTPS
#              NGINX — BY HENDRI
# ==========================================

# ========== WATERMARK START INSTALL ==========
echo ""
echo "****************************************************"
echo "      MIKHMON MULTI-INSTALLER — BY HENDRI          "
echo "****************************************************"
echo " Installer ini akan mempersiapkan:"
echo " - Multi Mikhmon Instance"
echo " - Nginx Web Server"
echo " - HTTPS Certbot SSL"
echo " - Auto Folder + Auto Clone Repo"
echo ""
echo " Kontak Support jika error:"
echo " 📩 Email    :  heruu2004@gmail.com"
echo " 🔥 Telegram :  https://t.me/GbtTapiPngnSndiri"
echo "****************************************************"
echo ""

# ==========================================
# REPO LIST
# ==========================================
REPO_AGENT="https://github.com/heruhendri/mikhmon-agent"
REPO_PPP6="https://github.com/heruhendri/Mikhmon-PPPoE-Ros.6"
REPO_PPP7="https://github.com/heruhendri/Mikhmon-PPPoE-Ros.7"
REPO_GENIEACS="https://github.com/heruhendri/Mikhmon-GenieAcs-WAgateway"

README_AGENT="$REPO_AGENT#readme"
README_PPP6="$REPO_PPP6#readme"
README_PPP7="$REPO_PPP7#readme"
README_GENIEACS="$REPO_GENIEACS#readme"

# ==========================================
# ERROR WATERMARK HANDLER
# ==========================================
error_handler() {
    echo ""
    echo "=============================================="
    echo "⚠️  INSTALLER ERROR — BY HENDRI"
    echo "----------------------------------------------"
    echo "Terdapat error saat proses instalasi!"
    echo ""
    echo "📩 Email Support :  heruu2004@gmail.com"
    echo "📨 Telegram      :  https://t.me/GbtTapiPngnSndiri"
    echo "----------------------------------------------"
    echo "Silakan kirim screenshot error ke kontak di atas."
    echo "=============================================="
}
trap error_handler ERR

# ==========================================
# INSTALLER FUNCTIONS
# ==========================================

install_base() {
    echo "[*] Menginstall paket dasar..."
    apt update -y
    apt install -y sudo nano nginx curl zip unzip git \
        php php-fpm php-cli php-zip php-curl php-xml php-mbstring \
        certbot python3-certbot-nginx

    systemctl enable nginx
    systemctl start nginx
}

choose_version() {
    echo ""
    echo "Pilih versi Mikhmon yang ingin di-install:"
    echo "1) Mikhmon-Agent"
    echo "2) Mikhmon PPPoE ROS 6"
    echo "3) Mikhmon PPPoE ROS 7"
    echo "4) Mikhmon GenieACS Integration"
    read -p "Masukkan pilihan (1-4): " choice

    case $choice in
        1) REPO=$REPO_AGENT; NAME="mikhmon-agent"; README=$README_AGENT ;;
        2) REPO=$REPO_PPP6; NAME="mikhmon-ppp6"; README=$README_PPP6 ;;
        3) REPO=$REPO_PPP7; NAME="mikhmon-ppp7"; README=$README_PPP7 ;;
        4) REPO=$REPO_GENIEACS; NAME="mikhmon-genieacs"; README=$README_GENIEACS ;;
        *) echo "Pilihan salah"; exit 1 ;;
    esac
}

setup_https() {
    DOMAIN=$1
    echo "[*] Mengatur HTTPS untuk domain $DOMAIN ..."
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN" || {
        echo "Certbot gagal, lanjutkan manual setelah install."
    }
}

setup_nginx() {
    DOMAIN=$1
    FOLDER=$2

    echo "[*] Membuat konfigurasi Nginx untuk $DOMAIN ..."

    cat > /etc/nginx/sites-available/$DOMAIN <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/$FOLDER;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
}

install_mikhmon() {
    read -p "Masukkan domain/subdomain (contoh: mikhmon.hendri.com): " DOMAIN
    read -p "Masukkan nama folder instance (contoh: mikhmon-hendri): " FOLDER

    mkdir -p /var/www/$FOLDER
    git clone $REPO /var/www/$FOLDER/
    chown -R www-data:www-data /var/www/$FOLDER

    setup_nginx "$DOMAIN" "$FOLDER"
    setup_https "$DOMAIN"

    echo ""
    echo "=============================================="
    echo "   ✔ INSTALLASI MIKHMON SELESAI"
    echo "----------------------------------------------"
    echo "URL Akses : https://$DOMAIN"
    echo "Folder    : /var/www/$FOLDER"
    echo ""
    echo "Panduan Penggunaan:"
    echo "$README"
    echo "=============================================="

    # WATERMARK FINISH
    echo ""
    echo "****************************************************"
    echo "         INSTALLER SELESAI — BY HENDRI              "
    echo "****************************************************"
    echo " GitHub  : https://github.com/heruhendri"
    echo " Telegram: https://t.me/GbtTapiPngnSndiri"
    echo " Email   : heruu2004@gmail.com"
    echo "****************************************************"
    echo ""
}

main_menu() {
    install_base
    choose_version
    install_mikhmon

    echo ""
    read -p "Hapus script installer ini? (y/n): " HAPUS
    [[ "$HAPUS" == "y" ]] && rm -- "$0"
}

main_menu
