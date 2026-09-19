/**
 * MEIWA APPS PORTAL - Configuration File
 * Last Updated: 19 September 2026
 * Anda bisa mengubah link download, versi, ukuran file, dan changelog di sini
 * tanpa perlu mengubah file HTML!
 */

const MEIWA_CONFIG = {
  brand: {
    name: "Meiwa Network",
    tagline: "Pusat Hiburan & Live Sports Streaming Terlengkap",
    telegramUrl: "https://t.me/meiwatv", // Ganti dengan link grup/channel Telegram Anda
    whatsappUrl: "https://wa.me/",       // Opsional: link WA jika ada
    websiteUrl: "https://meiwa.my.id",
  },

  apps: {
    sports: {
      id: "sports",
      name: "MeiwaSports",
      tagline: "Live Sports & Real-time Scores",
      badge: "Gratis & Tanpa Iklan Mengganggu",
      version: "v1.0.0",
      versionCode: 1,
      releaseDate: "September 2026",
      fileSize: "28.5 MB",
      minAndroid: "Android 5.0+ (Lollipop ke atas)",
      supportsTV: true,
      
      // Link Download APK (Google Drive)
      downloadUrlUniversal: "https://drive.google.com/uc?export=download&id=1CDQW3bNBs-3H6M6ADBXWtKllW70wJJ9V",
      downloadUrlSTB: "https://drive.google.com/uc?export=download&id=1s0hHDHYfVo8bqAoSK0rHVRcrUFUpd6QY",
      downloadUrlHP: "https://drive.google.com/uc?export=download&id=1sWP2kF5n2mlUH2bNf4JsQ3jYTxerni7x",
      
      // Mirror / Preview Links
      driveViewUniversal: "https://drive.google.com/file/d/1CDQW3bNBs-3H6M6ADBXWtKllW70wJJ9V/view?usp=sharing",
      driveViewSTB: "https://drive.google.com/file/d/1s0hHDHYfVo8bqAoSK0rHVRcrUFUpd6QY/view?usp=sharing",
      driveViewHP: "https://drive.google.com/file/d/1sWP2kF5n2mlUH2bNf4JsQ3jYTxerni7x/view?usp=sharing",

      rating: "4.9",
      totalDownloads: "15K+",
      
      features: [
        "⚽ Live Streaming Liga Top Dunia (Premier League, UCL, La Liga, Serie A, BRI Liga 1, dll)",
        "🏎️ Tayangan Live MotoGP, Formula 1, Badminton, NBA, & UFC",
        "⚡ Multi-Server Ultra Low-Latency (Pilihan server lancar & anti-buffering)",
        "📊 Live Score, Klasemen, & Statistik Pertandingan Real-time",
        "📺 Kompatibel dengan Android Smartphone, Tablet, & Android Smart TV",
        "🔔 Notifikasi Kick-off pertandingan favorit"
      ],

      changelog: [
        "Rilis versi perdana MeiwaSports 1.0.0",
        "Dukungan player ExoPlayer dengan adaptasi resolusi otomatis (360p - 1080p 60fps)",
        "Fitur remote D-Pad navigation untuk Android TV Box",
        "Tersedia versi Ringan khusus STB / TV Box hemat memori"
      ]
    },

    studio: {
      id: "studio",
      name: "MeiwaStudio",
      tagline: "Nonton Film, Series & Anime Sub Indo",
      badge: "Koleksi Box Office Terlengkap",
      version: "v1.0.0",
      versionCode: 1,
      releaseDate: "September 2026",
      fileSize: "15.6 MB (STB) / 18.1 MB (HP)",
      minAndroid: "Android 5.0+ (Lollipop ke atas)",
      supportsTV: true,

      // Link Download APK (Google Drive)
      downloadUrlUniversal: "https://drive.google.com/uc?export=download&id=1iJSlxHl2gb3omFR_rVGdsPr9JnP-CVC2",
      downloadUrlSTB: "https://drive.google.com/uc?export=download&id=1No7NFfkLCvZb4RUdqO1yhKZzB5mFPPxj",
      downloadUrlHP: "https://drive.google.com/uc?export=download&id=1elPWgczMwY7oJ4T1MM7nyO8SqFH0zrd7",
      
      // Mirror / Preview Links
      driveViewUniversal: "https://drive.google.com/file/d/1iJSlxHl2gb3omFR_rVGdsPr9JnP-CVC2/view?usp=sharing",
      driveViewSTB: "https://drive.google.com/file/d/1No7NFfkLCvZb4RUdqO1yhKZzB5mFPPxj/view?usp=sharing",
      driveViewHP: "https://drive.google.com/file/d/1elPWgczMwY7oJ4T1MM7nyO8SqFH0zrd7/view?usp=sharing",

      rating: "4.8",
      totalDownloads: "12K+",

      features: [
        "🍿 Ribuan Koleksi Film Box Office, Drama Korea, Serial Barat, & Anime",
        "🇮🇩 Subtitle Bahasa Indonesia Lengkap & Sinkron",
        "⚡ Pilihan Resolusi Video (360p, 480p, 720p, 1080p FHD)",
        "📥 Fitur Download Offline (Nonton tanpa kuota)",
        "🔍 Fitur Pencarian Cerdas & Filter Genre",
        "📺 Support Android TV & Remote Control Navigation"
      ],

      changelog: [
        "Rilis versi perdana MeiwaStudio 1.0.0",
        "Katalog film dan serial update otomatis setiap hari",
        "Player modern dengan gesture swipe brightness & volume",
        "Bookmark & riwayat tontonan (Continue Watching)"
      ]
    }
  },

  faq: [
    {
      q: "Apakah semua aplikasi Meiwa ini 100% Gratis?",
      a: "Ya! Baik MeiwaSports maupun MeiwaStudio dapat diunduh dan dinikmati secara gratis tanpa biaya langganan bulanan."
    },
    {
      q: "Kenapa muncul peringatan 'File Berbahaya' atau 'Play Protect' saat install?",
      a: "Hal ini wajar pada semua aplikasi Android yang diunduh langsung (format .APK) di luar Google Play Store. File APK kami 100% aman, bersih dari malware, dan diverifikasi secara berkala. Anda cukup klik 'Tetap Install' (Install Anyway)."
    },
    {
      q: "Apakah aplikasi bisa dipasang di Smart TV / Android TV Box?",
      a: "Bisa! Aplikasi kami dirancang khusus agar support navigasi tombol D-Pad remote Android TV. Anda bisa transfer file APK lewat Flashdisk / aplikasi 'Send Files to TV' lalu install langsung di TV Anda."
    },
    {
      q: "Bagaimana cara melakukan update jika ada versi baru?",
      a: "Cukup kunjungi kembali web portal ini, download APK versi terbaru, lalu install langsung (tidak perlu menghapus aplikasi lama agar data/favorit Anda tidak hilang)."
    }
  ]
};
