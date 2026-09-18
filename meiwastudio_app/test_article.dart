import 'package:http/http.dart' as http;

void main() async {
  final client = http.Client();
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  };

  final res = await client.get(Uri.parse('https://tv12.lk21official.cc/populer'), headers: headers);
  final articleRegex = RegExp(r'<article[^>]*>([\s\S]*?)<\/article>', caseSensitive: false);
  final matches = articleRegex.allMatches(res.body);

  if (matches.isNotEmpty) {
    print('=== Full Article [0] ===');
    print(matches.first.group(1));
  }
}
