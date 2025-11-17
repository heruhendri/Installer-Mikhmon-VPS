Selamat mencoba 💪
Berikut **skrip otomatis (auto installer)** untuk **Mikhmon Multi User + HTTPS (Certbot)** — tinggal **copy-paste sekali jalan** di VPS kamu (NAT VPS / Ubuntu 20.04–22.04).
Skrip ini akan:

* Install semua dependensi (Nginx, PHP, Git, Certbot)
* Clone **Mikhmon PPPoE User (versi hendri)**
* Setup Nginx otomatis
* Pasang HTTPS pakai **Let’s Encrypt (Certbot)**
* Support **Cloudflare DNS** juga

---
## 📌 OPSI INSTALL OTOMATIS ⬇️

```
bash <(curl -s https://raw.githubusercontent.com/heruhendri/Installer-Mikhmon-VPS/master/install-mikhmon.sh)
```
## 📰 Atau Instalasi Manual Menggunakan Cara Seperti Dibawah↙️

### 🧾 **Langkah-langkah**

⚠️⚠️Pastikan anda sudah menambahkan port forwarding dan mendaftarkan domain anda di cloudflare⚠️⚠️

#### 1️⃣ Login ke VPS via SSH:

```
ssh root@ip-vps-kamu -p [port NAT]
```

#### 2️⃣ Jalankan skrip di bawah ini (Sudah didalam File Install.sh):

```bash
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
mkdir -p /var/www/mikhmon
cd /var/www/

# Clone Mikhmon Multi User
git clone https://github.com/heruhendri/Mikhmon-PPPoE-Ros.6.git

# Set permission
chown -R www-data:www-data /var/www/mikhmon
chmod -R 755 /var/www/mikhmon

# Buat konfigurasi Nginx
cat > /etc/nginx/sites-available/mikhmon.conf <<EOF
server {
    listen 80;
    server_name $domain;

    root /var/www/mikhmon;
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

ln -s /etc/nginx/sites-available/mikhmon.conf /etc/nginx/sites-enabled/

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
echo "Lokasi file: /var/www/mikhmon/"
echo "============================================"
```

---

#### 3️⃣ Simpan skrip (opsional, biar bisa digunakan lagi)

Kamu bisa simpan jadi file misalnya:

```bash
nano install-mikhmon.sh
```

Lalu paste isi di atas → Simpan (`CTRL+X`, `Y`, `ENTER`), kemudian jalankan:

```bash
bash install-mikhmon.sh
```

---

### 💡 Catatan Tambahan
* Pastikan anda **sudah menambahkan port forwarding terlebih dahulu Https 443 dan Https 80**
* Pastikan **subdomain sudah diarahkan ke IP VPS kamu** (kalau pakai NAT VPS, gunakan IP + port NAT di Cloudflare).
* Jika kamu pakai **Cloudflare**, set **SSL Mode = Full (strict)**.
* Jika port 80/443 tidak langsung terbuka (karena NAT), SSL mungkin perlu dijalankan lewat **Cloudflare Flexible**.

---