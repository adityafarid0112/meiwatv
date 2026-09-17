# 🏆 Panduan Lengkap: SportStream Pro + Auto-Poster Bot + Monetisasi Adsterra

Selamat! Website portal live streaming Anda sekarang sudah dilengkapi dengan:
1. 🤖 **Bot Auto-Poster Cerdas**: Otomatis menarik jadwal & link streaming pertandingan dari `https://xoilaczbj.tv/` dan mempostingkannya ke Blogger Anda.
2. ⚡ **Hero Match Stage (Pilihan A)**: Tampilan panggung pertandingan modern dengan countdown real-time, badge liga, dan tombol pemutar resolusi HD (Server 1 & Server 2) langsung mengarahkan pengunjung ke siaran lancar tanpa error blokir iframe.
3. 💰 **Monetisasi Adsterra Penuh**:
   - **Direct Link / Smartlink**: Menghasilkan uang/traffic setiap kali pengunjung mengklik tombol siaran (`SERVER 1 HD`, `SERVER 2`, atau tombol popunder).
   - **Slot Banner 728x90**: Tepat di bawah Hero Player Stage untuk CTR tinggi.
   - **Slot Banner 300x250**: Di dalam sidebar daftar jadwal.

---

## 🚀 LANGKAH 1: Cara Memasukkan Link Iklan Adsterra

### A. Memasukkan Direct Link (Smartlink) Adsterra
1. Buka file [template-sportstream.xml](file:///d:/@Project/Blog/template-sportstream.xml).
2. Cari baris berikut (di bagian bawah file, sekitar baris 770):
   ```javascript
   const ADSTERRA_DIRECT_LINK = ""; // <-- TEMPEL LINK ADSTERRA ANDA DI SINI
   ```
3. Masukkan Direct Link Adsterra Anda di dalam tanda petik, contoh:
   ```javascript
   const ADSTERRA_DIRECT_LINK = "https://www.profitablecpmrate.com/abcdef123456";
   ```

### B. Memasukkan Kode Banner Adsterra 728x90 (Di Bawah Player)
1. Di file [template-sportstream.xml](file:///d:/@Project/Blog/template-sportstream.xml), cari:
   ```html
   <!-- TEMPEL KODE SCRIPT BANNER ADSTERRA 728x90 DI BAWAH INI -->
   <div id='adsterra-slot-728x90' ...>
   ```
2. Ganti teks placeholder di dalam tag `div` tersebut dengan script HTML/JS banner 728x90 yang Anda dapatkan dari dashboard Adsterra.

### C. Memasukkan Kode Banner Adsterra 300x250 (Di Sidebar)
1. Di file [template-sportstream.xml](file:///d:/@Project/Blog/template-sportstream.xml), cari:
   ```html
   <!-- TEMPEL KODE SCRIPT BANNER ADSTERRA 300x250 DI BAWAH INI -->
   <div id='adsterra-slot-300x250' ...>
   ```
2. Ganti teks placeholder di dalam tag `div` tersebut dengan script HTML/JS banner 300x250 Adsterra Anda.

---

## 🎨 LANGKAH 2: Pasang Template ke Blogger

1. Buka file [template-sportstream.xml](file:///d:/@Project/Blog/template-sportstream.xml).
2. Tekan `Ctrl + A` (pilih semua) lalu `Ctrl + C` (salin).
3. Buka dashboard [Blogger.com](https://www.blogger.com) -> Masuk ke menu **Tema (Theme)**.
4. Klik tombol panah ke bawah **(▼)** di sebelah tombol Sesuaikan -> Pilih **Edit HTML**.
5. Hapus semua kode yang ada di editor Blogger, lalu **Paste (Ctrl + V)** kode dari `template-sportstream.xml`.
6. Klik ikon **Simpan (Save)** di pojok kanan atas.

---

## 🤖 LANGKAH 3: Jalankan Bot Auto-Poster untuk Mengambil Pertandingan Terbaru

Kapan pun Anda ingin memperbarui atau menambah jadwal pertandingan dari Xoilac ke Blog Anda:
1. Buka folder `d:\@Project\Blog`.
2. Klik ganda (Double-click) file:
   👉 **`JALANKAN_BOT.bat`**
3. Bot akan otomatis:
   - Menghubungi `xoilaczbj.tv`
   - Mengekstrak semua pertandingan hari ini beserta jam kickoff & link server HD
   - Menyeleksi dan memposting ke Blogger Anda secara otomatis tanpa duplikasi!

---

## 🔍 Cara Melihat Hasil di Komputer Anda (Preview)
Anda bisa langsung membuka file [preview.html](file:///d:/@Project/Blog/preview.html) di browser Google Chrome / Edge untuk melihat simulasi tampilan web portal live streaming dan monetisasinya.
