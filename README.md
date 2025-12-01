

# ✅ **Script Installer Otomatis Mikhmon Multi + Domain + HTTPS**

## **🟢 Fitur:**

* Install beberapa Mikhmon dalam 1 VPS
* Input domain manual per instance
* Auto-create folder per instance
* Auto-create database per instance
* Auto-setup Nginx vhost
* Auto-install SSL Certbot
* Auto-config PHP full
* Auto-import database default jika script tersedia
* Support NATVPS, Ubuntu 20.04–24.04


new
```bash
wget https://raw.githubusercontent.com/heruhendri/Installer-Mikhmon-VPS/refs/heads/install-multi/installer-mikhmon.sh
```








## **Mikhmon Multi Installer + HTTPS Auto (Cloudflare / Certbot)**

Installer ini digunakan untuk menginstall **beberapa instance Mikhmon** dalam 1 VPS sekaligus, dengan fitur:

### 🔥 **Fitur Utama**

* Install **banyak Mikhmon** dalam 1 server
* **Input manual domain/subdomain** setiap instance
* Auto setup:

  * Nginx
  * PHP-FPM
  * MariaDB
  * Certbot (HTTPS otomatis)
  * Permission folder
* Auto clone repo Mikhmon:
  👉 [https://github.com/heruhendri/Mikhmon-PPPoE-Ros.6](https://github.com/heruhendri/Mikhmon-PPPoE-Ros.6)

---

## 📦 **Cara Install**

### Langkah Sebelum Install
---

```bash
apt install -y curl bash nano
```

### 1. Download script

```bash
wget https://raw.githubusercontent.com/heruhendri/Installer-Mikhmon-VPS/install-multi/install-mikhmon.sh
```

*(ganti NAMAREPO setelah sudah upload ke GitHub)*

### 2. Beri izin eksekusi

```bash
chmod +x install-mikhmon.sh
```

### 3. Jalankan installer

```bash
./install-mikhmon.sh
```

---

## 🧩 **Proses Installer**

Script akan meminta:

1. **Berapa banyak instance**
2. Nama folder instance
   Contoh:

   ```
   mikhmon1
   mikhmon2
   ```
3. Domain per instance
   Contoh:

   ```
   m1.domain.com
   m2.domain.com
   ```

---

## 🚀 **Setelah Install**

Setiap instance akan memiliki:

* URL HTTPS otomatis
* Folder di `/var/www/mikhmon/`
* Database unik per instance

---

## 🛠️ **Kebutuhan Server**

* Ubuntu 20.04 / 22.04 / 24.04
* NATVPS / VPS umum
* DNS domain sudah diarahkan ke IP VPS

---