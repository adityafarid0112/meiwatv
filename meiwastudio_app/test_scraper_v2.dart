import 'package:http/http.dart' as http;

class MovieItem {
  final String title;
  final String slug;
  final String url;
  final String posterUrl;
  final String rating;
  final String quality;
  final String year;
  final String duration;
  final List<String> genres;

  MovieItem({
    required this.title,
    required this.slug,
    required this.url,
    required this.posterUrl,
    required this.rating,
    required this.quality,
    required this.year,
    required this.duration,
    required this.genres,
  });

  @override
  String toString() => '[$quality] $title ($year) ⭐$rating - $duration | ${genres.join(", ")}\nPoster: $posterUrl\nURL: $url\n';
}

List<MovieItem> parseMovies(String html) {
  final List<MovieItem> list = [];
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

    if (title.isNotEmpty && posterUrl.isNotEmpty) {
      list.add(MovieItem(
        title: title,
        slug: slug,
        url: url,
        posterUrl: posterUrl,
        rating: rating.isNotEmpty ? rating : '7.8',
        quality: quality,
        year: year,
        duration: duration,
        genres: genres,
      ));
    }
  }

  return list;
}

void main() async {
  final client = http.Client();
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  };

  print('Testing parser on /populer:');
  final res = await client.get(Uri.parse('https://tv12.lk21official.cc/populer'), headers: headers);
  final items = parseMovies(res.body);
  print('Successfully parsed ${items.length} movies!\n');
  items.take(5).forEach(print);
}
