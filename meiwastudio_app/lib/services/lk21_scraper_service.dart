import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import 'remote_config_service.dart';

class LK21ScraperService {
  static final LK21ScraperService _instance = LK21ScraperService._internal();
  factory LK21ScraperService() => _instance;
  LK21ScraperService._internal();

  final RemoteConfigService _config = RemoteConfigService();

  Map<String, String> get _headers => {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Android TV Build/STTE.220623.001) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
  };

  final Map<String, String> _htmlCache = {};

  String _normalizeUrl(String path, {String? defaultHost}) {
    if (path.startsWith('http')) return path;
    final host = defaultHost ?? (path.contains('series') || path.contains('drama') || path.contains('episode')
        ? _config.dramaBaseUrl
        : _config.activeBaseUrl);
    final base = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$base$cleanPath';
  }

  Future<String> _fetchHtmlWithFailover(String path, {String? defaultHost}) async {
    final cacheKey = '$defaultHost|$path';
    if (_htmlCache.containsKey(cacheKey) && _htmlCache[cacheKey]!.isNotEmpty) {
      return _htmlCache[cacheKey]!;
    }

    String fullUrl = _normalizeUrl(path, defaultHost: defaultHost);

    // 1. Fast Direct Request (Timeout 3.5s)
    try {
      final res = await http.get(Uri.parse(fullUrl), headers: _headers).timeout(const Duration(milliseconds: 3500));
      if (res.statusCode == 200 && res.body.isNotEmpty && (res.body.contains('<article') || res.body.contains('<html') || res.body.contains('<!DOCTYPE'))) {
        _htmlCache[cacheKey] = res.body;
        return res.body;
      } else if (res.statusCode >= 300 && res.statusCode < 400 && res.headers['location'] != null) {
        return _fetchHtmlWithFailover(res.headers['location']!, defaultHost: defaultHost);
      }
    } catch (e) {
      debugPrint('[Scraper] Direct fetch failed for $fullUrl ($e), switching to fast proxy relays...');
    }

    // 2. High-Speed Proxy Relays (Bypasses Telkomsel / Indihome / XL / Tri blocks)
    final proxyUrls = [
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(fullUrl)}',
      'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(fullUrl)}',
      'https://corsproxy.io/?url=${Uri.encodeComponent(fullUrl)}',
    ];

    for (final pUrl in proxyUrls) {
      try {
        final res = await http.get(Uri.parse(pUrl), headers: _headers).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && res.body.isNotEmpty && (res.body.contains('<article') || res.body.contains('<html') || res.body.contains('<!DOCTYPE'))) {
          debugPrint('[Scraper] Successfully fetched data via proxy relay: $pUrl');
          _htmlCache[cacheKey] = res.body;
          return res.body;
        }
      } catch (e) {
        debugPrint('[Scraper] Proxy relay failed: $pUrl ($e)');
      }
    }

    // 3. Alternative Mirror Hosts
    for (final src in _config.sources) {
      if (src.baseUrl == _config.activeBaseUrl) continue;
      final altUrl = _normalizeUrl(path, defaultHost: src.baseUrl);
      try {
        final res = await http.get(Uri.parse(altUrl), headers: _headers).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          _config.switchBaseUrl(src.baseUrl);
          _htmlCache[cacheKey] = res.body;
          return res.body;
        }
      } catch (_) {}
    }

    return '';
  }

  /// Parse article list items from LK21 / NontonDrama HTML
  List<Movie> parseMoviesFromHtml(String html, {String? defaultHost}) {
    final List<Movie> list = [];
    final articleRegex = RegExp(r'<article[^>]*>([\s\S]*?)<\/article>', caseSensitive: false);
    final matches = articleRegex.allMatches(html);

    for (final m in matches) {
      final block = m.group(1) ?? '';

      // 1. URL & Slug
      String url = '';
      String slug = '';
      final urlMatch = RegExp(r'href="([^"]+)"', caseSensitive: false).firstMatch(block);
      if (urlMatch != null) {
        url = urlMatch.group(1) ?? '';
        slug = url.replaceAll(RegExp(r'^https?:\/\/[^\/]+'), '').replaceAll('/', '').trim();
      }

      // 2. Title
      String title = '';
      final titleMatch = RegExp(r'<h\d[^>]*class="[^"]*poster-title[^"]*"[^>]*>([^<]+)<\/h\d>', caseSensitive: false).firstMatch(block) ??
                         RegExp(r'itemprop="name"[^>]*>([^<]+)<\/h\d>', caseSensitive: false).firstMatch(block) ??
                         RegExp(r'alt="([^"]+)"', caseSensitive: false).firstMatch(block) ??
                         RegExp(r'title="([^"]+)"', caseSensitive: false).firstMatch(block);
      if (titleMatch != null) {
        title = titleMatch.group(1)?.trim() ?? '';
        title = title.replaceAll(RegExp(r'^Nonton\s+(?:film|series|movie)?\s*', caseSensitive: false), '')
                     .replaceAll(RegExp(r'\s*streaming\s+download\s+movie\s*$', caseSensitive: false), '')
                     .replaceAll(RegExp(r'\s*streaming\s+gratis\s*$', caseSensitive: false), '')
                     .trim();
      }

      // 3. Poster Image
      String posterUrl = '';
      final imgMatch = RegExp(r'<img[^>]*src="([^"]+)"', caseSensitive: false).firstMatch(block) ??
                       RegExp(r'<source[^>]*srcset="([^"]+)"', caseSensitive: false).firstMatch(block);
      if (imgMatch != null) {
        posterUrl = imgMatch.group(1) ?? '';
        if (posterUrl.contains(' ')) posterUrl = posterUrl.split(' ').first;
        if (posterUrl.startsWith('//')) posterUrl = 'https:$posterUrl';
      }

      // 4. Rating
      String rating = '';
      final ratingMatch = RegExp(r'itemprop="ratingValue">([^<]+)<\/span>', caseSensitive: false).firstMatch(block) ??
                          RegExp(r'class="rating"[^>]*>[\s\S]*?(\d+\.\d+)[\s\S]*?<\/span>', caseSensitive: false).firstMatch(block);
      if (ratingMatch != null) {
        rating = ratingMatch.group(1)?.trim() ?? '';
      }

      // 5. Quality / Status
      String quality = 'HD';
      final qualMatch = RegExp(r'class="label[^"]*">([^<]+)<\/span>', caseSensitive: false).firstMatch(block);
      if (qualMatch != null) {
        quality = qualMatch.group(1)?.trim() ?? 'HD';
      }

      // 6. Year
      String year = '2026';
      final yearMatch = RegExp(r'class="year"[^>]*>([^<]+)<\/span>', caseSensitive: false).firstMatch(block);
      if (yearMatch != null) {
        year = yearMatch.group(1)?.trim() ?? '2026';
      }

      // 7. Duration / Eps
      String duration = '';
      final durMatch = RegExp(r'class="duration"[^>]*>([^<]+)<\/span>', caseSensitive: false).firstMatch(block);
      if (durMatch != null) {
        duration = durMatch.group(1)?.trim() ?? '';
      }

      // 8. Genres
      final List<String> genres = [];
      final genreMeta = RegExp(r'itemprop="genre"\s+content="([^"]+)"', caseSensitive: false).firstMatch(block) ??
                        RegExp(r'<div class="genre">\s*([^<]+)\s*<\/div>', caseSensitive: false).firstMatch(block);
      if (genreMeta != null) {
        final raw = genreMeta.group(1) ?? '';
        genres.addAll(raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
      }

      final isSeries = url.contains('nontondrama') || url.contains('series') || defaultHost?.contains('nontondrama') == true;

      if (title.isNotEmpty && posterUrl.isNotEmpty) {
        list.add(Movie(
          title: title,
          slug: slug,
          url: url.startsWith('http') ? url : _normalizeUrl(url, defaultHost: defaultHost),
          posterUrl: posterUrl,
          rating: rating.isNotEmpty ? rating : '7.8',
          quality: quality,
          year: year,
          duration: duration,
          genres: genres,
          isSeries: isSeries,
        ));
      }
    }

    return list;
  }

  /// 1. Film Terbaru (/latest)
  Future<List<Movie>> fetchFilmTerbaru({int page = 1}) async {
    try {
      final path = page == 1 ? '/latest' : '/latest/page/$page';
      final html = await _fetchHtmlWithFailover(path, defaultHost: _config.activeBaseUrl);
      return parseMoviesFromHtml(html, defaultHost: _config.activeBaseUrl);
    } catch (e) {
      debugPrint('[Scraper] Error fetching Film Terbaru: $e');
      return [];
    }
  }

  /// 2. Series Unggulan (/top-series-today)
  Future<List<Movie>> fetchSeriesUnggulan({int page = 1}) async {
    try {
      final path = page == 1 ? '/top-series-today' : '/top-series-today/page/$page';
      // Try NontonDrama first for series
      String html = await _fetchHtmlWithFailover(path, defaultHost: _config.dramaBaseUrl);
      if (html.isEmpty || !html.contains('<article')) {
        html = await _fetchHtmlWithFailover(path, defaultHost: _config.activeBaseUrl);
      }
      return parseMoviesFromHtml(html, defaultHost: _config.dramaBaseUrl);
    } catch (e) {
      debugPrint('[Scraper] Error fetching Series Unggulan: $e');
      return [];
    }
  }

  /// 3. Series Update (/latest-series)
  Future<List<Movie>> fetchSeriesUpdate({int page = 1}) async {
    try {
      final path = page == 1 ? '/latest-series' : '/latest-series/page/$page';
      String html = await _fetchHtmlWithFailover(path, defaultHost: _config.dramaBaseUrl);
      if (html.isEmpty || !html.contains('<article')) {
        html = await _fetchHtmlWithFailover(path, defaultHost: _config.activeBaseUrl);
      }
      return parseMoviesFromHtml(html, defaultHost: _config.dramaBaseUrl);
    } catch (e) {
      debugPrint('[Scraper] Error fetching Series Update: $e');
      return [];
    }
  }

  /// 4. Top Bulan Ini (/populer)
  Future<List<Movie>> fetchTopBulanIni({int page = 1}) async {
    try {
      final path = page == 1 ? '/populer' : '/populer/page/$page';
      final html = await _fetchHtmlWithFailover(path, defaultHost: _config.activeBaseUrl);
      return parseMoviesFromHtml(html, defaultHost: _config.activeBaseUrl);
    } catch (e) {
      debugPrint('[Scraper] Error fetching Top Bulan Ini: $e');
      return [];
    }
  }

  /// Alias for backward compatibility
  Future<List<Movie>> fetchPopularMovies({int page = 1}) => fetchTopBulanIni(page: page);

  /// 5. Top Rating (/rating)
  Future<List<Movie>> fetchTopRating({int page = 1}) async {
    try {
      final path = page == 1 ? '/rating' : '/rating/page/$page';
      final html = await _fetchHtmlWithFailover(path, defaultHost: _config.activeBaseUrl);
      return parseMoviesFromHtml(html, defaultHost: _config.activeBaseUrl);
    } catch (e) {
      debugPrint('[Scraper] Error fetching Top Rating: $e');
      return [];
    }
  }

  /// 5. Rekomendasi Untukmu (/rating or /rekomendasi)
  Future<List<Movie>> fetchRekomendasi({int page = 1}) async {
    try {
      final path = page == 1 ? '/rating' : '/rating/page/$page';
      final html = await _fetchHtmlWithFailover(path, defaultHost: _config.activeBaseUrl);
      return parseMoviesFromHtml(html, defaultHost: _config.activeBaseUrl);
    } catch (e) {
      debugPrint('[Scraper] Error fetching Rekomendasi: $e');
      return [];
    }
  }

  /// 6. Fetch Movies by Category / Genre
  Future<List<Movie>> fetchMoviesByGenre(String genreSlug, {int page = 1}) async {
    try {
      if (genreSlug.isEmpty) return fetchFilmTerbaru(page: page);
      
      String slug = genreSlug;
      if (slug == 'keluarga') slug = 'family';
      
      final path = page == 1 ? '/genre/$slug' : '/genre/$slug/page/$page';
      final isDrama = genreSlug == 'drama' || genreSlug == 'drakor' || genreSlug == 'drama-korea';
      final defaultHost = isDrama ? _config.dramaBaseUrl : _config.activeBaseUrl;
      
      String html = await _fetchHtmlWithFailover(path, defaultHost: defaultHost);
      if (html.isEmpty || !html.contains('<article')) {
        final altHost = isDrama ? _config.activeBaseUrl : _config.dramaBaseUrl;
        html = await _fetchHtmlWithFailover(path, defaultHost: altHost);
      }
      return parseMoviesFromHtml(html, defaultHost: defaultHost);
    } catch (e) {
      debugPrint('[Scraper] Error fetching genre $genreSlug: $e');
      return [];
    }
  }

  /// 7. Fetch Movies by Country (Korea, Thailand, India, dll)
  Future<List<Movie>> fetchMoviesByCountry(String countrySlug, {int page = 1}) async {
    try {
      String slug = countrySlug.toLowerCase();
      if (slug == 'korea') slug = 'south-korea';

      final path = page == 1 ? '/country/$slug' : '/country/$slug/page/$page';
      String html = await _fetchHtmlWithFailover(path, defaultHost: _config.activeBaseUrl);
      
      // Fallback to /country/korea if south-korea was empty or try dramaBaseUrl
      if (html.isEmpty || !html.contains('<article')) {
        html = await _fetchHtmlWithFailover(page == 1 ? '/country/$countrySlug' : '/country/$countrySlug/page/$page', defaultHost: _config.activeBaseUrl);
      }
      if (html.isEmpty || !html.contains('<article')) {
        html = await _fetchHtmlWithFailover(path, defaultHost: _config.dramaBaseUrl);
      }
      return parseMoviesFromHtml(html, defaultHost: _config.activeBaseUrl);
    } catch (e) {
      debugPrint('[Scraper] Error fetching country $countrySlug: $e');
      return [];
    }
  }

  /// 8. Generic Endpoint Fetcher for Category List View
  Future<List<Movie>> fetchEndpoint(String endpoint, {int page = 1}) async {
    try {
      String path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      if (page > 1) {
        if (path.contains('?')) {
          path = '$path&page=$page';
        } else {
          path = '$endpoint/page/$page';
        }
      }
      final isDrama = endpoint.contains('series') || endpoint.contains('drama') || endpoint.contains('drakor');
      final defaultHost = isDrama ? _config.dramaBaseUrl : _config.activeBaseUrl;
      String html = await _fetchHtmlWithFailover(path, defaultHost: defaultHost);
      if (html.isEmpty || !html.contains('<article')) {
        final altHost = isDrama ? _config.activeBaseUrl : _config.dramaBaseUrl;
        html = await _fetchHtmlWithFailover(path, defaultHost: altHost);
      }
      return parseMoviesFromHtml(html, defaultHost: defaultHost);
    } catch (e) {
      debugPrint('[Scraper] Error fetching endpoint $endpoint: $e');
      return [];
    }
  }

  /// Search Movies & Series across all sources with clean filtering
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final encoded = Uri.encodeComponent(cleanQuery);
      final path = page == 1 ? '/?s=$encoded' : '/page/$page/?s=$encoded';

      // Concurrently query LK21 (Movies) and NontonDrama (Series/Drakor)
      final results = await Future.wait([
        _fetchAndParseSearch(path, _config.activeBaseUrl, cleanQuery),
        _fetchAndParseSearch(path, _config.dramaBaseUrl, cleanQuery),
      ]);

      final all = <Movie>[];
      final seenSlugs = <String>{};

      for (final list in results) {
        for (final m in list) {
          if (seenSlugs.add(m.slug)) {
            all.add(m);
          }
        }
      }

      // Rank results: exact match first, then startsWith, then contains
      final qLower = cleanQuery.toLowerCase();
      all.sort((a, b) {
        final aTitle = a.title.toLowerCase();
        final bTitle = b.title.toLowerCase();
        if (aTitle == qLower && bTitle != qLower) return -1;
        if (bTitle == qLower && aTitle != qLower) return 1;
        if (aTitle.startsWith(qLower) && !bTitle.startsWith(qLower)) return -1;
        if (bTitle.startsWith(qLower) && !aTitle.startsWith(qLower)) return 1;
        return 0;
      });

      return all;
    } catch (e) {
      debugPrint('[Scraper] Error searching $cleanQuery: $e');
      return [];
    }
  }

  Future<List<Movie>> _fetchAndParseSearch(String path, String defaultHost, String query) async {
    try {
      String html = await _fetchHtmlWithFailover(path, defaultHost: defaultHost);
      if (html.isEmpty) return [];

      // Strip out sidebars, widgets, headers, footers so sidebar movies don't pollute search
      html = html
          .replaceAll(RegExp(r'<aside[\s\S]*?<\/aside>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<footer[\s\S]*?<\/footer>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<div[^>]*class="[^"]*(?:sidebar|widget|popular-posts)[^"]*"[\s\S]*?<\/div>', caseSensitive: false), '');

      final parsed = parseMoviesFromHtml(html, defaultHost: defaultHost);

      // Filter to ensure relevance to the search query
      final qWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
      if (qWords.isEmpty) {
        return parsed;
      }

      final filtered = parsed.where((m) {
        final titleLower = m.title.toLowerCase();
        final slugLower = m.slug.toLowerCase();
        return qWords.any((word) => titleLower.contains(word) || slugLower.contains(word));
      }).toList();

      return filtered.isNotEmpty ? filtered : parsed;
    } catch (e) {
      debugPrint('[Scraper] Error in _fetchAndParseSearch: $e');
      return [];
    }
  }

  /// Extract available Video Servers (P2P 480p, TURBOVIP 720p HD, HYDRAX 1080p FHD, CAST, etc.)
  List<VideoServer> extractVideoServers(String html, {String fallbackUrl = ''}) {
    final List<VideoServer> servers = [];
    final Set<String> seenUrls = {};

    // 1. Check data-url and data-server on player links
    final serverMatches = RegExp(
      r'<(?:a|button|li)[^>]*(?:data-url="([^"]+)"|href="([^"]+)")(?:\s+class="[^"]*")?\s+data-server="([^"]+)"[^>]*>([\s\S]*?)<\/(?:a|button|li)>',
      caseSensitive: false,
    ).allMatches(html);

    for (final sm in serverMatches) {
      String url = sm.group(1) ?? sm.group(2) ?? '';
      final serverKey = (sm.group(3) ?? '').trim().toLowerCase();
      final label = (sm.group(4) ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim();

      if (url.startsWith('//')) url = 'https:$url';

      if (url.isNotEmpty && url.contains('http') && seenUrls.add(url)) {
        String displayName = label.isNotEmpty ? label.toUpperCase() : serverKey.toUpperCase();
        String quality = '720p HD';

        if (serverKey == 'hydrax') {
          displayName = 'HYDRAX • Multi-Kualitas (480p - 1080p)';
          quality = '480p - 1080p FHD';
        } else if (serverKey == 'turbovip') {
          displayName = 'TURBOVIP • Cadangan (720p)';
          quality = '720p HD';
        } else if (serverKey == 'p2p') {
          displayName = 'P2P • Cadangan Cepat (480p)';
          quality = '480p SD';
        } else if (serverKey == 'cast') {
          displayName = 'CAST • Mirror HD';
          quality = 'Mirror HD';
        }

        servers.add(VideoServer(
          name: displayName,
          serverKey: serverKey,
          url: url,
          qualityLabel: quality,
        ));
      }
    }

    // 2. Also check player-list if any were missed
    if (servers.isEmpty) {
      final listMatches = RegExp(
        r'<a[^>]*data-url="([^"]*(?:videonode|playcdn|player|embed|stream)[^"]*)"[^>]*>([\s\S]*?)<\/a>',
        caseSensitive: false,
      ).allMatches(html);

      for (final lm in listMatches) {
        String url = lm.group(1) ?? '';
        final text = lm.group(2)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? 'Server';
        if (url.startsWith('//')) url = 'https:$url';
        if (url.isNotEmpty && seenUrls.add(url)) {
          servers.add(VideoServer(
            name: text.isNotEmpty ? text.toUpperCase() : 'Server ${servers.length + 1}',
            serverKey: 'server_${servers.length + 1}',
            url: url,
            qualityLabel: text.contains('1080') ? '1080p FHD' : (text.contains('720') ? '720p HD' : 'HD'),
          ));
        }
      }
    }

    // 3. Fallback to main-player iframe if available
    if (servers.isEmpty && fallbackUrl.isNotEmpty && seenUrls.add(fallbackUrl)) {
      servers.add(VideoServer(
        name: 'Server Utama (Auto)',
        serverKey: 'default',
        url: fallbackUrl,
        qualityLabel: 'HD Auto',
      ));
    }

    // Order: HYDRAX (1080p FHD) -> TURBOVIP (720p HD) -> P2P (480p) -> CAST
    servers.sort((a, b) {
      int score(VideoServer s) {
        if (s.serverKey == 'hydrax') return 1;
        if (s.serverKey == 'turbovip') return 2;
        if (s.serverKey == 'p2p') return 3;
        if (s.serverKey == 'cast') return 4;
        return 5;
      }
      return score(a).compareTo(score(b));
    });

    return servers;
  }

  /// Resolves the actual direct embed URL from videonode.de (e.g. emturbovid, abyssplayer, playcdn)
  Future<String> resolveDirectEmbedUrl(String serverKey, String url) async {
    try {
      // Hydrax must use videonode.de as its authorized parent frame to avoid abyss.to redirect
      if (serverKey == 'hydrax') {
        return url;
      }

      if (!url.contains('videonode.de/iframe3/')) {
        return url;
      }

      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length >= 3) {
        final host = segments[segments.length - 2];
        final id = segments.last;

        final apiUri = Uri.parse('https://videonode.de/api.php');
        final res = await http.post(
          apiUri,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Android TV Build/STTE.220623.001) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': url,
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-Requested-With': 'XMLHttpRequest',
          },
          body: 'host=$host&id=$id',
        ).timeout(const Duration(milliseconds: 4000));

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data['embedUrl'] != null && data['embedUrl'].toString().isNotEmpty) {
            String directUrl = data['embedUrl'].toString();
            if (directUrl.startsWith('//')) directUrl = 'https:$directUrl';
            debugPrint('[Scraper] Resolved $serverKey ($host) direct stream URL: $directUrl');
            return directUrl;
          }
        }
      }
    } catch (e) {
      debugPrint('[Scraper] Error resolving direct embed URL for $url: $e');
    }
    return url;
  }

  /// Fetch Direct Episode Embed URL and Servers
  Future<SeriesEpisode> fetchEpisodeDetails(SeriesEpisode episode) async {
    try {
      final fullUrl = episode.url.startsWith('http')
          ? episode.url
          : _normalizeUrl(episode.url, defaultHost: _config.dramaBaseUrl);
      final html = await _fetchHtmlWithFailover(fullUrl, defaultHost: _config.dramaBaseUrl);

      String embedUrl = '';
      final iframeMatch = RegExp(r'<iframe[^>]*id="main-player"[^>]*src="([^"]*)"', caseSensitive: false).firstMatch(html) ??
                          RegExp(r'<iframe[^>]*src="([^"]*(?:videonode|player|embed|stream|p2p|playcdn)[^"]*)"', caseSensitive: false).firstMatch(html);
      if (iframeMatch != null) {
        embedUrl = iframeMatch.group(1) ?? '';
        if (embedUrl.startsWith('//')) embedUrl = 'https:$embedUrl';
      }

      final rawServers = extractVideoServers(html, fallbackUrl: embedUrl);
      final servers = await Future.wait(rawServers.map((s) async {
        final directUrl = await resolveDirectEmbedUrl(s.serverKey, s.url);
        return VideoServer(
          name: s.name,
          serverKey: s.serverKey,
          url: directUrl,
          qualityLabel: s.qualityLabel,
        );
      }));

      if (embedUrl.isEmpty && servers.isNotEmpty) {
        embedUrl = servers.first.url;
      }

      return episode.copyWith(
        embedUrl: embedUrl.isNotEmpty ? embedUrl : fullUrl,
        servers: servers,
      );
    } catch (e) {
      debugPrint('[Scraper] Error fetching episode details: $e');
      return episode;
    }
  }

  /// Fetch Direct Episode Embed URL (Backward compatibility)
  Future<String> fetchEpisodeEmbedUrl(String episodeUrl) async {
    try {
      final fullUrl = episodeUrl.startsWith('http')
          ? episodeUrl
          : _normalizeUrl(episodeUrl, defaultHost: _config.dramaBaseUrl);
      final html = await _fetchHtmlWithFailover(fullUrl, defaultHost: _config.dramaBaseUrl);

      final iframeMatch = RegExp(r'<iframe[^>]*id="main-player"[^>]*src="([^"]*)"', caseSensitive: false).firstMatch(html) ??
                          RegExp(r'<iframe[^>]*src="([^"]*(?:videonode|player|embed|stream|p2p|playcdn)[^"]*)"', caseSensitive: false).firstMatch(html);
      if (iframeMatch != null) {
        String embedUrl = iframeMatch.group(1) ?? '';
        if (embedUrl.startsWith('//')) embedUrl = 'https:$embedUrl';
        return embedUrl;
      }
      return fullUrl;
    } catch (e) {
      debugPrint('[Scraper] Error fetching episode embed: $e');
      return episodeUrl;
    }
  }

  /// Fetch Movie / Drama Details & Streaming Embed URL + Episodes List + Servers
  Future<Movie> fetchMovieDetail(Movie movie) async {
    try {
      final isDrama = movie.url.contains('nontondrama') || movie.url.contains('series') || movie.isSeries;
      final defaultHost = isDrama ? _config.dramaBaseUrl : _config.activeBaseUrl;
      final fullUrl = movie.url.startsWith('http') ? movie.url : _normalizeUrl(movie.url, defaultHost: defaultHost);
      final html = await _fetchHtmlWithFailover(fullUrl, defaultHost: defaultHost);

      // 1. Synopsis
      String synopsis = '';
      final synMatch = RegExp(r'<blockquote[^>]*>([\s\S]*?)<\/blockquote>', caseSensitive: false).firstMatch(html) ??
                       RegExp(r'<div class="content">([\s\S]*?)<\/div>', caseSensitive: false).firstMatch(html) ??
                       RegExp(r'<p class="description">([\s\S]*?)<\/p>', caseSensitive: false).firstMatch(html);
      if (synMatch != null) {
        synopsis = synMatch.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
      }

      // 2. Duration / Status
      String duration = '';
      final durMatch = RegExp(r'Duration:\s*<\/strong>([^<]*)', caseSensitive: false).firstMatch(html) ??
                       RegExp(r'(\d+)\s*min', caseSensitive: false).firstMatch(html) ??
                       RegExp(r'class="duration"[^>]*>([^<]+)<\/span>', caseSensitive: false).firstMatch(html);
      if (durMatch != null) {
        duration = durMatch.group(1)?.trim() ?? '';
      }

      // 3. Genres
      final List<String> genres = [];
      final genreMatches = RegExp(r'href="[^"]*\/genre\/([^"]*)"[^>]*>([^<]*)<\/a>', caseSensitive: false).allMatches(html);
      for (final gm in genreMatches) {
        final g = gm.group(2)?.trim();
        if (g != null && g.isNotEmpty && !genres.contains(g)) {
          genres.add(g);
        }
      }

      // 4. Series Episodes Parser
      final List<SeriesEpisode> episodes = [];
      final episodeJsonMatch = RegExp(r'\{"\d+":\[\{"s":\d+,"episode_no":[\s\S]*?\}\]\}').firstMatch(html);
      if (episodeJsonMatch != null) {
        try {
          final Map<String, dynamic> seasonsMap = json.decode(episodeJsonMatch.group(0)!);
          for (final seasonKey in seasonsMap.keys) {
            final epList = seasonsMap[seasonKey];
            if (epList is List) {
              for (final ep in epList) {
                if (ep is Map<String, dynamic>) {
                  episodes.add(SeriesEpisode.fromJson(ep, baseUrl: defaultHost));
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[Scraper] Error parsing episode JSON: $e');
        }
      }

      // Fallback: Check HTML links for episodes
      if (episodes.isEmpty && isDrama) {
        final epLinkMatches = RegExp(r'<a[^>]*href="([^"]*episode-\d+[^"]*)"[^>]*>([\s\S]*?)<\/a>', caseSensitive: false).allMatches(html);
        int epCount = 1;
        for (final el in epLinkMatches) {
          final epHref = el.group(1) ?? '';
          final epText = el.group(2)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? 'Episode $epCount';
          final epNo = int.tryParse(RegExp(r'episode-(\d+)').firstMatch(epHref)?.group(1) ?? '') ?? epCount;
          episodes.add(SeriesEpisode(
            season: 1,
            episodeNo: epNo,
            title: epText.startsWith('Episode') ? epText : 'Episode $epNo',
            slug: epHref,
            url: epHref.startsWith('http') ? epHref : _normalizeUrl(epHref, defaultHost: defaultHost),
          ));
          epCount++;
        }
      }

      // Sort episodes by Season and Episode Number
      episodes.sort((a, b) {
        if (a.season != b.season) return a.season.compareTo(b.season);
        return a.episodeNo.compareTo(b.episodeNo);
      });

      // 5. Video Embed URL & Server Extraction
      String embedUrl = '';
      final iframeMatch = RegExp(r'<iframe[^>]*id="main-player"[^>]*src="([^"]*)"', caseSensitive: false).firstMatch(html) ??
                          RegExp(r'<iframe[^>]*src="([^"]*(?:videonode|player|embed|stream|p2p|playcdn)[^"]*)"', caseSensitive: false).firstMatch(html);
      if (iframeMatch != null) {
        embedUrl = iframeMatch.group(1) ?? '';
        if (embedUrl.startsWith('//')) {
          embedUrl = 'https:$embedUrl';
        }
      }

      final rawServers = extractVideoServers(html, fallbackUrl: embedUrl);
      final servers = await Future.wait(rawServers.map((s) async {
        final directUrl = await resolveDirectEmbedUrl(s.serverKey, s.url);
        return VideoServer(
          name: s.name,
          serverKey: s.serverKey,
          url: directUrl,
          qualityLabel: s.qualityLabel,
        );
      }));

      // If embedUrl empty, use first server URL
      if (embedUrl.isEmpty && servers.isNotEmpty) {
        embedUrl = servers.first.url;
      }

      // Fallback for player list options
      if (embedUrl.isEmpty) {
        final p2pMatch = RegExp(r'href="([^"]*(?:videonode\.de\/iframe3)[^"]*)"', caseSensitive: false).firstMatch(html) ??
                         RegExp(r'data-url="([^"]*(?:videonode\.de\/iframe3)[^"]*)"', caseSensitive: false).firstMatch(html);
        if (p2pMatch != null) {
          embedUrl = p2pMatch.group(1) ?? '';
          if (embedUrl.startsWith('//')) embedUrl = 'https:$embedUrl';
        }
      }

      // If series and embedUrl still empty, get Episode 1 embed
      if (embedUrl.isEmpty && episodes.isNotEmpty) {
        final epDetail = await fetchEpisodeDetails(episodes.first);
        embedUrl = epDetail.embedUrl;
      }

      if (embedUrl.isEmpty) {
        embedUrl = fullUrl;
      }

      return movie.copyWith(
        synopsis: synopsis.isNotEmpty ? synopsis : 'Film & serial drama pilihan terbaik siap menemani waktu santai Anda dengan kualitas Full HD dan subtitle bahasa Indonesia.',
        duration: duration.isNotEmpty ? duration : (movie.duration.isNotEmpty ? movie.duration : (episodes.isNotEmpty ? '${episodes.length} Episode' : '1 jam 45 mnt')),
        genres: genres.isNotEmpty ? genres : (movie.genres.isNotEmpty ? movie.genres : ['Action', 'Drama', 'HD']),
        embedUrl: embedUrl,
        isSeries: isDrama || episodes.isNotEmpty,
        episodes: episodes,
        servers: servers,
      );
    } catch (e) {
      debugPrint('[Scraper] Error fetching movie detail: $e');
      return movie.copyWith(
        embedUrl: movie.url.startsWith('http') ? movie.url : _normalizeUrl(movie.url),
      );
    }
  }
}
