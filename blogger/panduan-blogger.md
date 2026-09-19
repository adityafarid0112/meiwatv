# 📖 Panduan Manajemen Template & Bot Blogger MeiwaSports

Folder ini berisi semua file, template, dan skrip otomasi khusus untuk Blog **[MeiwaSports (meiwaolaharaga.blogspot.com)](https://meiwaolaharaga.blogspot.com/)**.

---

## 📁 Struktur File di Folder `blogger/`

| File | Deskripsi |
|---|---|
| **`template-sportstream.xml`** | **Template Utama Blogger**. Desain modern Xoilac/Socolive dengan Player Theater Mode (16:9), Single-Select Filter Multi-Olahraga, Iklan Adsterra & Donasi Saweria. |
| **`template-sportstream-update.xml`** | Cadangan / Arsip pembaruan template. |
| **`auto-poster.js`** | Bot otomatis untuk mempublikasikan postingan jadwal pertandingan ke Blogger via Blogger REST API v3. |
| **`auth.js`** | Skrip otentikasi Google OAuth2 untuk mendapatkan izin akses Blogger API. |
| **`client_secrets.json`** | Kredensial OAuth Client ID & Secret Google Cloud Console. |
| **`token.json`** | Token otentikasi OAuth aktif untuk Blogger API. |
| **`sample-post-format.html`** | Contoh format HTML postingan pertandingan. |
| **`test-create-post.js`** | Skrip pengujian pembuatan postingan ke Blogger. |
| **`test-get-blogs.js`** | Skrip pengujian koneksi dan pengecekan daftar blog di akun Google Anda. |

---

## 🚀 Cara Menerapkan Template ke Blogger

1. Buka dashboard **[Blogger](https://www.blogger.com/)** dan pilih blog **MeiwaSports**.
2. Masuk ke menu **Tema (Theme)**.
3. Klik tanda panah bawah di sebelah tombol *Sesuaikan (Customize)* ➔ pilih **Edit HTML**.
4. Buka file **`blogger/template-sportstream.xml`**, salin semua isinya (`Ctrl+A`, `Ctrl+C`).
5. Tempelkan (`Ctrl+V`) ke editor HTML Blogger dan klik **Simpan (Save)**.

---

## ⚡ Sinkronisasi Otomatis Real-Time

* Template di blog sudah dilengkapi fungsi `fetchLiveMatchesDirect()`.
* Setiap 2 menit, browser pengunjung akan otomatis mengambil jadwal & status pertandingan terbaru langsung dari repository GitHub (`matches.json`).
* **Artinya:** Anda tidak perlu mengedit HTML tema setiap ada jadwal baru. Cukup jalankan bot scraper di komputer atau biarkan bot berjalan, maka tampilan blog akan otomatis sinkron!

---

## 🤖 Menjalankan Bot Auto-Poster

Untuk menerbitkan postingan jadwal pertandingan secara otomatis ke feed Blogger:

```bash
cd d:\@Project\Blog\blogger
node auto-poster.js
```
