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

  // Daftar domain sumber siaran live lengkap (utamakan domain aktif teruji)
  static const List<String> onlineSeeds = [
    'https://xoilaczbi.tv/',
    'https://theceoschool.co/',
    'https://xoilacz.vip/',
    'https://socolivezc.tv/',
    'https://tft-forests.org/',
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

  // URL CDN dan GitHub Raw untuk auto-update pertandingan tanpa compile ulang
  static const String jsdelivrCdnUrl =
      'https://cdn.jsdelivr.net/gh/adityafarid0112/meiwatv@main/matches.json';
  static const String githubRawUrl =
      'https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/matches.json';

  /// Mengambil siaran langsung terbaru (utamakan CDN / GitHub jika masih fresh, atau langsung scrape sumber web)
  Future<void> refreshOnlineMatches({bool forceDirectScrape = false}) async {
    try {
      // 1. Jika tidak dipaksa scrape langsung, coba cek GitHub / CDN terlebih dahulu
      if (!forceDirectScrape) {
        final endpoints = [githubRawUrl, jsdelivrCdnUrl];
        for (final endpoint in endpoints) {
          try {
            final uri = Uri.parse('$endpoint?t=${DateTime.now().millisecondsSinceEpoch}');
            final res = await http.get(uri, headers: {
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
            }).timeout(const Duration(seconds: 8));

            if (res.statusCode == 200 && res.body.isNotEmpty) {
              final List<dynamic> decoded = json.decode(res.body);
              if (decoded.isNotEmpty) {
                // Cek apakah dataset GitHub masih segar (< 15 menit)
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
                  debugPrint('⚠️ Data GitHub berusia > 15 menit, melanjutkan scraping live langsung...');
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
      String league = leagueMatch != null ? leagueMatch.group(1)!.trim() : 'Live Sports';
      league = league.replaceAll('&#039;', "'").replaceAll('&amp;', '&');

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

      final kickoffIso = '$year-$month-$day' 'T$hour:$min:00+07:00';

      // Penentuan Status LIVE akurat dari sumber web
      int status = 0;
      if (['2', '3', '51', '52', '438'].contains(rawStatus) ||
          cardContent.contains('is-live') ||
          cardContent.contains('badge-live')) {
        status = 1; // 🔴 LIVE SEKARANG
      } else if (rawStatus == '4') {
        status = 2; // Selesai (Full Time)
      } else {
        status = 0; // Upcoming
      }

      // Ekstraksi Skor & Menit Pertandingan Real-Time
      String homeScore = '';
      String awayScore = '';
      String scoreText = '';
      String matchMinute = '';

      final goalMatch = RegExp(r'class="[^"]*grid-match__goal[^"]*"[^>]*>\s*(\d+)\s*[-:]\s*(\d+)\s*<\/div>', caseSensitive: false).firstMatch(cardContent);
      final liveScoreEl = RegExp(r'class="[^"]*grid-match__score[^"]*"[^>]*>\s*(\d+)\s*[-:]\s*(\d+)', caseSensitive: false).firstMatch(cardContent);
      final hpuScore = RegExp(r'class="[^"]*hpu-score-home[^"]*"[^>]*>\s*(\d+)\s*<\/span>[\s\S]*?class="[^"]*hpu-score-away[^"]*"[^>]*>\s*(\d+)\s*<\/span>', caseSensitive: false).firstMatch(cardContent);

      if (hpuScore != null) {
        homeScore = hpuScore.group(1)?.trim() ?? '';
        awayScore = hpuScore.group(2)?.trim() ?? '';
        scoreText = '$homeScore - $awayScore';
      } else if (goalMatch != null) {
        homeScore = goalMatch.group(1)?.trim() ?? '';
        awayScore = goalMatch.group(2)?.trim() ?? '';
        scoreText = '$homeScore - $awayScore';
      } else if (liveScoreEl != null) {
        homeScore = liveScoreEl.group(1)?.trim() ?? '';
        awayScore = liveScoreEl.group(2)?.trim() ?? '';
        scoreText = '$homeScore - $awayScore';
      }

      final periodMatch = RegExp(r'class="[^"]*(?:grid-match__half-court|period|quarter|set-name)[^"]*"[^>]*>\s*([^<]+)\s*<', caseSensitive: false).firstMatch(cardContent);
      if (periodMatch != null) {
        matchMinute = periodMatch.group(1)?.trim() ?? '';
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

  /// Urutkan pertandingan: Live di atas (Sepak bola no 1), lalu Upcoming (Sepak bola no 1)
  void _sortMatches(List<MatchModel> list) {
    const categoryPriority = {
      '⚽ Sepak Bola': 1,
      '🏀 Bola Basket': 2,
      '🏸 Bulu Tangkis': 3,
      '🎾 Tenis': 4,
      '🏐 Bola Voli': 5,
      '🏎️ Olahraga Lainnya': 6,
    };

    list.sort((a, b) {
      int weightA = a.status == 1 ? 0 : (a.status == 0 ? 1 : 2);
      int weightB = b.status == 1 ? 0 : (b.status == 0 ? 1 : 2);
      if (weightA != weightB) return weightA.compareTo(weightB);

      int prioA = categoryPriority[a.sportCategory] ?? 99;
      int prioB = categoryPriority[b.sportCategory] ?? 99;
      if (prioA != prioB) return prioA.compareTo(prioB);

      if (a.status == 1) {
        return b.kickoffIso.compareTo(a.kickoffIso);
      } else if (a.status == 0) {
        return a.kickoffIso.compareTo(b.kickoffIso);
      } else {
        return b.kickoffIso.compareTo(a.kickoffIso);
      }
    });
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
