#!/bin/bash
# ============================================
# Mikhmon Multi Auto Installer + SSL (Certbot)
# By Hendri 😎
# ============================================

echo "============================================"
echo "     INSTALLER MIKHMON MULTI + HTTPS BY HENDRI"
echo "============================================"
echo ""

read -p "Masukkan domain/subdomain (contoh: mikhmon.hendri.site): " domain

# Update & install dependensi
apt update && apt upgrade -y
apt install nginx php php-fpm php-cli php-curl php-zip php-xml php-mbstring unzip curl git certbot python3-certbot-nginx -y

# Hentikan default nginx site
rm -f /etc/nginx/sites-enabled/default

# Buat folder web
mkdir -p /var/www/html/Mikhmon-PPPoE-Ros.6
cd /var/www/html/

# Clone Mikhmon Multi User
git clone https://github.com/heruhendri/Mikhmon-PPPoE-Ros.6.git

# Set permission
chown -R www-data:www-data /var/www/html/Mikhmon-PPPoE-Ros.6
chmod -R 755 /var/www/Mikhmon-PPPoE-Ros.6

# Buat konfigurasi Nginx
cat > /etc/nginx/sites-available/Mikhmon-PPPoE-Ros.6.conf <<EOF
server {
    listen 80;
    server_name $domain;

    root /var/www/html/Mikhmon-PPPoE-Ros.6;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/Mikhmon-PPPoE-Ros.6.conf /etc/nginx/sites-enabled/

# Test & reload Nginx
nginx -t && systemctl reload nginx

# Pasang SSL
echo ""
echo "🔒 Memasang SSL Let's Encrypt untuk $domain..."
certbot --nginx -d $domain --non-interactive --agree-tos -m admin@$domain --redirect

# Restart service
systemctl restart nginx
systemctl restart php*-fpm

# Info selesai
echo ""
echo "============================================"
echo "✅ INSTALASI SELESAI!"
echo "URL: https://$domain"
echo "Lokasi file: /var/www/html/Mikhmon-PPPoE-Ros.6/"
echo "============================================"