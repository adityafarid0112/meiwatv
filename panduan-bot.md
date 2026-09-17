# 🤖 Panduan Penggunaan Bot Auto-Poster (Xoilac ➡️ Blogger)

Bot ini otomatis mengambil jadwal pertandingan dari **`https://xoilacz.vip/`** dan menerbitkannya ke blog Anda (**`meiwaolaharaga.blogspot.com`**).

---

## 🚀 LANGKAH 1: Login & Izinkan Bot (Hanya Perlu Dilakukan Sekali / Jika Izin Kedaluwarsa)

1. Buka folder proyek Anda di file explorer: `d:\@Project\Blog`.
2. Klik ganda (*double-click*) file:
   📁 **`LOGIN_GOOGLE.bat`**
3. Browser Anda akan otomatis terbuka menampilkan halaman login Google.
4. Pilih akun Google pemilik / admin blog Anda (**`meiwaolaharaga.blogspot.com`**).
5. Jika muncul peringatan *"Google belum memverifikasi aplikasi ini"* -> Klik **Advanced (Lanjutan)** -> Klik **Buka SportStream Bot (tidak aman)** -> Centang semua izin akses Blogger -> Klik **Lanjutkan / Izinkan**.
6. Tab browser akan menampilkan: **"✅ Otentikasi Berhasil!"**.

---

## ⚽ LANGKAH 2: Menjalankan Bot Update Otomatis

Tersedia 2 pilihan cara menjalankan bot:

### Pilihan A: Mode Loop Otomatis Terus Menerus (Sangat Direkomendasikan) 🌟
1. Klik ganda file:
   📁 **`JALANKAN_BOT_OTOMATIS.bat`**
2. Bot akan otomatis:
   - Menghubungi `https://xoilacz.vip/`
   - Mengekstrak semua pertandingan live & jadwal hari ini
   - Menarik link embed streaming (Server 1 & Server 2 HD)
   - Menerbitkan pertandingan baru ke Blogger Anda
   - **Melakukan update otomatis secara berkala setiap 15 menit** tanpa perlu Anda jalankan ulang manual!

### Pilihan B: Mode Sekali Jalan (Manual Run)
1. Klik ganda file:
   📁 **`JALANKAN_BOT.bat`**
2. Bot akan menjalankan 1 siklus sinkronisasi lalu selesai.

---

## 📺 LANGKAH 3: Cek Blog Anda
Buka **`https://meiwaolaharaga.blogspot.com/`** -> Semua pertandingan baru dari `xoilacz.vip` langsung tampil di portal dan siap diputar di player!
