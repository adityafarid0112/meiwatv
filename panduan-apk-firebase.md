# Panduan Lengkap Aplikasi MeiwaTV (Native Flutter + Firebase)
### Kompatibel dengan: Android Mobile (HP), Tablet, & Android TV / Smart TV

---

## 📱 1. Fitur Utama Aplikasi

1. **Multi-Perangkat Murni**:
   * **Android TV / Smart TV / STB**: Mendukung penuh navigasi **Remote Control (D-Pad)** tombol Atas, Bawah, Kiri, Kanan, dan OK. Kartu pertandingan otomatis membesar (*zoom 1.04x*) dan bercahaya hijau emerald saat disorot remote. Tampil di menu utama Android TV (Leanback Launcher).
   * **HP & Tablet**: Tampilan sentuh (*touch-friendly*) dengan layout responsif (1 kolom di HP, 2–3 kolom di Tablet & TV).
2. **Multi-Server Streaming Switcher**:
   * **Jalur 1**: HLS `.m3u8` High Definition (HD 1080p/720p).
   * **Jalur 2**: FLV / HLS Low Latency (Cepat & Anti-Buffering).
   * **Jalur 3**: Backup CDN / Direct Web Link.
   * Tombol ganti server tersedia langsung di layar pemutar dan bisa dipindah menggunakan remote TV (Panah Kiri/Kanan atau tombol Jalur).
3. **Backend Mandiri Firebase Firestore**:
   * Real-time sync langsung ke Firebase.
   * **100% Kebal dari risiko Blogger dihapus**.

---

## 🚀 2. Cara Menjalankan & Menghubungkan ke Firebase

### A. Mode Cepat / Pengujian Langsung:
Aplikasi sudah dilengkapi dengan **Mock & Local Fallback otomatis**. Anda bisa langsung menjalankan atau mengompilasi APK tanpa perlu setup awal yang rumit.

### B. Menghubungkan Firebase Asli (Untuk Produksi):
1. Buat Project baru di [Firebase Console](https://console.firebase.google.com/).
2. Aktifkan **Cloud Firestore Database** (pilih mode *Start in test mode* atau atur rules read/write).
3. Tambahkan aplikasi Android dengan Package Name: `com.meiwatv.meiwatv_app`.
4. Download file `google-services.json` dan letakkan di:
   ```
   meiwatv_app/android/app/google-services.json
   ```
5. Untuk upload otomatis dari scraper bot ke Firebase:
   * Buka **Firebase Console** -> **Project Settings** -> **Service Accounts**.
   * Klik **Generate new private key** dan simpan filenya sebagai:
     ```
     firebase-service-account.json
     ```
   * Jalankan file `SYNC_KE_FIREBASE.bat` atau ketik `node sync-to-firebase.js`.

---

## 🛠️ 3. Cara Mengompilasi Menjadi APK (Siap Install di HP & TV Box)

1. Cukup klik ganda (double click) file:
   ```
   BUILD_APK.bat
   ```
   atau jalankan melalui terminal:
   ```bash
   cd meiwatv_app
   flutter build apk --release
   ```
2. File APK yang dihasilkan akan berada di:
   ```
   meiwatv_app/build/app/outputs/flutter-apk/app-release.apk
   ```
3. Kirim file APK tersebut ke HP, Tablet, atau transfer ke Android TV Box (menggunakan flashdisk / aplikasi *Send Files to TV*), lalu Install.

---

## 📂 4. Struktur Proyek Flutter

```
meiwatv_app/
├── android/app/src/main/AndroidManifest.xml  # Konfigurasi Android TV Leanback & Cleartext Network
├── lib/
│   ├── main.dart                             # Entry point aplikasi
│   ├── theme/app_theme.dart                  # Desain tema Dark Stadium & Neon Emerald
│   ├── models/match_model.dart               # Model data pertandingan & link Jalur 1, 2, 3
│   ├── services/match_service.dart           # Real-time Firestore stream & fallback service
│   ├── widgets/
│   │   ├── tv_focusable_card.dart            # Kartu fokus remote D-Pad TV Box
│   │   ├── category_chip.dart                # Filter liga & live status
│   │   └── live_badge.dart                   # Indikator animasi LIVE berkedip
│   └── screens/
│       ├── home_screen.dart                  # Halaman utama responsif Mobile / Tablet / TV
│       └── player_screen.dart                # Pemutar video layar penuh & switcher Jalur
└── pubspec.yaml                              # Dependency video_player, cloud_firestore, dll.
```
