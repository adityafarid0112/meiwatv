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

  // Daftar domain sumber siaran live lengkap dari Link nonton Online.txt
  static const List<String> onlineSeeds = [
    'https://xoilacz.vip/',
    'https://tft-forests.org/',
    'https://socolivezc.tv/',
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

    // 4. Jadwalkan auto-refresh setiap 3 menit agar daftar selalu terupdate
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 3), (_) {
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

  // URL GitHub Raw untuk auto-update pertandingan tanpa compile ulang
  static const String githubRawUrl =
      'https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/matches.json';

  /// Mengambil siaran langsung terbaru (utamakan GitHub Raw, lalu fallback ke seed online)
  Future<void> refreshOnlineMatches() async {
    try {
      // 1. Prioritas Utama: Ambil dari GitHub Raw (Otomatis diupdate oleh GitHub Actions robot)
      try {
        final ghUri = Uri.parse('$githubRawUrl?t=${DateTime.now().millisecondsSinceEpoch}');
        final ghRes = await http.get(ghUri, headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        }).timeout(const Duration(seconds: 7));
        if (ghRes.statusCode == 200 && ghRes.body.isNotEmpty) {
          final List<dynamic> decoded = json.decode(ghRes.body);
          if (decoded.isNotEmpty) {
            _cachedMatches = decoded
                .map((item) => MatchModel.fromJson(item as Map<String, dynamic>))
                .toList();
            _matchesController.add(_cachedMatches);
            debugPrint('✅ Berhasil memuat ${_cachedMatches.length} siaran dari GitHub Raw!');
            return;
          }
        }
      } catch (ghErr) {
        debugPrint('GitHub Raw fetch info: $ghErr');
      }

      // 2. Fallback cadangan jika GitHub belum terisi: hubungi domain online langsung
      String html = '';
      String activeDomain = '';

      for (final seed in onlineSeeds) {
        try {
          final res = await http.get(
            Uri.parse(seed),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml',
            },
          ).timeout(const Duration(seconds: 8));

          if (res.statusCode == 200 && res.body.contains('grid-matches__item')) {
            html = res.body;
            activeDomain = seed.endsWith('/') ? seed.substring(0, seed.length - 1) : seed;
            break;
          }
        } catch (_) {
          continue;
        }
      }

      if (html.isEmpty) return;

      final parsed = _parseMatchesFromHtml(html, activeDomain);
      if (parsed.isNotEmpty) {
        _cachedMatches = parsed;
        _matchesController.add(_cachedMatches);
      }
    } catch (e) {
      debugPrint('Error fetching online matches: $e');
    }
  }

  /// Parser HTML untuk semua cabang olahraga (Sepak Bola, Basket, Voli, Bulutangkis, Tenis, Lainnya)
  List<MatchModel> _parseMatchesFromHtml(String html, String activeDomain) {
    final List<MatchModel> list = [];
    final cardRegex = RegExp(
      r'<div[^>]*class="[^"]*grid-matches__item[^"]*"[^>]*data-sport="([^"]+)"[^>]*>([\s\S]*?)(?=(?:<div[^>]*class="[^"]*grid-matches__item|<div[^>]*class="sport-content-tab|<\/body|$))',
      caseSensitive: false,
    );

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final matches = cardRegex.allMatches(html);
    int matchIndex = 0;

    for (final m in matches) {
      final sportType = (m.group(1) ?? 'football').toLowerCase();
      final cardContent = m.group(2) ?? '';

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

      final hour = timeStr.substring(0, 2);
      final min = timeStr.substring(2, 4);

      // Liga
      final leagueMatch = RegExp(
        r'class="[^"]*text-ellipsis[^"]*"[^>]*>\s*([^<]+)\s*<\/span>',
        caseSensitive: false,
      ).firstMatch(cardContent);
      String league = leagueMatch != null ? leagueMatch.group(1)!.trim() : 'Live Sports';
      league = league.replaceAll('&#039;', "'").replaceAll('&amp;', '&');

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

      final title = '$home vs $away';

      // Kategori Olahraga
      String category = '⚽ Sepak Bola';
      if (sportType == 'basketball') {
        category = '🏀 Bola Basket';
      } else if (sportType == 'volleyball') {
        category = '🏐 Bola Voli';
      } else if (sportType == 'badminton') {
        category = '🏸 Bulu Tangkis';
      } else if (sportType == 'tennis') {
        category = '🎾 Tenis';
      } else if (sportType != 'football') {
        category = '🏎️ Olahraga Lainnya';
      }

      // Hitung Kickoff & Status
      final kickoffIso = '$year-$month-$day' 'T$hour:$min:00+07:00';
      final kickoffTime = DateTime.tryParse('$year-$month-$day $hour:$min:00') ?? now;
      final diffMs = kickoffTime.millisecondsSinceEpoch - nowMs;

      int status = 0;
      if (diffMs <= 0 && diffMs > -14400000) {
        status = 1; // Live (sedang berlangsung dalam rentang 4 jam)
      } else if (diffMs <= -14400000) {
        status = 2; // Selesai
      } else {
        status = 0; // Upcoming
      }

      // Jangan tampilkan pertandingan yang sudah selesai lebih dari 4 jam
      if (status == 2) continue;

      matchIndex++;
      final matchPageUrl = '$activeDomain$relUrl';

      // Jalur channel siaran: Pertahankan channel asli yang sudah ada di cache
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

      if (ch1.isEmpty) {
        ch1 = '${matchPageUrl}link/0';
      }
      if (ch2.isEmpty) {
        ch2 = '${matchPageUrl}link/1';
      }
      final ch3 = matchPageUrl;

      list.add(MatchModel(
        id: 'match_${matchIndex}_${slugName.substring(0, slugName.length > 25 ? 25 : slugName.length)}',
        title: title,
        homeTeam: home,
        awayTeam: away,
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

    // Urutkan: Live (status == 1) di bagian atas
    list.sort((a, b) {
      if (b.status != a.status) return b.status.compareTo(a.status);
      return a.kickoffIso.compareTo(b.kickoffIso);
    });

    return list;
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

  void dispose() {
    _autoRefreshTimer?.cancel();
    _matchesController.close();
  }
}
