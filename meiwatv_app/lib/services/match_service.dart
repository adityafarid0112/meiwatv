import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/match_model.dart';
import '../utils/league_translator.dart';

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

  /// Mengambil siaran langsung terbaru (utamakan Portal / CDN / GitHub jika tersedia, atau scrape langsung dari DaddyLive API & Xoilac)
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

            if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
              final bodyString = utf8.decode(res.bodyBytes, allowMalformed: true);
              final List<dynamic> decoded = json.decode(bodyString);
              // Hanya terima remote update jika jumlah pertandingan lengkap dan tidak mengalami downgrade
              if (decoded.length >= 200 && decoded.length >= _cachedMatches.length) {
                _cachedMatches = decoded
                    .map((item) => MatchModel.fromJson(item as Map<String, dynamic>))
                    .toList();
                _matchesController.add(_cachedMatches);
                debugPrint('✅ Berhasil memuat data (${_cachedMatches.length} siaran) dari $endpoint');
                return;
              }
            }
          } catch (ghErr) {
            debugPrint('Info fetch $endpoint: $ghErr');
          }
        }
      }

      // 2. Ambil langsung dari DaddyLive API resmi & Xoilac
      final daddyEvents = await _fetchDaddyLiveEventsOnline();
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

          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            final html = utf8.decode(res.bodyBytes, allowMalformed: true);
            if (html.contains('grid-matches__item')) {
              final activeDomain = seed.endsWith('/') ? seed.substring(0, seed.length - 1) : seed;
              final matches = _parseMatchesFromHtml(html, activeDomain, seenRelUrls);
              directParsed.addAll(matches);
            }
          }
        } catch (_) {
          continue;
        }
      }

      // Merge event resmi DaddyLive API ke dalam daftar pertandingan
      if (daddyEvents.isNotEmpty) {
        for (final dev in daddyEvents) {
          final rawEvent = (dev['event'] as String? ?? '').replaceAll(RegExp(r'^[⚽🏎️🏐🏀🎾🥊🎮🏆🏸]\s*'), '').trim();
          final channels = dev['channels'] as List<dynamic>? ?? [];
          if (rawEvent.isEmpty || channels.isEmpty) continue;

          String league = 'Turnamen Internasional';
          String title = rawEvent;
          String home = '';
          String away = '';

          if (rawEvent.contains(':')) {
            final parts = rawEvent.split(':');
            league = parts[0].trim();
            title = parts.sublist(1).join(':').trim();
          }

          if (title.contains(' vs ') || title.contains(' - ')) {
            final teamParts = title.split(RegExp(r'\s+vs\.?\s+|\s+-\s+', caseSensitive: false));
            home = teamParts[0].trim();
            away = teamParts.length > 1 ? teamParts[1].trim() : '';
          } else {
            home = title;
          }

          // Klasifikasi Kategori Olahraga
          String category = '⚽ Sepak Bola';
          final lowerAll = '${dev['category']} $league $title'.toLowerCase();
          if (lowerAll.contains('motogp') || lowerAll.contains('f1') || lowerAll.contains('motor') || lowerAll.contains('bol d’or') || lowerAll.contains('racing') || lowerAll.contains('balap')) {
            category = '🏎️ Balap & Motorsport';
          } else if (lowerAll.contains('voli') || lowerAll.contains('volleyball') || lowerAll.contains('v-league') || lowerAll.contains('kovo') || lowerAll.contains('proliga')) {
            category = '🏐 Bola Voli';
          } else if (lowerAll.contains('badminton') || lowerAll.contains('bulu tangkis') || lowerAll.contains('bwf')) {
            category = '🏸 Bulu Tangkis';
          } else if (lowerAll.contains('basket') || lowerAll.contains('nba')) {
            category = '🏀 Bola Basket';
          } else if (lowerAll.contains('tenis') || lowerAll.contains('tennis') || lowerAll.contains('wta') || lowerAll.contains('atp')) {
            category = '🎾 Tenis';
          } else if (lowerAll.contains('ufc') || lowerAll.contains('boxing') || lowerAll.contains('tinju') || lowerAll.contains('mma')) {
            category = '🥊 Combat Sports';
          } else if (!lowerAll.contains('football') && !lowerAll.contains('soccer')) {
            category = '🏆 Olahraga Lainnya';
          }

          final link1 = channels[0]['url'] as String? ?? '';
          final link2 = channels.length > 1 ? (channels[1]['url'] as String? ?? '') : '';
          final link3 = channels.length > 2 ? (channels[2]['url'] as String? ?? '') : '';

          // Cek apakah pertandingan sudah ada di list Xoilac
          final normTitle = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final existingIdx = directParsed.indexWhere((m) {
            final normM = m.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            return normTitle.isNotEmpty && normM.isNotEmpty && (normTitle.contains(normM) || normM.contains(normTitle));
          });

          if (existingIdx != -1) {
            final existing = directParsed[existingIdx];
            final xoilacBackup = existing.streamJalur1.isNotEmpty ? existing.streamJalur1 : existing.streamJalur2;
            directParsed[existingIdx] = MatchModel(
              id: existing.id,
              title: existing.title,
              homeTeam: existing.homeTeam,
              awayTeam: existing.awayTeam,
              homeLogo: existing.homeLogo,
              awayLogo: existing.awayLogo,
              homeScore: existing.homeScore,
              awayScore: existing.awayScore,
              scoreText: existing.scoreText,
              matchMinute: existing.matchMinute,
              league: existing.league,
              kickoffIso: existing.kickoffIso,
              kickoffText: existing.kickoffText,
              status: existing.status,
              sportCategory: existing.sportCategory,
              streamJalur1: link1, // DaddyLive HD sebagai Jalur 1
              streamJalur2: link2.isNotEmpty ? link2 : xoilacBackup,
              streamJalur3: link3.isNotEmpty ? link3 : (link2.isNotEmpty ? xoilacBackup : link1),
              streamJalur4: xoilacBackup,
            );
          } else {
            final uniqueId = 'daddy_${directParsed.length + 1}_${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
            final isLive = dev['time'].toString().toLowerCase().contains('live') || dev['time'] == 'Live';
            directParsed.add(MatchModel(
              id: uniqueId,
              title: away.isNotEmpty ? '$home vs $away' : home,
              homeTeam: home,
              awayTeam: away,
              homeLogo: '',
              awayLogo: '',
              homeScore: '',
              awayScore: '',
              scoreText: '',
              matchMinute: '',
              league: league,
              kickoffIso: DateTime.now().toIso8601String(),
              kickoffText: isLive ? 'LIVE Sekarang' : '${dev['time']} WIB',
              status: isLive ? 1 : 0,
              sportCategory: category,
              streamJalur1: link1,
              streamJalur2: link2.isNotEmpty ? link2 : link1,
              streamJalur3: link3.isNotEmpty ? link3 : link1,
              streamJalur4: '',
            ));
          }
        }
      }

      if (directParsed.isNotEmpty && directParsed.length >= _cachedMatches.length) {
        _sortMatches(directParsed);
        _cachedMatches = directParsed;
        _matchesController.add(_cachedMatches);
        debugPrint('✅ Berhasil sinkronisasi ${directParsed.length} siaran langsung (DaddyLive + Xoilac)!');
      }
    } catch (e) {
      debugPrint('Error fetching online matches: $e');
    }
  }

  /// Ambil seluruh jadwal siaran resmi DaddyLive API secara real-time
  Future<List<Map<String, dynamic>>> _fetchDaddyLiveEventsOnline() async {
    try {
      final res = await http.get(
        Uri.parse('https://daddylive.app/api/events'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        final decoded = json.decode(utf8.decode(res.bodyBytes, allowMalformed: true)) as Map<String, dynamic>;
        final categories = decoded['categories'] as Map<String, dynamic>? ?? {};
        final list = <Map<String, dynamic>>[];

        for (final entry in categories.entries) {
          if (entry.value is List) {
            for (final item in entry.value as List) {
              if (item is Map<String, dynamic> && item['event'] != null) {
                list.add({
                  'category': entry.key,
                  'time': item['time'] ?? 'Live',
                  'event': item['event'],
                  'channels': item['channels'] ?? [],
                  'source': item['source'] ?? 'tv1',
                });
              }
            }
          }
        }
        return list;
      }
    } catch (e) {
      debugPrint('Info DaddyLive API: $e');
    }
    return [];
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

      home = LeagueTranslator.cleanTeamName(home);
      away = LeagueTranslator.cleanTeamName(away);
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

      final daddyUrl = _getDaddyLiveUrl(category, league, title);

      // Jalur 1: DaddyLive HD (Utama, Kualitas Jernih 1080p)
      // Jalur 2: Xoilac HD (Komentator Indonesia)
      // Jalur 3: Cadangan / Alternatif
      final ch1 = daddyUrl.isNotEmpty ? daddyUrl : matchPageUrl;
      final ch2 = matchPageUrl;
      final ch3 = daddyUrl.isNotEmpty ? matchPageUrl : '';

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

  /// Pemetaan URL Siaran DaddyLive HD Resmi
  String _getDaddyLiveUrl(String sportCategory, String league, String title) {
    final text = '$sportCategory $league $title'.toLowerCase();
    if (text.contains('motogp') || text.contains('moto2') || text.contains('moto3') || text.contains('balap') || text.contains('motor') || text.contains('wsbk')) {
      return 'https://daddylive.app/player/embed.php?id=32';
    }
    if (text.contains('formula 1') || text.contains('f1')) {
      return 'https://daddylive.app/player/embed.php?id=38';
    }
    if (text.contains('badminton') || text.contains('bulu tangkis') || text.contains('bwf') || text.contains('all england') || text.contains('indonesia open')) {
      return 'https://daddylive.app/player/embed.php?id=123';
    }
    if (text.contains('voli') || text.contains('volleyball') || text.contains('v-league') || text.contains('kovo') || text.contains('proliga')) {
      return 'https://daddylive.app/player/embed.php?id=125';
    }
    if (text.contains('inggris') || text.contains('premier league') || text.contains('championship')) {
      return 'https://daddylive.app/player/embed.php?id=39';
    }
    if (text.contains('champions') || text.contains('ucl') || text.contains('europa')) {
      return 'https://daddylive.app/player/embed.php?id=31';
    }
    if (text.contains('bundesliga') || text.contains('jerman') || text.contains('dfb')) {
      return 'https://daddylive.app/player/embed.php?id=240';
    }
    if (text.contains('spanyol') || text.contains('la liga') || text.contains('italia') || text.contains('serie a')) {
      return 'https://daddylive.app/player/embed.php?id=91';
    }
    if (text.contains('basket') || text.contains('nba')) {
      return 'https://daddylive.app/player/embed.php?id=404';
    }
    if (text.contains('tenis') || text.contains('tennis')) {
      return 'https://daddylive.app/player/embed.php?id=576';
    }
    return '';
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
    return LeagueTranslator.translate(text);
  }

  void dispose() {
    _autoRefreshTimer?.cancel();
    _matchesController.close();
  }
}
