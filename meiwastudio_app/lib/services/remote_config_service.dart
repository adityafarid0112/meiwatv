import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  static const String primaryConfigUrl = 'https://meiwa.my.id/studio_sources.json';
  static const String fallbackConfigUrl = 'https://raw.githubusercontent.com/adityafarid0112/meiwatv-portal/main/studio_sources.json';

  String _activeBaseUrl = 'https://tv12.lk21official.cc';
  List<StudioSource> _sources = [
    StudioSource(name: 'LK21 Official Main', baseUrl: 'https://tv12.lk21official.cc', priority: 1, isActive: true),
    StudioSource(name: 'LK21 Auto-Redirect', baseUrl: 'https://www.lk21.de', priority: 2, isActive: true),
    StudioSource(name: 'LK21 Dev Mirror', baseUrl: 'https://tv.lk21official.dev', priority: 3, isActive: true),
    StudioSource(name: 'Layarkaca21 Backup', baseUrl: 'https://lite.dadadidi.de', priority: 4, isActive: true),
  ];

  List<GenreCategory> _genres = [
    const GenreCategory(title: 'Semua', slug: ''),
    const GenreCategory(title: 'Action', slug: 'action'),
    const GenreCategory(title: 'Drama Korea (Drakor)', slug: 'drama'),
    const GenreCategory(title: 'Horor', slug: 'horror'),
    const GenreCategory(title: 'Sci-Fi', slug: 'sci-fi'),
    const GenreCategory(title: 'Romance', slug: 'romance'),
    const GenreCategory(title: 'Komedi', slug: 'comedy'),
    const GenreCategory(title: 'Animasi / Anime', slug: 'animation'),
    const GenreCategory(title: 'Petualangan', slug: 'adventure'),
    const GenreCategory(title: 'Crime', slug: 'crime'),
    const GenreCategory(title: 'Thriller', slug: 'thriller'),
    const GenreCategory(title: 'Misteri', slug: 'mystery'),
    const GenreCategory(title: 'Family', slug: 'family'),
  ];

  List<String> _adBlockPatterns = [
    'doubleclick.net',
    'profitablecpmrate',
    'highrevenueformat',
    'adcash',
    'popads',
    'propellerads',
    'exoclick',
    'onclickmega',
    'betting',
    'slot',
    'judol'
  ];

  String get activeBaseUrl => _activeBaseUrl;
  List<GenreCategory> get genres => _genres;
  List<String> get adBlockPatterns => _adBlockPatterns;

  Future<void> initConfig() async {
    try {
      debugPrint('[RemoteConfig] Fetching cloud config...');
      http.Response? response;
      
      try {
        response = await http.get(Uri.parse(primaryConfigUrl)).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('[RemoteConfig] Primary failed, trying fallback: $e');
        response = await http.get(Uri.parse(fallbackConfigUrl)).timeout(const Duration(seconds: 4));
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sources'] != null && data['sources'] is List) {
          _sources = (data['sources'] as List)
              .map((s) => StudioSource.fromJson(s))
              .where((s) => s.isActive)
              .toList();
          _sources.sort((a, b) => a.priority.compareTo(b.priority));
        }

        if (data['genres'] != null && data['genres'] is List) {
          _genres = (data['genres'] as List).map((g) => GenreCategory.fromJson(g)).toList();
        }

        if (data['adBlockList'] != null && data['adBlockList'] is List) {
          _adBlockPatterns = List<String>.from(data['adBlockList'])
              .map((p) => p.replaceAll('*', ''))
              .toList();
        }

        debugPrint('[RemoteConfig] Config updated successfully. Total sources: ${_sources.length}');
      }
    } catch (e) {
      debugPrint('[RemoteConfig] Failed to fetch remote config, using embedded fallbacks: $e');
    }

    // Resolve working base URL
    await resolveActiveBaseUrl();
  }

  /// Automatically tests candidate sources and selects the fastest responsive working URL
  Future<String> resolveActiveBaseUrl() async {
    for (final src in _sources) {
      try {
        final uri = Uri.parse(src.baseUrl);
        final res = await http.get(uri, headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200 || (res.statusCode >= 300 && res.statusCode < 400)) {
          if (res.headers['location'] != null && res.headers['location']!.startsWith('http')) {
            _activeBaseUrl = res.headers['location']!;
          } else {
            _activeBaseUrl = src.baseUrl;
          }
          debugPrint('[RemoteConfig] Selected active base URL: $_activeBaseUrl (${src.name})');
          return _activeBaseUrl;
        }
      } catch (e) {
        debugPrint('[RemoteConfig] Candidate ${src.baseUrl} failed: $e, trying next mirror...');
      }
    }

    debugPrint('[RemoteConfig] Fallback to default: $_activeBaseUrl');
    return _activeBaseUrl;
  }

  void switchBaseUrl(String newUrl) {
    _activeBaseUrl = newUrl;
  }
}
