#!/bin/bash
set -euo pipefail

# ==========================================
#      MIKHMON PREMIUM INSTALLER v1.1
#             ✨ BY HENDRI ✨
# ==========================================

# COLOR STYLES (PREMIUM)
BOLD="\e[1m"
RESET="\e[0m"

RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
BLUE="\e[94m"
MAGENTA="\e[95m"
CYAN="\e[96m"
WHITE="\e[97m"
BLACK="\e[30m"         # FIX: DITAMBAHKAN AGAR TIDAK ERROR

BG_BLUE="\e[44m"
BG_MAGENTA="\e[45m"
BG_CYAN="\e[46m"

# ==========================================
# PREMIUM WATERMARK — HEADER
# ==========================================
echo -e ""
echo -e "${BG_MAGENTA}${WHITE}${BOLD}============================================================${RESET}"
echo -e "${BG_MAGENTA}${WHITE}${BOLD}        🔥 MIKHMON MULTI-INSTALLER — PREMIUM EDITION 🔥       ${RESET}"
echo -e "${BG_MAGENTA}${WHITE}${BOLD}                     BY HENDRI • 2025                       ${RESET}"
echo -e "${BG_MAGENTA}${WHITE}${BOLD}============================================================${RESET}"
echo -e ""
echo -e "${CYAN}${BOLD}Installer ini akan menyiapkan:${RESET}"
echo -e "${WHITE}• Multi Mikhmon Instance"
echo -e "• HTTPS Certbot SSL"
echo -e "• Nginx Web Server"
echo -e "• Auto Clone Repo + Auto Konfigurasi${RESET}"
echo ""
echo -e "${GREEN}${BOLD}Support:${RESET}"
echo -e "${YELLOW}📩 Email   :${RESET} ${WHITE}heruu2004@gmail.com"
echo -e "${YELLOW}🔥 Telegram:${RESET} ${WHITE}https://t.me/GbtTapiPngnSndiri${RESET}"
echo ""

# ==========================================
# REPOSITORY
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
# PREMIUM ERROR HANDLER
# ==========================================
error_handler() {
    echo -e "${RED}${BOLD}"
    echo "============================================================"
    echo "⚠️  INSTALLER GAGAL — PREMIUM EDITION"
    echo "============================================================"
    echo -e "${RESET}${WHITE}Error terdeteksi! Silakan kirim screenshot ke kontak berikut:${RESET}"
    echo -e "${YELLOW}📩 Email   :${RESET} ${WHITE}heruu2004@gmail.com"
    echo -e "${YELLOW}🔥 Telegram:${RESET} ${WHITE}https://t.me/GbtTapiPngnSndiri${RESET}"
    echo -e "${RED}${BOLD}============================================================${RESET}"
}
trap error_handler ERR

# ==========================================
# WAIT APT LOCK
# ==========================================
wait_apt_lock() {
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        sleep 3
    done
}

# ==========================================
# PACKAGES
# ==========================================
install_base() {
    wait_apt_lock
    echo -e "${BLUE}${BOLD}[1/4] Menginstall paket dasar...${RESET}"
    apt update -y
    apt install -y sudo nano nginx curl zip unzip git \
        php php-fpm php-cli php-zip php-curl php-xml php-mbstring \
        certbot python3-certbot-nginx
}


# ==========================================
# AUTO DETECT PHP VERSION & SOCKET
# ==========================================
detect_php() {
    PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || true)

    if [[ -z "$PHP_VER" ]]; then
        echo -e "${RED}PHP belum terinstall atau gagal terdeteksi${RESET}"
        exit 1
    fi

    PHP_FPM_SERVICE="php${PHP_VER}-fpm"
    PHP_SOCK="/run/php/php${PHP_VER}-fpm.sock"

    if [[ ! -S "$PHP_SOCK" ]]; then
        echo -e "${RED}Socket PHP-FPM tidak ditemukan: $PHP_SOCK${RESET}"
        exit 1
    fi
}

# ==========================================
# OPTIMIZE PHP & PHP-FPM (ANTI 502 / 504)
# ==========================================
optimize_php() {
    echo -e "${BLUE}${BOLD}• Optimasi PHP-FPM & php.ini...${RESET}"

    PHP_INI="/etc/php/$PHP_VER/fpm/php.ini"
    POOL_CONF="/etc/php/$PHP_VER/fpm/pool.d/www.conf"

    # php.ini
    sed -i 's/^memory_limit.*/memory_limit = 512M/' $PHP_INI
    sed -i 's/^max_execution_time.*/max_execution_time = 300/' $PHP_INI
    sed -i 's/^upload_max_filesize.*/upload_max_filesize = 64M/' $PHP_INI
    sed -i 's/^post_max_size.*/post_max_size = 64M/' $PHP_INI

    # php-fpm pool
sed -i \
    -e 's|^pm = .*|pm = dynamic|' \
    -e 's|^pm.max_children =.*|pm.max_children = 30|' \
    -e 's|^pm.start_servers =.*|pm.start_servers = 5|' \
    -e 's|^pm.min_spare_servers =.*|pm.min_spare_servers = 5|' \
    -e 's|^pm.max_spare_servers =.*|pm.max_spare_servers = 15|' \
    "$POOL_CONF"


    systemctl restart "$PHP_FPM_SERVICE"
}

# ==========================================
# MENU PILIH VERSI
# ==========================================
choose_version() {
    echo ""
    echo -e "${MAGENTA}${BOLD}Pilih versi Mikhmon:${RESET}"
    echo -e "${CYAN}1) Mikhmon-Agent${RESET}"
    echo -e "${CYAN}2) Mikhmon PPPoE ROS 6${RESET}"
    echo -e "${CYAN}3) Mikhmon PPPoE ROS 7${RESET}"
    echo -e "${CYAN}4) Mikhmon GenieACS Integration${RESET}"
    echo ""
    read -p "Masukkan pilihan (1-4): " choice

    case $choice in
        1) REPO=$REPO_AGENT; NAME="mikhmon-agent"; README=$README_AGENT ;;
        2) REPO=$REPO_PPP6; NAME="mikhmon-ppp6"; README=$README_PPP6 ;;
        3) REPO=$REPO_PPP7; NAME="mikhmon-ppp7"; README=$README_PPP7 ;;
        4) REPO=$REPO_GENIEACS; NAME="mikhmon-genieacs"; README=$README_GENIEACS ;;
        *) echo -e "${RED}Pilihan salah.${RESET}"; exit 1 ;;
    esac
}

# ==========================================
# CONFIGURE NGINX
# ==========================================
setup_nginx() {
    DOMAIN=$1
    FOLDER=$2

    echo -e "${BLUE}${BOLD}[2/4] Mengkonfigurasi Nginx...${RESET}"

    cat > /etc/nginx/sites-available/$DOMAIN <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/$FOLDER;
    index index.php index.html;

    client_max_body_size 64M;


    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCK;
        fastcgi_read_timeout 300;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;

    }
}
EOF

    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
}

# ==========================================
# HTTPS
# ==========================================
setup_https() {
    DOMAIN=$1
    echo -e "${BLUE}${BOLD}[3/4] Mengatur HTTPS (Certbot)...${RESET}"
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN" || true
}

# ==========================================
# INSTALL MIKHMON
# ==========================================
install_mikhmon() {
    read -p "Masukkan domain (Contoh: mikhmon.hendri.com): " DOMAIN
    read -p "Masukkan nama folder (Contoh: mikhmon-hendri): " FOLDER

    echo -e "${BLUE}${BOLD}[4/4] Menginstall Mikhmon...${RESET}"

    mkdir -p /var/www/$FOLDER
    git clone $REPO /var/www/$FOLDER/
    chown -R www-data:www-data /var/www/$FOLDER

    detect_php
    optimize_php

    setup_nginx "$DOMAIN" "$FOLDER"
    setup_https "$DOMAIN"
    restart_services

    echo -e ""
    echo -e "${GREEN}${BOLD}============================================================"
    echo -e "✔ INSTALLASI SELESAI — PREMIUM EDITION"
    echo -e "============================================================${RESET}"
    echo -e "${WHITE}URL Akses :${RESET} ${CYAN}https://$DOMAIN${RESET}"
    echo -e "${WHITE}Folder    :${RESET} ${CYAN}/var/www/$FOLDER${RESET}"
    echo -e ""
    echo -e "${YELLOW}${BOLD}Panduan Penggunaan:${RESET}"
    echo -e "${CYAN}$README${RESET}"
    echo -e "${GREEN}${BOLD}============================================================${RESET}"
    echo ""

    # PREMIUM WATERMARK
    echo -e "${BG_CYAN}${BLACK}${BOLD}      TERIMA KASIH TELAH MENGGUNAKAN INSTALLER PREMIUM      ${RESET}"
    echo -e "${BG_CYAN}${BLACK}${BOLD}               BY HENDRI — NATVPS/VPS                       ${RESET}"
    echo ""
}

# ==========================================
# RESTART SERVICES (SAFE)
# ==========================================
restart_services() {
    systemctl restart nginx
    systemctl restart "$PHP_FPM_SERVICE"
}

# ==========================================
# MAIN SYSTEM
# ==========================================
main_menu() {
    install_base
    choose_version
    install_mikhmon

    echo ""
    read -p "Hapus script installer ini? (y/n): " H
    if [[ "$H" == "y" ]]; then
        rm -- "$0"
        echo -e "${GREEN}Installer berhasil dihapus.${RESET}"
    fi
}

main_menu
