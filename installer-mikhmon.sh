#!/bin/bash
set -euo pipefail

# ==========================================
#  MIKHMON MULTI-INSTALLER + HTTPS + NGINX
#  BY HENDRI
# ==========================================

REPO_AGENT="https://github.com/heruhendri/mikhmon-agent"
REPO_PPP6="https://github.com/heruhendri/Mikhmon-PPPoE-Ros.6"
REPO_PPP7="https://github.com/heruhendri/Mikhmon-PPPoE-Ros.7"
REPO_GENIEACS="https://github.com/heruhendri/Mikhmon-GenieAcs-WAgateway"

# ---- Installer dependencies ----
install_base() {
    apt update -y
    apt install -y nginx curl zip unzip git php php-fpm php-cli php-zip php-curl php-xml php-mbstring certbot python3-certbot-nginx
    systemctl enable nginx
    systemctl start nginx
}

# ---- Menu pilihan versi Mikhmon ----
choose_version() {
    echo ""
    echo "Pilih versi Mikhmon yang ingin di-install:"
    echo "1) Mikhmon-Agent"
    echo "2) Mikhmon PPPoE ROS 6"
    echo "3) Mikhmon PPPoE ROS 7"
    echo "4) Mikhmon GenieACS Integration"
    read -p "Masukkan pilihan (1-4): " choice

    case $choice in
        1) REPO=$REPO_AGENT; NAME="mikhmon-agent" ;;
        2) REPO=$REPO_PPP6; NAME="mikhmon-ppp6" ;;
        3) REPO=$REPO_PPP7; NAME="mikhmon-ppp7" ;;
        4) REPO=$REPO_GENIEACS; NAME="mikhmon-genieacs" ;;
        *) echo "Pilihan salah"; exit 1;;
    esac
}

# ---- Setup HTTPS ----
setup_https() {
    DOMAIN=$1

    echo "Mengatur HTTPS untuk domain $DOMAIN ..."
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN" || {
        echo "Certbot gagal, lanjutkan manual setelah install."
    }
}

# ---- Setup Nginx ----
setup_nginx() {
    DOMAIN=$1
    FOLDER=$2

    echo "Membuat konfigurasi Nginx untuk $DOMAIN ..."

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

# ---- Install Mikhmon instance ----
install_mikhmon() {
    read -p "Masukkan domain/subdomain (contoh: m1.domain.com): " DOMAIN
    read -p "Masukkan nama folder instance (contoh: m1): " FOLDER

    mkdir -p /var/www/$FOLDER
    git clone $REPO /var/www/$FOLDER/

    chown -R www-data:www-data /var/www/$FOLDER

    setup_nginx "$DOMAIN" "$FOLDER"
    setup_https "$DOMAIN"

    echo ""
    echo "=============================================="
    echo "   INSTALLASI MIKHMON SELESAI!"
    echo "   URL: https://$DOMAIN"
    echo "   Folder: /var/www/$FOLDER"
    echo "=============================================="
}

# ---- Menu utama ----
main_menu() {
    install_base
    choose_version
    install_mikhmon

    echo ""
    read -p "Hapus script installer ini? (y/n): " HAPUS
    if [[ "$HAPUS" == "y" ]]; then
        rm -- "$0"
    fi
}

main_menu
