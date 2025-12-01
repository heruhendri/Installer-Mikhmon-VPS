#!/bin/bash
set -euo pipefail

# ==========================================
#   COLOR & STYLE
# ==========================================
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
MAGENTA="\e[35m"
BOLD="\e[1m"
RESET="\e[0m"

# ==========================================
#   WATERMARK — START INSTALL
# ==========================================
clear
echo -e ""
echo -e "${MAGENTA}${BOLD}┌────────────────────────────────────────────────────────────┐${RESET}"
echo -e "${MAGENTA}${BOLD}│        🚀 MIKHMON MULTI-INSTALLER + HTTPS — BY HENDRI      │${RESET}"
echo -e "${MAGENTA}${BOLD}└────────────────────────────────────────────────────────────┘${RESET}"
echo -e "${CYAN}${BOLD}Installer ini akan mempersiapkan environment lengkap:${RESET}"
echo -e "${GREEN}✔ Multi Instance Mikhmon"
echo -e "✔ Nginx Web Server"
echo -e "✔ HTTPS Certbot SSL"
echo -e "✔ Auto Clone Repo + Auto Konfigurasi Nginx${RESET}"
echo ""
echo -e "${YELLOW}Jika terjadi error, hubungi:${RESET}"
echo -e "${BLUE}📩 Email   :${RESET} heruu2004@gmail.com"
echo -e "${BLUE}🔥 Telegram:${RESET} https://t.me/GbtTapiPngnSndiri"
echo -e "${MAGENTA}${BOLD}──────────────────────────────────────────────────────────────${RESET}"
echo ""

# ==========================================
#  REPO LIST
# ==========================================
REPO_AGENT="https://github.com/heruhendri/mikhmon-agent"
REPO_PPP6="https://github.com/heruhendri/Mikhmon-PPPoE-Ros.6"
REPO_PPP7="https://github.com/heruhendendri/Mikhmon-PPPoE-Ros.7"
REPO_GENIEACS="https://github.com/heruhendri/Mikhmon-GenieAcs-WAgateway"

README_AGENT="$REPO_AGENT#readme"
README_PPP6="$REPO_PPP6#readme"
README_PPP7="$REPO_PPP7#readme"
README_GENIEACS="$REPO_GENIEACS#readme"

# ==========================================
# ERROR WATERMARK
# ==========================================
error_handler() {
    echo -e ""
    echo -e "${RED}${BOLD}┌────────────────────────────────────────────┐${RESET}"
    echo -e "${RED}${BOLD}│ ⚠️  INSTALLER ERROR — BY HENDRI            │${RESET}"
    echo -e "${RED}${BOLD}└────────────────────────────────────────────┘${RESET}"
    echo -e "${RED}Terdapat error saat proses instalasi!${RESET}"
    echo ""
    echo -e "${BLUE}📩 Email   :${RESET}  heruu2004@gmail.com"
    echo -e "${BLUE}📨 Telegram:${RESET} https://t.me/GbtTapiPngnSndiri"
    echo -e ""
    echo -e "${YELLOW}Silakan kirim screenshot error ke kontak di atas.${RESET}"
}
trap error_handler ERR

# ==========================================
# FUNCTIONS
# ==========================================
install_base() {
    echo -e "${CYAN}${BOLD}[*] Menginstall paket dasar...${RESET}"
    apt update -y
    apt install -y sudo nano nginx curl zip unzip git \
        php php-fpm php-cli php-zip php-curl php-xml php-mbstring \
        certbot python3-certbot-nginx

    systemctl enable nginx
    systemctl start nginx
}

choose_version() {
    echo ""
    echo -e "${YELLOW}${BOLD}Pilih versi Mikhmon yang ingin di-install:${RESET}"
    echo -e " ${GREEN}1)${RESET} Mikhmon-Agent"
    echo -e " ${GREEN}2)${RESET} Mikhmon PPPoE ROS 6"
    echo -e " ${GREEN}3)${RESET} Mikhmon PPPoE ROS 7"
    echo -e " ${GREEN}4)${RESET} Mikhmon GenieACS Integration"
    echo ""
    read -p "Masukkan pilihan (1-4): " choice

    case $choice in
        1) REPO=$REPO_AGENT; NAME="mikhmon-agent"; README=$README_AGENT ;;
        2) REPO=$REPO_PPP6; NAME="mikhmon-ppp6"; README=$README_PPP6 ;;
        3) REPO=$REPO_PPP7; NAME="mikhmon-ppp7"; README=$README_PPP7 ;;
        4) REPO=$REPO_GENIEACS; NAME="mikhmon-genieacs"; README=$README_GENIEACS ;;
        *) echo -e "${RED}Pilihan salah!${RESET}"; exit 1 ;;
    esac
}

setup_https() {
    DOMAIN=$1
    echo -e "${CYAN}${BOLD}[*] Mengatur HTTPS untuk domain $DOMAIN ...${RESET}"
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN" || {
        echo -e "${RED}Certbot gagal! Lanjutkan manual setelah install.${RESET}"
    }
}

setup_nginx() {
    DOMAIN=$1
    FOLDER=$2

    echo -e "${CYAN}${BOLD}[*] Membuat konfigurasi Nginx untuk $DOMAIN ...${RESET}"

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
    echo -e "${GREEN}${BOLD}┌──────────────────────────────────────────────┐${RESET}"
    echo -e "${GREEN}${BOLD}│ ✔ INSTALLASI MIKHMON SELESAI                │${RESET}"
    echo -e "${GREEN}${BOLD}└──────────────────────────────────────────────┘${RESET}"
    echo -e "${CYAN}URL Akses :${RESET} https://$DOMAIN"
    echo -e "${CYAN}Folder    :${RESET} /var/www/$FOLDER"
    echo ""
    echo -e "${YELLOW}Panduan Penggunaan:${RESET}"
    echo -e "${BLUE}$README${RESET}"

    echo ""
    echo -e "${MAGENTA}${BOLD}┌──────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}${BOLD}│     🎉 INSTALLER SELESAI — BY HENDRI         │${RESET}"
    echo -e "${MAGENTA}${BOLD}└──────────────────────────────────────────────┘${RESET}"
    echo -e "${BLUE}GitHub  :${RESET} https://github.com/heruhendri"
    echo -e "${BLUE}Telegram:${RESET} https://t.me/GbtTapiPngnSndiri"
    echo -e "${BLUE}Email   :${RESET} heruu2004@gmail.com"
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
