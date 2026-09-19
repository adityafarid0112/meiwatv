import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/match_model.dart';

class MatchService {
  static final MatchService _instance = MatchService._internal();
  factory MatchService() => _instance;
  MatchService._internal();

  bool _isFirebaseReady = false;
  List<MatchModel> _cachedMatches = [];
  final StreamController<List<MatchModel>> _matchesController =
      StreamController<List<MatchModel>>.broadcast();
  Timer? _autoRefreshTimer;

  // Daftar domain sumber siaran live lengkap (semua seeds dari Link nonton Online.txt)
  static const List<String> onlineSeeds = [
    'https://xoilaczzf.cc/',
    'https://xoilacz.vip/',
    'https://tft-forests.org/',
    'https://xoilaczbi.tv/',
    'https://socolivezc.tv/',
    'https://theceoschool.co/',
    'https://atttvnow.com/',
    'https://xoilackl.tv/',
    'https://90phutcn.tv/',
    'https://cakhiazkv.cc/',
    'https://xoilaccu.tv/',
    'https://vebotvx.cc/',
    'https://rakhoiib.cc/',
    'https://mitomzm.cc/',
    'https://vaoroig.cc/',
    'https://malaysiandigest.com/',
  ];

  /// Inisialisasi service, muat data lokal segera, lalu ambil data online terbaru
  Future<void> initialize() async {
    // 1. Muat dataset lokal segera untuk tampilan instan tanpa loading lama
    await _loadLocalMatches();

    // 2. Coba inisialisasi Firebase jika tersedia
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseReady = true;
      } else {
        await Firebase.initializeApp();
        _isFirebaseReady = true;
      }
    } catch (_) {
      _isFirebaseReady = false;
    }

    // 3. Ambil data pertandingan terbaru dari sumber live online
    unawaited(refreshOnlineMatches());

    // 4. Jadwalkan auto-refresh setiap 2 menit agar daftar selalu sinkron
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      refreshOnlineMatches();
    });
  }

  /// Memuat pertandingan dari file aset lokal
  Future<void> _loadLocalMatches() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/matches.json');
      final List<dynamic> decoded = json.decode(jsonString);
      _cachedMatches = decoded
          .map((item) => MatchModel.fromJson(item as Map<String, dynamic>))
          .toList();
      _matchesController.add(_cachedMatches);
    } catch (e) {
      if (_cachedMatches.isEmpty) {
        _cachedMatches = _getFallbackMatches();
        _matchesController.add(_cachedMatches);
      }
    }
  }

  // URL CDN dan Portal untuk auto-update pertandingan tanpa compile ulang
  static const String portalUrl =
      'http://meiwa.my.id/matches.json';
  static const String githubRawUrl =
      'https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/matches.json';
  static const String jsdelivrCdnUrl =
      'https://cdn.jsdelivr.net/gh/adityafarid0112/meiwatv@main/matches.json';

  /// Mengambil siaran langsung terbaru (utamakan Portal / CDN / GitHub jika masih fresh, atau langsung scrape sumber web)
  Future<void> refreshOnlineMatches({bool forceDirectScrape = false}) async {
    try {
      // 1. Jika tidak dipaksa scrape langsung, coba cek Portal / GitHub / CDN terlebih dahulu
      if (!forceDirectScrape) {
        final endpoints = [portalUrl, githubRawUrl, jsdelivrCdnUrl];
        for (final endpoint in endpoints) {
          try {
            final uri = Uri.parse('$endpoint?t=${DateTime.now().millisecondsSinceEpoch}');
            final res = await http.get(uri, headers: {
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
            }).timeout(const Duration(seconds: 6));

            if (res.statusCode == 200 && res.body.isNotEmpty) {
              final List<dynamic> decoded = json.decode(res.body);
              if (decoded.isNotEmpty) {
                // Cek apakah dataset masih segar (< 15 menit)
                final firstItem = decoded.first as Map<String, dynamic>;
                final updatedStr = firstItem['updatedAt'] as String?;
                bool isStale = false;
                if (updatedStr != null) {
                  final updateTime = DateTime.tryParse(updatedStr);
                  if (updateTime != null) {
                    final ageMins = DateTime.now().toUtc().difference(updateTime).inMinutes;
                    if (ageMins > 15) {
                      isStale = true;
                    }
                  }
                }

                _cachedMatches = decoded
                    .map((item) => MatchModel.fromJson(item as Map<String, dynamic>))
                    .toList();
                _matchesController.add(_cachedMatches);

                if (!isStale) {
                  debugPrint('✅ Berhasil memuat data segar (${_cachedMatches.length} siaran) dari $endpoint');
                  return;
                } else {
                  debugPrint('⚠️ Data di $endpoint berusia > 15 menit, melanjutkan live scraping...');
                  break;
                }
              }
            }
          } catch (ghErr) {
            debugPrint('Info fetch $endpoint: $ghErr');
          }
        }
      }

      // 2. Scrape langsung dari sumber live online utama (Xoilac & Socolive)
      final List<MatchModel> directParsed = [];
      final Set<String> seenRelUrls = {};

      for (final seed in onlineSeeds.take(3)) {
        try {
          final res = await http.get(
            Uri.parse(seed),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml',
            },
          ).timeout(const Duration(seconds: 6));

          if (res.statusCode == 200 && res.body.contains('grid-matches__item')) {
            final activeDomain = seed.endsWith('/') ? seed.substring(0, seed.length - 1) : seed;
            final matches = _parseMatchesFromHtml(res.body, activeDomain, seenRelUrls);
            directParsed.addAll(matches);
          }
        } catch (_) {
          continue;
        }
      }

      if (directParsed.isNotEmpty) {
        _sortMatches(directParsed);
        _cachedMatches = directParsed;
        _matchesController.add(_cachedMatches);
        debugPrint('✅ Berhasil live scraping ${directParsed.length} siaran langsung dari sumber web!');
      }
    } catch (e) {
      debugPrint('Error fetching online matches: $e');
    }
  }

  /// Parser HTML untuk semua cabang olahraga dari sumber live (Xoilac & Socolive)
  List<MatchModel> _parseMatchesFromHtml(
      String html, String activeDomain, Set<String> seenRelUrls) {
    final List<MatchModel> list = [];
    final cardRegex = RegExp(
      r'<div([^>]*class="[^"]*grid-matches__item[^"]*"[^>]*)>([\s\S]*?)(?=(?:<div[^>]*class="[^"]*grid-matches__item|<div[^>]*class="sport-content-tab|<\/body|$))',
      caseSensitive: false,
    );

    final matches = cardRegex.allMatches(html);
    int matchIndex = 0;

    for (final m in matches) {
      final cardHeader = m.group(1) ?? '';
      final cardContent = m.group(2) ?? '';

      // Abaikan elemen iklan
      if (cardHeader.contains('xlz-ads-item')) continue;

      // Ekstrak atribut header
      final sportMatch = RegExp(r'data-sport="([^"]+)"', caseSensitive: false).firstMatch(cardHeader);
      final sportType = (sportMatch?.group(1) ?? 'football').toLowerCase();

      final statusAttrMatch = RegExp(r'data-status="([^"]+)"', caseSensitive: false).firstMatch(cardHeader);
      final rawStatus = statusAttrMatch?.group(1) ?? '1';

      // Ekstrak URL pertandingan
      final linkMatch = RegExp(
        r'href="(\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\/)"',
        caseSensitive: false,
      ).firstMatch(cardContent);

      if (linkMatch == null) continue;

      final relUrl = linkMatch.group(1) ?? '';
      final slugName = linkMatch.group(2) ?? '';
      final timeStr = linkMatch.group(3) ?? '0000';
      final day = linkMatch.group(4) ?? '01';
      final month = linkMatch.group(5) ?? '01';
      final year = linkMatch.group(6) ?? '2026';

      if (seenRelUrls.contains(relUrl)) continue;
      seenRelUrls.add(relUrl);

      // Abaikan status 8 (selesai lama/dibatalkan)
      if (rawStatus == '8') continue;

      final hour = timeStr.substring(0, 2);
      final min = timeStr.substring(2, 4);

      // Liga
      final leagueMatch = RegExp(
        r'class="[^"]*text-ellipsis[^"]*"[^>]*>\s*([^<]+)\s*<\/span>',
        caseSensitive: false,
      ).firstMatch(cardContent);
      String league = leagueMatch != null ? leagueMatch.group(1)!.trim() : 'Turnamen Olahraga';
      league = league.replaceAll('&#039;', "'").replaceAll('&amp;', '&');
      league = _translateToId(league);

      // Home & Away IDs & Logos
      final homeTeamIdMatch = RegExp(r'data-home-team-id="([^"]+)"', caseSensitive: false).firstMatch(cardHeader);
      final awayTeamIdMatch = RegExp(r'data-away-team-id="([^"]+)"', caseSensitive: false).firstMatch(cardHeader);
      final homeTeamId = homeTeamIdMatch?.group(1) ?? '';
      final awayTeamId = awayTeamIdMatch?.group(1) ?? '';

      final homeImgMatch = RegExp(r'team-logo-group-home-logo[^>]*>\s*<img[^>]+src=[\x27\x22]([^\x27\x22]+)[\x27\x22]', caseSensitive: false).firstMatch(cardContent);
      final awayImgMatch = RegExp(r'team-logo-group-away-logo[^>]*>\s*<img[^>]+src=[\x27\x22]([^\x27\x22]+)[\x27\x22]', caseSensitive: false).firstMatch(cardContent);

      String homeLogo = (homeImgMatch != null && homeImgMatch.group(1)!.startsWith('http'))
          ? homeImgMatch.group(1)!
          : (homeTeamId.isNotEmpty ? 'https://imgts.sportpulseapiz.com/$sportType/team/$homeTeamId/image/small' : '');
      String awayLogo = (awayImgMatch != null && awayImgMatch.group(1)!.startsWith('http'))
          ? awayImgMatch.group(1)!
          : (awayTeamId.isNotEmpty ? 'https://imgts.sportpulseapiz.com/$sportType/team/$awayTeamId/image/small' : '');

      // Tim Home & Away
      final homeMatch = RegExp(
        r'class="[^"]*grid-match__team--home-name[^"]*"[^>]*>\s*([^<]+)\s*<\/div>',
        caseSensitive: false,
      ).firstMatch(cardContent);
      final awayMatch = RegExp(
        r'class="[^"]*grid-match__team--away-name[^"]*"[^>]*>\s*([^<]+)\s*<\/div>',
        caseSensitive: false,
      ).firstMatch(cardContent);

      String home = homeMatch != null ? homeMatch.group(1)!.trim() : '';
      String away = awayMatch != null ? awayMatch.group(1)!.trim() : '';

      if (home.isEmpty || away.isEmpty) {
        final raw = slugName.replaceAll('-', ' ');
        final parts = raw.split(RegExp(r'\s+vs\s+|\s+-\s+', caseSensitive: false));
        home = home.isNotEmpty ? home : (parts.isNotEmpty ? parts[0].trim() : 'Tim 1');
        away = away.isNotEmpty ? away : (parts.length > 1 ? parts[1].trim() : 'Tim 2');
      }

      home = _translateToId(home);
      away = _translateToId(away);
      final title = '$home vs $away';

      // Kategori Olahraga
      String category = '⚽ Sepak Bola';
      final lowerAll = '$sportType $slugName $league'.toLowerCase();
      if (sportType == 'basketball' || lowerAll.contains('basket') || lowerAll.contains('nba')) {
        category = '🏀 Bola Basket';
      } else if (sportType == 'volleyball' || lowerAll.contains('voli') || lowerAll.contains('volleyball')) {
        category = '🏐 Bola Voli';
      } else if (sportType == 'badminton' || lowerAll.contains('badminton') || lowerAll.contains('bulu tangkis')) {
        category = '🏸 Bulu Tangkis';
      } else if (sportType == 'tennis' || lowerAll.contains('tenis') || lowerAll.contains('tennis') || lowerAll.contains('wta') || lowerAll.contains('atp')) {
        category = '🎾 Tenis';
      } else if (['lol', 'csgo', 'dota2', 'esport', 'esports'].contains(sportType) || lowerAll.contains('esport') || lowerAll.contains('lpl') || lowerAll.contains('lcs') || lowerAll.contains('lec') || lowerAll.contains('lit') || lowerAll.contains('vcs') || lowerAll.contains('gaming') || lowerAll.contains('pgl') || lowerAll.contains('dota') || lowerAll.contains('crossfire')) {
        category = '🎮 Esports & Gaming';
      } else if (sportType != 'football') {
        category = '🏎️ Olahraga Lainnya';
      }

      final kickoffIso = '$year-$month-$day' 'T$hour:$min:00+07:00';

      // Penentuan Status LIVE yang 100% Akurat untuk SEMUA cabang olahraga:
      int status = 0;
      final DateTime? matchDate = DateTime.tryParse(kickoffIso);
      final DateTime now = DateTime.now();
      final double diffMinutes = matchDate != null
          ? (now.difference(matchDate).inSeconds / 60.0)
          : -999.0;

      if (diffMinutes < -5) {
        status = 0; // Terjadwal / Belum Mulai
      } else if (diffMinutes >= -5 && diffMinutes <= 150) {
        status = 1; // Sedang LIVE
      } else {
        status = 2; // Selesai
      }

      final contentLower = cardContent.toLowerCase();
      if (contentLower.contains('>ft<') ||
          contentLower.contains('kết thúc') ||
          contentLower.contains('finished') ||
          contentLower.contains('hết giờ')) {
        status = 2; // Selesai
      }

      // Ekstraksi Skor & Menit Pertandingan Real-Time (Hanya saat LIVE / FT)
      String homeScore = '';
      String awayScore = '';
      String scoreText = '';
      String matchMinute = '';

      if (status == 1 || status == 2) {
        final hpuScore = RegExp(r'class="[^"]*hpu-score-home[^"]*"[^>]*>\s*(\d+)\s*<\/span>[\s\S]*?class="[^"]*hpu-score-away[^"]*"[^>]*>\s*(\d+)\s*<\/span>', caseSensitive: false).firstMatch(cardContent);
        final realScoreMatch = RegExp(r'class="[^"]*score-(?:live|real|current)[^"]*"[^>]*>\s*(\d+)\s*[-:]\s*(\d+)', caseSensitive: false).firstMatch(cardContent);

        if (hpuScore != null) {
          homeScore = hpuScore.group(1)?.trim() ?? '';
          awayScore = hpuScore.group(2)?.trim() ?? '';
          scoreText = '$homeScore - $awayScore';
        } else if (realScoreMatch != null) {
          homeScore = realScoreMatch.group(1)?.trim() ?? '';
          awayScore = realScoreMatch.group(2)?.trim() ?? '';
          scoreText = '$homeScore - $awayScore';
        }

        final periodMatch = RegExp(r'class="[^"]*(?:period|quarter|set-name|match-time)[^"]*"[^>]*>\s*([^<]+)\s*<', caseSensitive: false).firstMatch(cardContent);
        if (periodMatch != null) {
          String pm = periodMatch.group(1)?.trim() ?? '';
          if (!RegExp(r'^\d+\s*[-:]\s*\d+$').hasMatch(pm)) {
            pm = pm
                .replaceAll(RegExp('Hiệp 1', caseSensitive: false), 'Babak 1')
                .replaceAll(RegExp('Hiệp 2', caseSensitive: false), 'Babak 2')
                .replaceAll(RegExp('Nghỉ giữa hiệp', caseSensitive: false), 'Turun Minum')
                .replaceAll(RegExp('Hết giờ', caseSensitive: false), 'Selesai');
            matchMinute = pm;
          }
        }
      }

      matchIndex++;
      final matchPageUrl = '$activeDomain$relUrl';

      // Jalur channel siaran: Pertahankan channel asli dari cache jika tersedia
      final existingIndex = _cachedMatches.indexWhere((m) =>
          m.streamJalur3.contains(slugName) ||
          m.id.contains(slugName.substring(0, slugName.length > 20 ? 20 : slugName.length)));

      String ch1 = '';
      String ch2 = '';
      if (existingIndex != -1) {
        final existing = _cachedMatches[existingIndex];
        if (existing.streamJalur1.isNotEmpty && !existing.streamJalur1.contains('/channel1/')) {
          ch1 = existing.streamJalur1;
        }
        if (existing.streamJalur2.isNotEmpty) {
          ch2 = existing.streamJalur2;
        }
      }

      if (ch1.isEmpty) ch1 = matchPageUrl;
      if (ch2.isEmpty) ch2 = matchPageUrl;
      final ch3 = matchPageUrl;

      list.add(MatchModel(
        id: 'match_${matchIndex}_${slugName.substring(0, slugName.length > 25 ? 25 : slugName.length)}',
        title: title,
        homeTeam: home,
        awayTeam: away,
        homeLogo: homeLogo,
        awayLogo: awayLogo,
        homeScore: homeScore,
        awayScore: awayScore,
        scoreText: scoreText,
        matchMinute: matchMinute,
        league: league,
        kickoffIso: kickoffIso,
        kickoffText: '$hour:$min WIB ($day/$month)',
        status: status,
        sportCategory: category,
        streamJalur1: ch1,
        streamJalur2: ch2,
        streamJalur3: ch3,
      ));
    }

    return list;
  }

  /// Pertahankan 100% urutan persis seperti tampilan di web sumber aslinya tanpa diacak
  void _sortMatches(List<MatchModel> list) {
    // No artificial sorting - preserve natural web order
  }

  /// Stream real-time pertandingan
  Stream<List<MatchModel>> getMatchesStream() {
    if (_cachedMatches.isNotEmpty) {
      // Langsung emit data cache agar instan
      Future.microtask(() => _matchesController.add(_cachedMatches));
    }

    if (_isFirebaseReady) {
      try {
        FirebaseFirestore.instance
            .collection('matches')
            .orderBy('kickoffIso', descending: false)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final fbMatches = snapshot.docs.map((doc) {
              return MatchModel.fromJson(doc.data(), docId: doc.id);
            }).toList();
            _cachedMatches = fbMatches;
            _matchesController.add(_cachedMatches);
          }
        }, onError: (_) {});
      } catch (_) {}
    }

    return _matchesController.stream;
  }

  List<MatchModel> _getFallbackMatches() {
    return [
      const MatchModel(
        id: 'match_1',
        title: 'Arsenal vs Chelsea',
        homeTeam: 'Arsenal',
        awayTeam: 'Chelsea',
        league: 'Premier League',
        kickoffIso: '2026-09-17T21:00:00+07:00',
        kickoffText: 'Hari ini, 21:00 WIB',
        status: 1,
        sportCategory: '⚽ Sepak Bola',
        streamJalur1: 'https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel18/off-tvc?is_off_add=false',
        streamJalur2: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
        streamJalur3: 'https://cdn.livepush.io/live/bigbuckbunnyclip/index.m3u8',
      ),
    ];
  }

  String _translateToId(String text) {
    if (text.isEmpty) return '';
    String result = text;

    final Map<String, String> replacements = {
      'Ngoại Hạng Anh': 'Premier League (Inggris)',
      'VĐQG Indonesia': 'BRI Liga 1 Indonesia',
      'Hạng 2 Indonesia': 'Liga 2 Indonesia',
      'Hạng 3 Indonesia': 'Liga 3 Indonesia',
      'Cúp Quốc Gia Việt Nam': 'Piala Nasional Vietnam',
      'VĐQG Việt Nam': 'V.League 1 (Vietnam)',
      'VĐQG Tây Ban Nha': 'La Liga (Spanyol)',
      'VĐQG Ý': 'Serie A (Italia)',
      'VĐQG Đức': 'Bundesliga (Jerman)',
      'VĐQG Pháp': 'Ligue 1 (Prancis)',
      'VĐQG Hà Lan': 'Eredivisie (Belanda)',
      'VĐQG Bồ Đào Nha': 'Liga Portugal',
      'VĐQG Saudi Arabia': 'Saudi Pro League',
      'VĐQG Ả Rập Xê Út': 'Saudi Pro League',
      'VĐQG Nhật Bản': 'J1 League (Jepang)',
      'VĐQG Hàn Quốc': 'K League 1 (Korea Selatan)',
      'Hạng Nhất Ukraina': 'Liga Utama Ukraina',
      'Hạng Nhất Anh': 'Championship (Inggris)',
      'Hạng 2 Trung Quốc': 'Liga 2 China',
      'Hạng 2 Romania': 'Liga 2 Rumania',
      'Hạng 2 Tây Ban Nha': 'La Liga 2 (Spanyol)',
      'Hạng 2 Đức': '2. Bundesliga (Jerman)',
      'Hạng 2 Ý': 'Serie B (Italia)',
      'Hạng 2 Pháp': 'Ligue 2 (Prancis)',
      'Ngoại Hạng Darwin': 'Liga Utama Darwin (Australia)',
      'Czech 3 liga': 'Liga 3 Republik Ceko',
      'Bangladesh Premier League': 'Liga Utama Bangladesh',
      'National Basketball League': 'Liga Basket Nasional (NBL)',
      'Philippines University Athletic Association': 'Liga Universitas Filipina (UAAP)',
      'Turkish Basketball First League': 'Liga Basket Divisi 1 Turki',
      'Vietnam VBA': 'Liga Basket Vietnam (VBA)',
      'VTB United League Supercup': 'Piala Super VTB United League',
      'Italy Super Cup': 'Piala Super Italia',
      'Basketball Bundesliga': 'Bundesliga Basket (Jerman)',
      'Spain Basketball Supercopa': 'Piala Super Basket Spanyol',
      'Women National Basketball Association': 'Liga Basket Wanita Amerika (WNBA)',
      'Liga Nacional de Baloncesto Profesional': 'Liga Basket Profesional Meksiko (LNBP)',
      'Asian Games - Women\'s Basketball': 'Asian Games - Bola Basket Putri',
      'Copa del Rey de Baloncesto': 'Piala Raja Basket Spanyol',
      'WTA Seoul, Korea Republic Women Singles': 'WTA Seoul (Tunggal Putri Korea Selatan)',
      'Davis Cup': 'Piala Davis (Tenis)',
      'European Championships': 'Kejuaraan Eropa',
      'LPL Regional Finals 2026': 'Final Regional LPL 2026 (LoL)',
      'VCS Finals 2026': 'Final VCS 2026 (LoL)',
      'Rift Legends Summer 2026': 'Rift Legends Musim Panas 2026',
      'LEC Summer 2026': 'LEC Musim Panas 2026 (LoL)',
      'LIT Summer 2026': 'LIT Musim Panas 2026',
      'LCS Summer 2026': 'LCS Musim Panas 2026 (LoL)',
      'PGL Wallachia Season 9': 'PGL Wallachia Musim 9 (Dota 2)',
      'European Pro League Season 40': 'Liga Pro Eropa Musim 40',
      'CCT 2026 Europe Series 9': 'CCT 2026 Seri Eropa 9 (CS2)',
      'StarLadder StarSeries Season 22': 'StarLadder StarSeries Musim 22 (CS2)',
      'NODWIN Clutch Series 12': 'NODWIN Clutch Seri 12',
      'HyperX Retake Season 12': 'HyperX Retake Musim 12',
      'CROSSFIRE Season 6': 'CROSSFIRE Musim 6',
      'Cúp C1': 'Liga Champions',
      'Champions League': 'Liga Champions',
      'Cúp C2': 'Liga Europa',
      'Europa League': 'Liga Europa',
      'Cúp C3': 'Liga Konferensi Eropa',
      'Conference League': 'Liga Konferensi Eropa',
      'Cúp FA': 'Piala FA (Inggris)',
      'Cúp Nhà Vua': 'Copa del Rey (Spanyol)',
      'Cúp Quốc Gia': 'Piala Nasional',
      'Cúp Liên Đoàn': 'Piala Liga',
      'Siêu Cúp': 'Piala Super',
      'Giao hữu quốc tế': 'Laga Persahabatan Internasional',
      'Giao hữu CLB': 'Laga Persahabatan Klub',
      'Giao hữu': 'Laga Persahabatan',
      'Giải vô địch': 'Kejuaraan',
      'Vòng loại World Cup': 'Kualifikasi Piala Dunia',
      'Vòng loại Asian Cup': 'Kualifikasi Piala Asia',
      'Vòng loại Euro': 'Kualifikasi Euro',
      'Vòng loại': 'Kualifikasi',
      'Bán kết': 'Semifinal',
      'Chung kết': 'Final',
      'Tứ kết': 'Perempat Final',
      'Vòng Bảng': 'Fase Grup',
      'Hạng 2': 'Divisi 2',
      'Hạng 3': 'Divisi 3',
      'Hạng 4': 'Divisi 4',
      'Hạng Nhất': 'Divisi Utama',
      'VĐQG': 'Liga Utama',
      'Cúp': 'Piala',
      'Season': 'Musim',
      'Series': 'Seri',
      'Summer': 'Musim Panas',
      'Spring': 'Musim Semi',
      'Autumn': 'Musim Gugur',
      'Winter': 'Musim Dingin',
      'Finals': 'Final',
      'Semifinals': 'Semifinal',
      'Quarterfinals': 'Perempat Final',
      'Singles': 'Tunggal',
      'Doubles': 'Ganda',
      'Women': 'Wanita',
      'Nữ': 'Wanita',
      'Men': 'Pria',
      'Nam': 'Pria',
      'Trẻ': 'Muda',
      'CLB ': 'Klub ',
      'Nhật Bản': 'Jepang',
      'Hàn Quốc': 'Korea Selatan',
      'Triều Tiên': 'Korea Utara',
      'Trung Quốc': 'China',
      'Đài Loan': 'Taiwan',
      'Hồng Kông': 'Hong Kong',
      'Tây Ban Nha': 'Spanyol',
      'Ý': 'Italia',
      'Đức': 'Jerman',
      'Pháp': 'Prancis',
      'Anh': 'Inggris',
      'Hà Lan': 'Belanda',
      'Bồ Đào Nha': 'Portugal',
      'Thái Lan': 'Thailand',
      'Mỹ': 'Amerika Serikat',
      'Hoa Kỳ': 'Amerika Serikat',
      'Úc': 'Australia',
      'Thụy Sĩ': 'Swiss',
      'Thụy Điển': 'Swedia',
      'Thổ Nhĩ Kỳ': 'Turki',
      'Nga': 'Rusia',
      'Hy Lạp': 'Yunani',
      'Ả Rập Xê Út': 'Arab Saudi',
      'Indonesia': 'Indonesia',
      'Việt Nam': 'Vietnam',
    };

    replacements.forEach((key, val) {
      result = result.replaceAll(RegExp(key, caseSensitive: false), val);
    });

    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void dispose() {
    _autoRefreshTimer?.cancel();
    _matchesController.close();
  }
}
