#!/bin/bash
set -euo pipefail

# ==========================================
#      MIKHMON PREMIUM INSTALLER v1.2
#        STABLE • ANTI 502 / 504
# ==========================================

# COLOR
BOLD="\e[1m"
RESET="\e[0m"
RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
BLUE="\e[94m"
CYAN="\e[96m"
WHITE="\e[97m"
BLACK="\e[30m"
BG_MAGENTA="\e[45m"
BG_CYAN="\e[46m"

# ==========================================
# HEADER
# ==========================================
clear
echo -e "${BG_MAGENTA}${WHITE}${BOLD}============================================================${RESET}"
echo -e "${BG_MAGENTA}${WHITE}${BOLD}     MIKHMON MULTI-INSTALLER • STABLE EDITION                ${RESET}"
echo -e "${BG_MAGENTA}${WHITE}${BOLD}     OPTIMIZED NGINX + PHP-FPM (ANTI 502/504)                ${RESET}"
echo -e "${BG_MAGENTA}${WHITE}${BOLD}============================================================${RESET}"
echo ""

# ==========================================
# ERROR HANDLER
# ==========================================
error_handler() {
    echo -e "${RED}${BOLD}"
    echo "============================================================"
    echo "INSTALLER GAGAL"
    echo "============================================================"
    echo -e "${RESET}${YELLOW}Cek:"
    echo "- status nginx"
    echo "- status php-fpm"
    echo "- log /var/log/nginx/error.log"
    echo "============================================================"
}
trap error_handler ERR

# ==========================================
# BASE INSTALL
# ==========================================
install_base() {
    echo -e "${BLUE}${BOLD}[1/5] Install paket dasar...${RESET}"
    apt update -y
    apt install -y nginx curl zip unzip git sudo nano \
        php php-fpm php-cli php-zip php-curl php-xml php-mbstring \
        certbot python3-certbot-nginx
}

# ==========================================
# DETECT PHP VERSION
# ==========================================
detect_php() {
    PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    PHP_SOCK="/run/php/php${PHP_VER}-fpm.sock"
    PHP_FPM_SERVICE="php${PHP_VER}-fpm"

    if [[ ! -S "$PHP_SOCK" ]]; then
        echo -e "${RED}Socket PHP-FPM tidak ditemukan: $PHP_SOCK${RESET}"
        exit 1
    fi
}

# ==========================================
# OPTIMIZE PHP-FPM
# ==========================================
optimize_php() {
    echo -e "${BLUE}${BOLD}[2/5] Optimasi PHP-FPM...${RESET}"

    PHP_INI="/etc/php/$PHP_VER/fpm/php.ini"
    POOL_CONF="/etc/php/$PHP_VER/fpm/pool.d/www.conf"

    sed -i 's/^memory_limit.*/memory_limit = 512M/' $PHP_INI
    sed -i 's/^max_execution_time.*/max_execution_time = 300/' $PHP_INI
    sed -i 's/^upload_max_filesize.*/upload_max_filesize = 64M/' $PHP_INI
    sed -i 's/^post_max_size.*/post_max_size = 64M/' $PHP_INI

    sed -i 's/^pm = .*/pm = dynamic/' $POOL_CONF
    sed -i 's/^pm.max_children.*/pm.max_children = 30/' $POOL_CONF
    sed -i 's/^pm.start_servers.*/pm.start_servers = 5/' $POOL_CONF
    sed -i 's/^pm.min_spare_servers.*/pm.min_spare_servers = 5/' $POOL_CONF
    sed -i 's/^pm.max_spare_servers.*/pm.max_spare_servers = 15/' $POOL_CONF

    systemctl restart $PHP_FPM_SERVICE
}

# ==========================================
# NGINX CONFIG
# ==========================================
setup_nginx() {
    DOMAIN=$1
    FOLDER=$2

    echo -e "${BLUE}${BOLD}[3/5] Konfigurasi Nginx...${RESET}"

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
    nginx -t
    systemctl reload nginx
}

# ==========================================
# HTTPS
# ==========================================
setup_https() {
    DOMAIN=$1
    echo -e "${BLUE}${BOLD}[4/5] Setup HTTPS...${RESET}"
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN" || true
}

# ==========================================
# INSTALL APP
# ==========================================
install_mikhmon() {
    read -p "Domain (contoh: mikhmon.domain.com): " DOMAIN
    read -p "Nama folder: " FOLDER

    mkdir -p /var/www/$FOLDER
    git clone "$REPO" /var/www/$FOLDER
    chown -R www-data:www-data /var/www/$FOLDER

    setup_nginx "$DOMAIN" "$FOLDER"
    setup_https "$DOMAIN"

    echo -e "${GREEN}${BOLD}INSTALLASI SELESAI${RESET}"
    echo -e "URL : https://$DOMAIN"
}

# ==========================================
# REPO MENU
# ==========================================
choose_version() {
    echo "1) Mikhmon Agent"
    echo "2) Mikhmon PPPoE ROS 6"
    echo "3) Mikhmon PPPoE ROS 7"
    echo "4) Mikhmon GenieACS"
    read -p "Pilih (1-4): " C

    case $C in
        1) REPO="https://github.com/heruhendri/mikhmon-agent" ;;
        2) REPO="https://github.com/heruhendri/Mikhmon-PPPoE-Ros.6" ;;
        3) REPO="https://github.com/heruhendri/Mikhmon-PPPoE-Ros.7" ;;
        4) REPO="https://github.com/heruhendri/Mikhmon-GenieAcs-WAgateway" ;;
        *) exit 1 ;;
    esac
}

# ==========================================
# MAIN
# ==========================================
main() {
    install_base
    detect_php
    optimize_php
    choose_version
    install_mikhmon
}

main
