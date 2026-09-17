import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static const String configUrl =
      'https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/app_config.json';

  String saweriaUrl = 'https://saweria.co/meiwatv';
  List<String> popunderUrls = [
    'https://www.profitableratecpmnetwork.com/r1x7jbv2ys?key=c06365de807e3e8605b4e7e665953775',
    'https://www.profitableratecpmnetwork.com/nhgf41xe?key=c1f7258bb9659ab225647c310b68619e',
  ];
  Map<String, dynamic> banners = {};
  int _tapCounter = 0;

  Future<void> initialize() async {
    try {
      final res = await http.get(
        Uri.parse('$configUrl?t=${DateTime.now().millisecondsSinceEpoch}'),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        if (data['saweriaUrl'] != null) {
          saweriaUrl = data['saweriaUrl'].toString();
        }
        if (data['popunderUrls'] is List) {
          popunderUrls = List<String>.from(data['popunderUrls']);
        }
        if (data['banners'] is Map<String, dynamic>) {
          banners = data['banners'] as Map<String, dynamic>;
        }
        debugPrint('✅ AdService berhasil memuat konfigurasi iklan & Saweria dari GitHub');
      }
    } catch (e) {
      debugPrint('AdService fallback ke default config: $e');
    }
  }

  /// Buka link donasi Saweria di browser
  Future<void> openSaweria() async {
    try {
      final uri = Uri.parse(saweriaUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Gagal membuka Saweria: $e');
    }
  }

  /// Memicu popunder sesekali (misal setiap 2-3 kali klik pertandingan)
  Future<void> triggerPopunder({bool force = false}) async {
    _tapCounter++;
    if (force || _tapCounter % 3 == 1) {
      if (popunderUrls.isEmpty) return;
      final url = popunderUrls[(_tapCounter ~/ 3) % popunderUrls.length];
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Popunder error: $e');
      }
    }
  }
}
