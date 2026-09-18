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
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
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
      
      // Title and Link
      String title = '';
      String url = '';
      String slug = '';

      final titleMatch = RegExp(r'<h\d[^>]*><a[^>]*href="([^"]*)"[^>]*>([^<]*)<\/a>', caseSensitive: false).firstMatch(block) ??
                         RegExp(r'<a[^>]*href="([^"]*)"[^>]*title="([^"]*)"', caseSensitive: false).firstMatch(block);
      if (titleMatch != null) {
        url = titleMatch.group(1) ?? '';
        title = titleMatch.group(2) ?? '';
        // Clean title prefixes like "Nonton series", "Nonton film", etc.
        title = title.replaceAll(RegExp(r'^Nonton\s+(?:film|series|movie)?\s*', caseSensitive: false), '')
                     .replaceAll(RegExp(r'\s*streaming\s+download\s+movie\s*$', caseSensitive: false), '')
                     .replaceAll(RegExp(r'\s*streaming\s+gratis\s*$', caseSensitive: false), '')
                     .trim();
        slug = url.replaceAll(RegExp(r'^https?:\/\/[^\/]+'), '').replaceAll('/', '').trim();
      }

      // Poster Image
      String posterUrl = '';
      final imgMatch = RegExp(r'<img[^>]*src="([^"]*)"', caseSensitive: false).firstMatch(block) ??
                       RegExp(r'<img[^>]*data-src="([^"]*)"', caseSensitive: false).firstMatch(block);
      if (imgMatch != null) {
        posterUrl = imgMatch.group(1) ?? '';
      }

      // Rating
      String rating = '';
      final ratingMatch = RegExp(r'class="rating"[^>]*>([^<]*)', caseSensitive: false).firstMatch(block) ??
                          RegExp(r'class="rating-label"[^>]*>([^<]*)', caseSensitive: false).firstMatch(block) ??
                          RegExp(r'(\d+\.\d+)\s*(?:<\/div>|\/10)', caseSensitive: false).firstMatch(block);
      if (ratingMatch != null) {
        rating = ratingMatch.group(1)?.trim() ?? '';
      }

      // Quality
      String quality = 'HD';
      final qualityMatch = RegExp(r'class="quality"[^>]*>([^<]*)', caseSensitive: false).firstMatch(block) ??
                           RegExp(r'class="label"[^>]*>([^<]*)', caseSensitive: false).firstMatch(block);
      if (qualityMatch != null) {
        quality = qualityMatch.group(1)?.trim() ?? 'HD';
      }

      // Year
      String year = '';
      final yearMatch = RegExp(r'\((\d{4})\)').firstMatch(title);
      if (yearMatch != null) {
        year = yearMatch.group(1) ?? '';
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
          year: year.isNotEmpty ? year : '2026',
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
      if (genreSlug.isEmpty) return fetchLatestMovies(page: page);
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

      // 4. Video Embed URL (e.g. videonode, feurl, dood, lk21 player)
      String embedUrl = '';
      final iframeMatch = RegExp(r'<iframe[^>]*id="main-player"[^>]*src="([^"]*)"', caseSensitive: false).firstMatch(html) ??
                          RegExp(r'<iframe[^>]*src="([^"]*(?:videonode|player|embed|stream)[^"]*)"', caseSensitive: false).firstMatch(html);
      if (iframeMatch != null) {
        embedUrl = iframeMatch.group(1) ?? '';
        if (embedUrl.startsWith('//')) {
          embedUrl = 'https:$embedUrl';
        }
      }

      // Fallback embed URL to activeBaseUrl + movie url if not extracted
      if (embedUrl.isEmpty) {
        embedUrl = movie.url.startsWith('http') ? movie.url : '${_config.activeBaseUrl}${movie.url}';
      }

      return movie.copyWith(
        synopsis: synopsis.isNotEmpty ? synopsis : 'Film seru pilihan terbaik siap menemani waktu santai Anda dengan kualitas Full HD dan subtitle bahasa Indonesia.',
        duration: duration.isNotEmpty ? duration : '1 jam 45 mnt',
        genres: genres.isNotEmpty ? genres : ['Action', 'Drama', 'HD'],
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
