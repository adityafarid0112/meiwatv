import 'package:http/http.dart' as http;

void main() async {
  print('--- Testing LK21 Scraper in Dart ---');
  final client = http.Client();
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
  };

  try {
    final res = await client.get(Uri.parse('https://tv12.lk21official.cc/populer'), headers: headers);
    print('Status: ${res.statusCode}');
    print('Body length: ${res.body.length}');
    if (res.body.length > 0) {
      final articleRegex = RegExp(r'<article[^>]*>([\s\S]*?)<\/article>', caseSensitive: false);
      final matches = articleRegex.allMatches(res.body);
      print('Articles found on /populer: ${matches.length}');

      // Test homepage /
      final homeRes = await client.get(Uri.parse('https://tv12.lk21official.cc/'), headers: headers);
      print('Home status: ${homeRes.statusCode}, body length: ${homeRes.body.length}');
      final homeMatches = articleRegex.allMatches(homeRes.body);
      print('Articles found on /: ${homeMatches.length}');

      for (var i = 0; i < (matches.length < 3 ? matches.length : 3); i++) {
        final block = matches.elementAt(i).group(1) ?? '';
        print('\n--- Article [$i] ---');
        print(block.length > 300 ? block.substring(0, 300) : block);
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
