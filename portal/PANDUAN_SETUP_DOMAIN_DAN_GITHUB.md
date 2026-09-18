# 🚀 Panduan Lengkap Setup Web Portal, Custom Domain, & Hosting GitHub Pages

Web portal ini dirancang khusus untuk memposting dan mendistribusikan aplikasi APK Anda (**MeiwaSports** & **MeiwaStudio**) dengan tampilan modern dark mode yang super cepat dan responsif.

---

## 📁 Struktur File di Folder `portal/`

* `index.html` : Halaman utama website portal.
* `style.css` : Desain tampilan (modern glassmorphism, neon glow, dark mode).
* `config.js` : **File konfigurasi utama** (tempat ganti versi APK, link download, changelog, dan FAQ).
* `app.js` : Logika interaktif (modal download, multi-server mirror, tab preview, FAQ).
* `assets/` : Folder berisi logo, screenshot aplikasi, dan ikon.
* `CNAME` : File penunjuk custom domain Anda.
* `PREVIEW_WEB.bat` : Klik 2x file ini untuk melihat tampilan web di laptop Anda.

---

## 🛠️ Langkah 1: Tes Tampilan Web di Komputer Anda
1. Buka folder `portal/`.
2. Klik 2x file **`PREVIEW_WEB.bat`** (atau klik kanan `index.html` -> *Open with Chrome/Edge/Firefox*).
3. Anda akan langsung melihat tampilan web portal Meiwa Apps.

---

## 🌐 Langkah 2: Cara Hosting di GitHub Pages (100% Gratis)

Ada 2 cara paling mudah untuk meng-online-kan web ini:

### Opsi A: Buat Repository Khusus (Sangat Disarankan)
1. Buka [GitHub](https://github.com/) dan buat repository baru bernama `meiwatv-portal` (atau `meiwatv.github.io`).
2. Atur sebagai **Public**.
3. Upload seluruh isi folder `portal` (file `index.html`, `style.css`, `config.js`, `app.js`, `CNAME`, dan folder `assets`) ke dalam repository tersebut.
4. Buka menu **Settings** di repo tersebut -> klik menu **Pages** di sebelah kiri.
5. Pada bagian **Build and deployment > Source**, pilih **Deploy from a branch** -> Branch: **`main`** / Folder: **`/(root)`** -> Klik **Save**.
6. Tunggu 1–2 menit, web Anda sudah live di URL: `https://<username>.github.io/meiwatv-portal/`.

---

## 🔗 Langkah 3: Menghubungkan Custom Domain (misal `meiwatv.my.id`)

Setelah Anda membeli domain (di Niagahoster, Domainesia, Idwebhost, Rumahweb, dll):

### 1. Setting DNS di Member Area Pembelian Domain
Buka menu **DNS Management / Kelola DNS** pada domain yang Anda beli, lalu tambahkan record berikut:

#### Tambahkan 4 baris A Record (IP Resmi GitHub Pages):
| Type | Name / Host | Target / Value / IP | TTL |
| :--- | :--- | :--- | :--- |
| **A** | `@` | `185.199.108.153` | Auto / 14400 |
| **A** | `@` | `185.199.109.153` | Auto / 14400 |
| **A** | `@` | `185.199.110.153` | Auto / 14400 |
| **A** | `@` | `185.199.111.153` | Auto / 14400 |

#### Tambahkan 1 baris CNAME Record untuk `www`:
| Type | Name / Host | Target / Value | TTL |
| :--- | :--- | :--- | :--- |
| **CNAME** | `www` | `adityafarid0112.github.io` | Auto / 14400 |

*(Ganti `adityafarid0112` dengan username GitHub Anda jika berbeda).*

### 2. Pasang Domain di GitHub Pages
1. Di repository GitHub Anda, masuk ke **Settings** -> **Pages**.
2. Di kolom **Custom domain**, ketik domain Anda (misal `meiwatv.my.id`) lalu klik **Save**.
3. Centang opsi **Enforce HTTPS** (agar website memiliki gembok hijau / SSL aman).
4. Selesai! Domain Anda kini langsung membuka website portal Meiwa Apps.

---

## 📦 Langkah 4: Cara Upload File APK ke GitHub Releases (Penyimpanan Download)

Agar link download APK berkecepatan tinggi dan direct download:

1. Buka repository GitHub Anda -> klik tab **Releases** (di sebelah kanan halaman repo).
2. Klik tombol **Draft a new release** (atau *Create a new release*).
3. Isi kolom:
   * **Choose a tag**: ketik `v1.0.0` (lalu klik *Create new tag*).
   * **Release title**: `Meiwa Apps v1.0.0 Release`.
4. Drag & drop file **`MeiwaSports.apk`** dan **`MeiwaStudio.apk`** ke kotak *Attach binaries by dropping them here*.
5. Klik tombol **Publish release**.
6. Setelah ter-publish, klik kanan pada tombol download file APK tersebut -> pilih **Copy link address**.

---

## ⚙️ Langkah 5: Cara Update Link & Versi Aplikasi

Kapan pun Anda merilis versi baru atau ingin mengubah link download:

1. Buka file **`portal/config.js`**.
2. Ubah bagian `downloadUrlPrimary`, `version`, atau `changelog`:
   ```javascript
   sports: {
     version: "v1.0.1",
     fileSize: "29.1 MB",
     downloadUrlPrimary: "PASTE_LINK_GITHUB_RELEASE_ANDA_DI_SINI",
     downloadUrlMirror1: "LINK_GOOGLE_DRIVE_JIKA_ADA",
     // ...
   }
   ```
3. Simpan dan push/upload kembali file `config.js` ke GitHub. Website akan otomatis terupdate seketika tanpa perlu koding ulang!

---
*Dibuat untuk ekosistem Meiwa Network.*
