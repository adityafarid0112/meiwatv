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
    'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
  };

  Future<String> _fetchHtmlWithFailover(String path) async {
    String currentBase = _config.activeBaseUrl;
    try {
      final url = path.startsWith('http') ? path : '$currentBase$path';
      final res = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 8));
      
      if (res.statusCode == 200) {
        return res.body;
      } else if (res.statusCode >= 300 && res.statusCode < 400 && res.headers['location'] != null) {
        String loc = res.headers['location']!;
        if (!loc.startsWith('http')) loc = '$currentBase$loc';
        return _fetchHtmlWithFailover(loc);
      }
    } catch (e) {
      debugPrint('[Scraper] Error fetching from $currentBase: $e. Resolving new mirror...');
      currentBase = await _config.resolveActiveBaseUrl();
      final url = path.startsWith('http') ? path : '$currentBase$path';
      final res = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 8));
      return res.body;
    }
    return '';
  }

  /// Parse article list items from HTML
  List<Movie> parseMoviesFromHtml(String html) {
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

      // 5. Quality
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

      // 7. Duration
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

      final isSeries = url.contains('nontondrama') || url.contains('series');

      if (title.isNotEmpty && posterUrl.isNotEmpty) {
        list.add(Movie(
          title: title,
          slug: slug,
          url: url,
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

  /// Fetch Popular Movies
  Future<List<Movie>> fetchPopularMovies() async {
    try {
      final html = await _fetchHtmlWithFailover('/populer');
      return parseMoviesFromHtml(html);
    } catch (e) {
      debugPrint('[Scraper] Error fetching popular: $e');
      return [];
    }
  }

  /// Fetch Latest Movies
  Future<List<Movie>> fetchLatestMovies({int page = 1}) async {
    try {
      final path = page == 1 ? '/latest' : '/latest/page/$page';
      final html = await _fetchHtmlWithFailover(path);
      return parseMoviesFromHtml(html);
    } catch (e) {
      debugPrint('[Scraper] Error fetching latest: $e');
      return [];
    }
  }

  /// Fetch Movies by Genre
  Future<List<Movie>> fetchMoviesByGenre(String genreSlug, {int page = 1}) async {
    try {
      if (genreSlug.isEmpty) return fetchPopularMovies();
      final path = page == 1 ? '/genre/$genreSlug' : '/genre/$genreSlug/page/$page';
      final html = await _fetchHtmlWithFailover(path);
      return parseMoviesFromHtml(html);
    } catch (e) {
      debugPrint('[Scraper] Error fetching genre $genreSlug: $e');
      return [];
    }
  }

  /// Search Movies
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final path = '/?s=$encoded';
      final html = await _fetchHtmlWithFailover(path);
      return parseMoviesFromHtml(html);
    } catch (e) {
      debugPrint('[Scraper] Error searching $query: $e');
      return [];
    }
  }

  /// Fetch Movie Details & Streaming Embed URL
  Future<Movie> fetchMovieDetail(Movie movie) async {
    try {
      final path = movie.url.startsWith('http') ? movie.url : movie.url;
      final html = await _fetchHtmlWithFailover(path);

      // 1. Synopsis
      String synopsis = '';
      final synMatch = RegExp(r'<blockquote[^>]*>([\s\S]*?)<\/blockquote>', caseSensitive: false).firstMatch(html) ??
                       RegExp(r'<div class="content">([\s\S]*?)<\/div>', caseSensitive: false).firstMatch(html) ??
                       RegExp(r'<p class="description">([\s\S]*?)<\/p>', caseSensitive: false).firstMatch(html);
      if (synMatch != null) {
        synopsis = synMatch.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
      }

      // 2. Duration
      String duration = '';
      final durMatch = RegExp(r'Duration:\s*<\/strong>([^<]*)', caseSensitive: false).firstMatch(html) ??
                       RegExp(r'(\d+)\s*min', caseSensitive: false).firstMatch(html);
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

      // 4. Video Embed URL
      String embedUrl = '';
      final iframeMatch = RegExp(r'<iframe[^>]*id="main-player"[^>]*src="([^"]*)"', caseSensitive: false).firstMatch(html) ??
                          RegExp(r'<iframe[^>]*src="([^"]*(?:videonode|player|embed|stream)[^"]*)"', caseSensitive: false).firstMatch(html);
      if (iframeMatch != null) {
        embedUrl = iframeMatch.group(1) ?? '';
        if (embedUrl.startsWith('//')) {
          embedUrl = 'https:$embedUrl';
        }
      }

      if (embedUrl.isEmpty) {
        embedUrl = movie.url.startsWith('http') ? movie.url : '${_config.activeBaseUrl}${movie.url}';
      }

      return movie.copyWith(
        synopsis: synopsis.isNotEmpty ? synopsis : 'Film seru pilihan terbaik siap menemani waktu santai Anda dengan kualitas Full HD dan subtitle bahasa Indonesia.',
        duration: duration.isNotEmpty ? duration : (movie.duration.isNotEmpty ? movie.duration : '1 jam 45 mnt'),
        genres: genres.isNotEmpty ? genres : (movie.genres.isNotEmpty ? movie.genres : ['Action', 'Drama', 'HD']),
        embedUrl: embedUrl,
      );
    } catch (e) {
      debugPrint('[Scraper] Error fetching movie detail: $e');
      return movie.copyWith(
        embedUrl: movie.url.startsWith('http') ? movie.url : '${_config.activeBaseUrl}${movie.url}',
      );
    }
  }
}
