class LeagueTranslator {
  /// Bersihkan karakter diakritik khusus bahasa Vietnam agar menjadi nama klub / tim yang bersih & mudah dibaca
  static String cleanTeamName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    String text = raw.trim();

    const diacriticsMap = {
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'À': 'A', 'Á': 'A', 'Ạ': 'A', 'Ả': 'A', 'Ã': 'A',
      'Â': 'A', 'Ầ': 'A', 'Ấ': 'A', 'Ậ': 'A', 'Ẩ': 'A', 'Ẫ': 'A',
      'Ă': 'A', 'Ằ': 'A', 'Ắ': 'A', 'Ặ': 'A', 'Ẳ': 'A', 'Ẵ': 'A',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'È': 'E', 'É': 'E', 'Ẹ': 'E', 'Ẻ': 'E', 'Ẽ': 'E',
      'Ê': 'E', 'Ề': 'E', 'Ế': 'E', 'Ệ': 'E', 'Ể': 'E', 'Ễ': 'E',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'Ì': 'I', 'Í': 'I', 'Ị': 'I', 'Ỉ': 'I', 'Ĩ': 'I',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'Ò': 'O', 'Ó': 'O', 'Ọ': 'O', 'Ỏ': 'O', 'Õ': 'O',
      'Ô': 'O', 'Ồ': 'O', 'Ố': 'O', 'Ộ': 'O', 'Ổ': 'O', 'Ỗ': 'O',
      'Ơ': 'O', 'Ờ': 'O', 'Ớ': 'O', 'Ợ': 'O', 'Ở': 'O', 'Ỡ': 'O',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'Ù': 'U', 'Ú': 'U', 'Ụ': 'U', 'Ủ': 'U', 'Ũ': 'U',
      'Ư': 'U', 'Ừ': 'U', 'Ứ': 'U', 'Ự': 'U', 'Ử': 'U', 'Ữ': 'U',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'Ỳ': 'Y', 'Ý': 'Y', 'Ỵ': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y',
      'đ': 'd', 'Đ': 'D'
    };

    diacriticsMap.forEach((k, v) {
      text = text.replaceAll(k, v);
    });

    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Terjemahkan nama liga / kompetisi ke Bahasa Indonesia yang akurat dan bersih tanpa duplikasi negara
  static String translate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Turnamen Olahraga';
    }

    String text = raw.trim();

    // 1. Kamus Liga Spesifik (Diperiksa pertama untuk mencegah salah ganti)
    final directList = <MapEntry<Pattern, String>>[
      // Bangladesh & negara lain yang memakai nama 'Premier League'
      MapEntry(RegExp(r'Bangladesh\s*Premier\s*League', caseSensitive: false), 'Liga Utama Bangladesh'),
      MapEntry(RegExp(r'Czech\s*3\s*liga', caseSensitive: false), 'Liga 3 Ceko'),
      MapEntry(RegExp(r'Ngoại Hạng Darwin', caseSensitive: false), 'Liga Darwin Australia'),

      // Liga Inggris
      MapEntry(RegExp(r'Ngoại Hạng Anh|^Premier League(\s*\(Inggris\))?$', caseSensitive: false), 'Liga Inggris'),
      MapEntry(RegExp(r'Hạng Nhất Anh|^Championship$', caseSensitive: false), 'Liga Championship Inggris'),
      MapEntry(RegExp(r'Cúp FA|^FA Cup$', caseSensitive: false), 'Piala FA Inggris'),
      MapEntry(RegExp(r'Cúp Liên Đoàn Anh|EFL Cup|Carabao Cup', caseSensitive: false), 'Piala Carabao Inggris'),

      // Indonesia
      MapEntry(RegExp(r'VĐQG Indonesia|Liga\s*1\s*Indonesia|BRI Liga 1', caseSensitive: false), 'BRI Liga 1 Indonesia'),
      MapEntry(RegExp(r'Hạng 2 Indonesia|Liga\s*2\s*Indonesia', caseSensitive: false), 'Liga 2 Indonesia'),
      MapEntry(RegExp(r'Hạng 3 Indonesia|Liga\s*3\s*Indonesia', caseSensitive: false), 'Liga 3 Indonesia'),

      // Vietnam
      MapEntry(RegExp(r'Cúp Quốc Gia Việt Nam|Cúp Quốc Gia', caseSensitive: false), 'Piala Nasional Vietnam'),
      MapEntry(RegExp(r'VĐQG Việt Nam|V\.League\s*1', caseSensitive: false), 'Liga Vietnam (V.League 1)'),
      MapEntry(RegExp(r'Hạng Nhất Việt Nam|V\.League\s*2', caseSensitive: false), 'Liga Vietnam 2 (V.League 2)'),

      // Spanyol
      MapEntry(RegExp(r'VĐQG Tây Ban Nha|^La\s*Liga(\s*\(Spanyol\))?$', caseSensitive: false), 'La Liga Spanyol'),
      MapEntry(RegExp(r'Hạng 2 Tây Ban Nha|La\s*Liga\s*2|Segunda\s*División', caseSensitive: false), 'La Liga 2 Spanyol'),
      MapEntry(RegExp(r'Cúp Nhà Vua|^Copa del Rey$', caseSensitive: false), 'Piala Raja Spanyol (Copa del Rey)'),
      MapEntry(RegExp(r'Copa del Rey de Baloncesto', caseSensitive: false), 'Piala Raja Basket Spanyol'),
      MapEntry(RegExp(r'Spain Basketball Supercopa', caseSensitive: false), 'Piala Super Basket Spanyol'),

      // Italia
      MapEntry(RegExp(r'VĐQG Ý|^Serie\s*A(\s*\(Italia\))?$', caseSensitive: false), 'Serie A Italia'),
      MapEntry(RegExp(r'Hạng 2 Ý|^Serie\s*B', caseSensitive: false), 'Serie B Italia'),
      MapEntry(RegExp(r'Cúp Quốc Gia Ý|Coppa Italia', caseSensitive: false), 'Piala Italia (Coppa Italia)'),
      MapEntry(RegExp(r'Italy Super Cup', caseSensitive: false), 'Piala Super Italia'),

      // Jerman
      MapEntry(RegExp(r'VĐQG Đức|^Bundesliga(\s*\(Jerman\))?$', caseSensitive: false), 'Bundesliga Jerman'),
      MapEntry(RegExp(r'Hạng 2 Đức|2\.\s*Bundesliga|Bundesliga\s*2', caseSensitive: false), '2. Bundesliga Jerman'),
      MapEntry(RegExp(r'Cúp Quốc Gia Đức|DFB[- ]Pokal', caseSensitive: false), 'Piala DFB Jerman'),
      MapEntry(RegExp(r'Basketball Bundesliga', caseSensitive: false), 'Bundesliga Basket Jerman'),

      // Prancis
      MapEntry(RegExp(r'VĐQG Pháp|^Ligue\s*1(\s*\(Prancis\))?$', caseSensitive: false), 'Ligue 1 Prancis'),
      MapEntry(RegExp(r'Hạng 2 Pháp|^Ligue\s*2', caseSensitive: false), 'Ligue 2 Prancis'),

      // Belanda & Portugal
      MapEntry(RegExp(r'VĐQG Hà Lan|^Eredivisie(\s*\(Belanda\))?$', caseSensitive: false), 'Eredivisie Belanda'),
      MapEntry(RegExp(r'VĐQG Bồ Đào Nha|^Liga\s*Portugal$|^Primeira\s*Liga$', caseSensitive: false), 'Liga Portugal'),

      // Arab Saudi
      MapEntry(RegExp(r'VĐQG Saudi Arabia|VĐQG Ả Rập Xê Út|Saudi\s*Pro\s*League', caseSensitive: false), 'Saudi Pro League (Arab Saudi)'),

      // Jepang
      MapEntry(RegExp(r'VĐQG Nhật Bản|^J1\s*League(\s*\(Jepang\))?$', caseSensitive: false), 'J1 League Jepang'),
      MapEntry(RegExp(r'Hạng 2 Nhật Bản|^J2\s*League(\s*\(Jepang\))?$', caseSensitive: false), 'J2 League Jepang'),
      MapEntry(RegExp(r'Hạng 3 Nhật Bản|^J3\s*League(\s*\(Jepang\))?$', caseSensitive: false), 'J3 League Jepang'),
      MapEntry(RegExp(r'Japan Football League|^JFL$', caseSensitive: false), 'Liga Sepak Bola Jepang (JFL)'),

      // Korea Selatan
      MapEntry(RegExp(r'VĐQG Hàn Quốc|^K\s*League\s*1(\s*\(Korea Selatan\))?$', caseSensitive: false), 'K League 1 Korea Selatan'),
      MapEntry(RegExp(r'Hạng 2 Hàn Quốc|^K\s*League\s*2', caseSensitive: false), 'K League 2 Korea Selatan'),

      // Lainnya
      MapEntry(RegExp(r'Hạng Nhất Ukraina', caseSensitive: false), 'Liga Utama Ukraina'),
      MapEntry(RegExp(r'Hạng 2 Trung Quốc|China\s*League\s*One', caseSensitive: false), 'Liga 2 China'),
      MapEntry(RegExp(r'Hạng 2 Romania', caseSensitive: false), 'Liga 2 Rumania'),
      MapEntry(RegExp(r'National Basketball League|^NBL$', caseSensitive: false), 'Liga Basket Australia (NBL)'),
      MapEntry(RegExp(r'Philippines University Athletic Association|^UAAP$', caseSensitive: false), 'Liga Kampus Filipina (UAAP)'),
      MapEntry(RegExp(r'Turkish Basketball First League', caseSensitive: false), 'Liga Basket Turki (TBL)'),
      MapEntry(RegExp(r'Vietnam VBA|^VBA$', caseSensitive: false), 'Liga Basket Vietnam (VBA)'),
      MapEntry(RegExp(r'VTB United League Supercup', caseSensitive: false), 'Piala Super VTB Liga'),
      MapEntry(RegExp(r'Women National Basketball Association|^WNBA$', caseSensitive: false), 'Liga Basket Wanita Amerika (WNBA)'),
      MapEntry(RegExp(r'Liga Nacional de Baloncesto Profesional|^LNBP$', caseSensitive: false), 'Liga Basket Meksiko (LNBP)'),
      MapEntry(RegExp(r"Asian Games\s*-\s*Women'?s Basketball", caseSensitive: false), 'Asian Games - Bola Basket Putri'),
      MapEntry(RegExp(r'WTA Seoul.*', caseSensitive: false), 'WTA Seoul Tenis Putri'),
      MapEntry(RegExp(r'Davis Cup', caseSensitive: false), 'Piala Davis Tenis'),
      MapEntry(RegExp(r'European Championships', caseSensitive: false), 'Kejuaraan Eropa'),

      // Esports
      MapEntry(RegExp(r'LPL Regional Finals 2026', caseSensitive: false), 'Final Regional LPL 2026 (LoL)'),
      MapEntry(RegExp(r'VCS Finals 2026', caseSensitive: false), 'Final VCS 2026 (LoL)'),
      MapEntry(RegExp(r'Rift Legends Summer 2026', caseSensitive: false), 'Rift Legends Musim Panas 2026'),
      MapEntry(RegExp(r'LEC Summer 2026', caseSensitive: false), 'LEC Musim Panas 2026 (LoL)'),
      MapEntry(RegExp(r'LIT Summer 2026', caseSensitive: false), 'LIT Musim Panas 2026'),
      MapEntry(RegExp(r'LCS Summer 2026', caseSensitive: false), 'LCS Musim Panas 2026 (LoL)'),
      MapEntry(RegExp(r'PGL Wallachia Season 9', caseSensitive: false), 'PGL Wallachia Musim 9 (Dota 2)'),
      MapEntry(RegExp(r'European Pro League Season 40', caseSensitive: false), 'Liga Pro Eropa Musim 40'),
      MapEntry(RegExp(r'CCT 2026 Europe Series 9', caseSensitive: false), 'CCT 2026 Seri Eropa 9 (CS2)'),
      MapEntry(RegExp(r'StarLadder StarSeries Season 22', caseSensitive: false), 'StarLadder StarSeries Musim 22 (CS2)'),
      MapEntry(RegExp(r'NODWIN Clutch Series 12', caseSensitive: false), 'NODWIN Clutch Seri 12'),
      MapEntry(RegExp(r'HyperX Retake Season 12', caseSensitive: false), 'HyperX Retake Musim 12'),
      MapEntry(RegExp(r'CROSSFIRE Season 6', caseSensitive: false), 'CROSSFIRE Musim 6'),

      // Turnamen & Piala Internasional
      MapEntry(RegExp(r'Cúp C1|Champions League|UEFA Champions League', caseSensitive: false), 'Liga Champions'),
      MapEntry(RegExp(r'Cúp C2|Europa League|UEFA Europa League', caseSensitive: false), 'Liga Europa'),
      MapEntry(RegExp(r'Cúp C3|Conference League|UEFA Conference League', caseSensitive: false), 'Liga Konferensi Eropa'),
      MapEntry(RegExp(r'Cúp Liên Đoàn', caseSensitive: false), 'Piala Liga'),
      MapEntry(RegExp(r'Siêu Cúp', caseSensitive: false), 'Piala Super'),
      MapEntry(RegExp(r'Giao hữu quốc tế', caseSensitive: false), 'Laga Persahabatan Internasional'),
      MapEntry(RegExp(r'Giao hữu CLB', caseSensitive: false), 'Laga Persahabatan Klub'),
      MapEntry(RegExp(r'Giao hữu', caseSensitive: false), 'Laga Persahabatan'),
      MapEntry(RegExp(r'Giải vô địch', caseSensitive: false), 'Kejuaraan'),
      MapEntry(RegExp(r'Vòng loại World Cup', caseSensitive: false), 'Kualifikasi Piala Dunia'),
      MapEntry(RegExp(r'Vòng loại Asian Cup', caseSensitive: false), 'Kualifikasi Piala Asia'),
      MapEntry(RegExp(r'Vòng loại Euro', caseSensitive: false), 'Kualifikasi Euro'),
      MapEntry(RegExp(r'Vòng loại', caseSensitive: false), 'Kualifikasi'),
      MapEntry(RegExp(r'Bán kết', caseSensitive: false), 'Semifinal'),
      MapEntry(RegExp(r'Chung kết', caseSensitive: false), 'Final'),
      MapEntry(RegExp(r'Tứ kết', caseSensitive: false), 'Perempat Final'),
      MapEntry(RegExp(r'Vòng Bảng', caseSensitive: false), 'Fase Grup'),
      MapEntry(RegExp(r'Hạng 2', caseSensitive: false), 'Divisi 2'),
      MapEntry(RegExp(r'Hạng 3', caseSensitive: false), 'Divisi 3'),
      MapEntry(RegExp(r'Hạng 4', caseSensitive: false), 'Divisi 4'),
      MapEntry(RegExp(r'Hạng Nhất', caseSensitive: false), 'Divisi Utama'),
      MapEntry(RegExp(r'Ngoại Hạng', caseSensitive: false), 'Liga Utama'),
      MapEntry(RegExp(r'VĐQG', caseSensitive: false), 'Liga Utama'),
      MapEntry(RegExp(r'Cúp', caseSensitive: false), 'Piala'),
    ];

    for (final item in directList) {
      if (item.key.allMatches(text).isNotEmpty) {
        text = text.replaceAll(item.key, item.value);
        break;
      }
    }

    // 2. Pembersihan Frasa / Kata Pendukung
    final wordsList = <MapEntry<Pattern, String>>[
      MapEntry(RegExp(r'\bSeason\b', caseSensitive: false), 'Musim'),
      MapEntry(RegExp(r'\bSeries\b', caseSensitive: false), 'Seri'),
      MapEntry(RegExp(r'\bSummer\b', caseSensitive: false), 'Musim Panas'),
      MapEntry(RegExp(r'\bSpring\b', caseSensitive: false), 'Musim Semi'),
      MapEntry(RegExp(r'\bAutumn\b|\bFall\b', caseSensitive: false), 'Musim Gugur'),
      MapEntry(RegExp(r'\bWinter\b', caseSensitive: false), 'Musim Dingin'),
      MapEntry(RegExp(r'\bFinals\b', caseSensitive: false), 'Final'),
      MapEntry(RegExp(r'\bSemifinals\b', caseSensitive: false), 'Semifinal'),
      MapEntry(RegExp(r'\bQuarterfinals\b', caseSensitive: false), 'Perempat Final'),
      MapEntry(RegExp(r'\bSingles\b', caseSensitive: false), 'Tunggal'),
      MapEntry(RegExp(r'\bDoubles\b', caseSensitive: false), 'Ganda'),
      MapEntry(RegExp(r'\bWomen\b|\bNữ\b', caseSensitive: false), 'Wanita'),
      MapEntry(RegExp(r'\bMen\b|\bNam\b', caseSensitive: false), 'Pria'),
      MapEntry(RegExp(r'\bCLB\s+', caseSensitive: false), 'Klub '),
      MapEntry(RegExp(r'\bNhật Bản\b', caseSensitive: false), 'Jepang'),
      MapEntry(RegExp(r'\bHàn Quốc\b', caseSensitive: false), 'Korea Selatan'),
      MapEntry(RegExp(r'\bTrung Quốc\b', caseSensitive: false), 'China'),
      MapEntry(RegExp(r'\bTây Ban Nha\b', caseSensitive: false), 'Spanyol'),
      MapEntry(RegExp(r'\bÝ\b'), 'Italia'),
      MapEntry(RegExp(r'\bĐức\b', caseSensitive: false), 'Jerman'),
      MapEntry(RegExp(r'\bPháp\b', caseSensitive: false), 'Prancis'),
      MapEntry(RegExp(r'\bAnh\b'), 'Inggris'),
      MapEntry(RegExp(r'\bHà Lan\b', caseSensitive: false), 'Belanda'),
      MapEntry(RegExp(r'\bBồ Đào Nha\b', caseSensitive: false), 'Portugal'),
      MapEntry(RegExp(r'\bThái Lan\b', caseSensitive: false), 'Thailand'),
      MapEntry(RegExp(r'\bMỹ\b|\bHoa Kỳ\b', caseSensitive: false), 'Amerika Serikat'),
      MapEntry(RegExp(r'\bÚc\b', caseSensitive: false), 'Australia'),
      MapEntry(RegExp(r'\bẢ Rập Xê Út\b|\bẢ Rập Saudi\b', caseSensitive: false), 'Arab Saudi'),
      MapEntry(RegExp(r'\bViệt Nam\b', caseSensitive: false), 'Vietnam'),
    ];

    for (final item in wordsList) {
      text = text.replaceAll(item.key, item.value);
    }

    // 3. Hapus duplikasi tanda kurung atau pengulangan nama negara seperti (Jepang) (Jepang) atau Jepang (Jepang)
    text = text.replaceAll(RegExp(r'\(([^)]+)\)\s*\(\1\)', caseSensitive: false), r'($1)');
    text = text.replaceAll(RegExp(r'\b(Jepang|Inggris|Spanyol|Italia|Jerman|Prancis|Belanda|Portugal|Vietnam|China|Korea Selatan|Australia)\s+\(\1\)', caseSensitive: false), r'$1');
    text = text.replaceAll(RegExp(r'\((Jepang|Inggris|Spanyol|Italia|Jerman|Prancis|Belanda|Portugal|Vietnam|China|Korea Selatan|Australia)\)\s+\1', caseSensitive: false), r'$1');

    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
