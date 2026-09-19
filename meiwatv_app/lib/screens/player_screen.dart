import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/match_model.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/live_badge.dart';
import '../widgets/team_logo_widget.dart';
import '../widgets/tv_focusable_button.dart';

class PlayerScreen extends StatefulWidget {
  final MatchModel match;

  const PlayerScreen({super.key, required this.match});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoController;
  WebViewController? _webController;
  bool _isWebView = false;
  int _activeJalur = 1; // 1 = Jalur 1, 2 = Jalur 2, 3 = Jalur 3
  bool _isLoading = true;
  bool _isPlaying = true;
  bool _isMuted = false;
  String? _errorMessage;
  bool _showControls = true;
  Timer? _controlsTimer;
  BoxFit _videoFit = BoxFit.contain; // contain, cover, fill

  @override
  void initState() {
    super.initState();
    // 1. Mencegah layar HP / Android TV mati atau masuk mode screen saver saat menonton siaran
    WakelockPlus.enable();

    // 2. Otomatis masuk ke mode Fullscreen Landscape Immersive murni
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Prioritaskan Jalur 1, lalu 2, lalu 3
    if (widget.match.streamJalur1.isNotEmpty) {
      _activeJalur = 1;
    } else if (widget.match.streamJalur2.isNotEmpty) {
      _activeJalur = 2;
    } else {
      _activeJalur = 3;
    }

    _initPlayer();
    _resetControlsTimer();
  }

  bool _isWebEmbed(String url) {
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();
    if (lower.endsWith('.m3u8') || lower.endsWith('.flv') || lower.endsWith('.mp4')) {
      return false;
    }
    if (lower.contains('daddylive') ||
        lower.contains('dlhd.sx') ||
        lower.contains('embed.php') ||
        lower.contains('/player/') ||
        lower.contains('/embed/') ||
        lower.contains('/stream/') ||
        lower.contains('.php')) {
      return true;
    }
    return false;
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsOverlay() {
    if (!mounted) return;
    setState(() {
      _showControls = true;
    });
    _resetControlsTimer();
  }

  void _toggleControls() {
    if (_showControls) {
      _controlsTimer?.cancel();
      setState(() {
        _showControls = false;
      });
    } else {
      _showControlsOverlay();
    }
  }

  String _getActiveStreamUrl() {
    switch (_activeJalur) {
      case 1:
        return widget.match.streamJalur1.isNotEmpty
            ? widget.match.streamJalur1
            : widget.match.streamJalur2;
      case 2:
        return widget.match.streamJalur2.isNotEmpty
            ? widget.match.streamJalur2
            : widget.match.streamJalur1;
      case 3:
        return widget.match.streamJalur3.isNotEmpty
            ? widget.match.streamJalur3
            : widget.match.streamJalur1;
      case 4:
        return widget.match.streamJalur4.isNotEmpty
            ? widget.match.streamJalur4
            : widget.match.streamJalur1;
      default:
        return widget.match.streamJalur1;
    }
  }

  String _getRefererForUrl(String url) {
    if (widget.match.streamJalur3.isNotEmpty &&
        widget.match.streamJalur3.startsWith('http') &&
        !widget.match.streamJalur3.contains('domainkqt.cc')) {
      try {
        final uri = Uri.parse(widget.match.streamJalur3);
        return '${uri.scheme}://${uri.host}/';
      } catch (_) {}
    }
    if (url.startsWith('http') && !url.contains('domainkqt.cc')) {
      try {
        final uri = Uri.parse(url);
        return '${uri.scheme}://${uri.host}/';
      } catch (_) {}
    }
    return 'https://xoilaczzf.cc/';
  }

  /// Ekstraksi rekursif semua link stream yang valid dari JSON object/list
  void _extractStreamsFromJson(dynamic jsonVal, List<String> results) {
    if (jsonVal == null) return;
    if (jsonVal is String) {
      final s = jsonVal.replaceAll(r'\/', '/').replaceAll(r'\', '').trim();
      if (s.startsWith('http') &&
          (s.contains('.m3u8') ||
              s.contains('.mp4') ||
              s.contains('live') ||
              s.contains('stream') ||
              s.contains('chanel') ||
              s.contains('channel'))) {
        if (!results.contains(s)) results.add(s);
      }
    } else if (jsonVal is List) {
      for (final item in jsonVal) {
        _extractStreamsFromJson(item, results);
      }
    } else if (jsonVal is Map) {
      for (final key in ['link', 'play_url', 'url', 'stream', 'src', 'm3u8', 'urlStream', 'data']) {
        if (jsonVal.containsKey(key)) {
          _extractStreamsFromJson(jsonVal[key], results);
        }
      }
      for (final val in jsonVal.values) {
        if (val is Map || val is List) {
          _extractStreamsFromJson(val, results);
        }
      }
    }
  }

  /// Ekstraksi langsung video stream .m3u8 resolusi 1080p dari DaddyLive
  Future<String?> _resolveDaddyDirectM3u8(String embedUrl) async {
    if (embedUrl.isEmpty || !embedUrl.startsWith('http')) return null;
    try {
      final res1 = await http.get(Uri.parse(embedUrl), headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
        'Referer': 'https://daddylive.app/'
      }).timeout(const Duration(seconds: 4));

      if (res1.statusCode != 200) return null;
      final html1 = res1.body;

      String? playerUrl;
      final iframeMatch = RegExp(
            r'src=["\x27](https?://[^"\x27]*stream[^\s"\x27<>]+)["\x27]',
            caseSensitive: false,
          ).firstMatch(html1) ??
          RegExp(
            r'src=["\x27](https?://[^"\x27]+\.php\?stream=[^"\x27]+)["\x27]',
            caseSensitive: false,
          ).firstMatch(html1) ??
          RegExp(
            r'src=["\x27](https?://[^"\x27]*embed\.st[^\s"\x27<>]+)["\x27]',
            caseSensitive: false,
          ).firstMatch(html1) ??
          RegExp(
            r'src=["\x27](https?://[^"\x27]+)["\x27]',
            caseSensitive: false,
          ).firstMatch(html1);

      if (iframeMatch != null) {
        playerUrl = iframeMatch.group(1);
      } else {
        final jsonMatch = RegExp(r'const\s+PLAYERS\s*=\s*(\[[^\]]+\])', caseSensitive: false).firstMatch(html1);
        if (jsonMatch != null) {
          try {
            final players = json.decode(jsonMatch.group(1)!);
            if (players is List && players.isNotEmpty && players[0]['src'] != null) {
              playerUrl = players[0]['src'] as String;
            }
          } catch (_) {}
        }
      }

      if (playerUrl == null || !playerUrl.startsWith('http')) return null;

      final res2 = await http.get(Uri.parse(playerUrl), headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
        'Referer': embedUrl
      }).timeout(const Duration(seconds: 4));

      if (res2.statusCode != 200) return null;
      final html2 = res2.body;

      final m3u8Match = RegExp(
            r'var\s+playbackURL\s*=\s*["\x27](https?:[^"\x27]+\.m3u8[^"\x27]*)["\x27]',
            caseSensitive: false,
          ).firstMatch(html2) ??
          RegExp(
            r'["\x27](https?:[^\s"\x27<>]+\.m3u8[^\s"\x27<>]*)["\x27]',
            caseSensitive: false,
          ).firstMatch(html2);

      if (m3u8Match != null) {
        return m3u8Match.group(1)?.replaceAll(r'\/', '/').replaceAll(r'\', '');
      }

      final nestedMatch = RegExp(
            r'src=["\x27](https?://[^"\x27]*(?:epiembeds|flyembed|rockystream)[^\s"\x27<>]+)["\x27]',
            caseSensitive: false,
          ).firstMatch(html2) ??
          RegExp(
            r'<iframe[^>]+src=["\x27](https?://[^\s"\x27<>]+)["\x27]',
            caseSensitive: false,
          ).firstMatch(html2);

      if (nestedMatch != null) {
        final nestedUrl = nestedMatch.group(1);
        if (nestedUrl != null && nestedUrl.startsWith('http')) {
          final res3 = await http.get(Uri.parse(nestedUrl), headers: {
            'User-Agent': 'Mozilla/5.0',
            'Referer': playerUrl
          }).timeout(const Duration(seconds: 4));
          if (res3.statusCode == 200) {
            final html3 = res3.body;

            // Deobfuscate epiembeds format
            final deobMatch = RegExp(
              r'var\s+(_[a-z0-9]+)=\[([0-9,]+)\][\s\S]*?(_[a-z0-9]+)=([0-9]+)[\s\S]*?(_[a-z0-9]+)=([0-9]+)[\s\S]*?String\.fromCharCode',
              caseSensitive: false,
            ).firstMatch(html3);
            if (deobMatch != null) {
              final rawArr = deobMatch.group(2)!.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
              final vk = int.tryParse(deobMatch.group(4)!) ?? 0;
              final ko = int.tryParse(deobMatch.group(6)!) ?? 0;
              final buffer = StringBuffer();
              for (final val in rawArr) {
                buffer.writeCharCode(((val ^ vk) - ko + 256) & 255);
              }
              final decodedStr = buffer.toString();
              final urlMatch = RegExp(
                r'url\s*=\s*["\x27](https?:[^"\x27]+\.m3u8[^"\x27]*)["\x27]',
                caseSensitive: false,
              ).firstMatch(decodedStr);
              if (urlMatch != null) {
                return urlMatch.group(1);
              }
            }

            final m3u8Nested = RegExp(
                  r'var\s+playbackURL\s*=\s*["\x27](https?:[^"\x27]+\.m3u8[^"\x27]*)["\x27]',
                  caseSensitive: false,
                ).firstMatch(html3) ??
                RegExp(
                  r'["\x27](https?:[^\s"\x27<>]+\.m3u8[^\s"\x27<>]*)["\x27]',
                  caseSensitive: false,
                ).firstMatch(html3);
            if (m3u8Nested != null) {
              return m3u8Nested.group(1)?.replaceAll(r'\/', '/').replaceAll(r'\', '');
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Ekstraksi semua kandidat direct video (.m3u8 / .mp4 / CDN HLS) dari web sumber
  Future<List<String>> _resolveCandidateStreams(String rawUrl) async {
    final candidates = <String>[];
    if (rawUrl.isEmpty) return candidates;

    final lower = rawUrl.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mp4')) {
      candidates.add(rawUrl);
      return candidates;
    }

    // 1. Jika URL berasal dari DaddyLive, resolve langsung ke direct stream .m3u8 HD 1080p
    if (lower.contains('daddylive') ||
        lower.contains('streamtp') ||
        lower.contains('domhsd') ||
        lower.contains('dlhd') ||
        lower.contains('embed.php')) {
      final daddyDirect = await _resolveDaddyDirectM3u8(rawUrl);
      if (daddyDirect != null && daddyDirect.isNotEmpty) {
        candidates.add(daddyDirect);
        return candidates;
      }
    }

    final referersToTry = [
      _getRefererForUrl(rawUrl),
      'https://xoilaczzf.cc/',
      'https://atttvnow.com/',
      'https://theceoschool.co/',
    ];

    for (final referer in referersToTry) {
      try {
        final headers = {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14; Mobile; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
          'Referer': referer,
          'Origin': referer.endsWith('/')
              ? referer.substring(0, referer.length - 1)
              : referer,
          'Accept': '*/*',
        };

        final response = await http
            .get(Uri.parse(rawUrl), headers: headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final body = response.body.trim();

          // 1. Ekstraksi var urlStream = "https://...";
          final urlStreamMatches = RegExp(
            r'var\s+urlStream\s*=\s*["\x27](https?://[^"\x27\s]+)["\x27]',
            caseSensitive: false,
          ).allMatches(body);
          for (final m in urlStreamMatches) {
            final s = m.group(1);
            if (s != null && s.isNotEmpty) {
              final m3u8 = s.replaceAll(RegExp(r'\.flv(?=\?|$)', caseSensitive: false), '.m3u8');
              if (!candidates.contains(m3u8)) candidates.add(m3u8);
              if (!candidates.contains(s)) candidates.add(s);
            }
          }

          // 2. Ekstraksi list_stream JSON array jika membuka Match Page
          final listStreamMatch = RegExp(
            r'var\s+list_stream\s*=\s*(\[[^\]]+\])',
            caseSensitive: false,
          ).firstMatch(body);
          if (listStreamMatch != null) {
            final raw = listStreamMatch
                .group(1)
                ?.replaceAll(r'\/', '/')
                .replaceAll(r'\', '');
            if (raw != null) {
              final innerMatches = RegExp(r'https?://[^\s"<>]+').allMatches(raw);
              for (final m in innerMatches) {
                final innerUrl = m.group(0);
                if (innerUrl != null && innerUrl != rawUrl) {
                  final sub = await _resolveCandidateStreams(innerUrl);
                  for (final item in sub) {
                    if (!candidates.contains(item)) candidates.add(item);
                  }
                }
              }
            }
          }

          // 3. Ekstraksi link m3u8 langsung di dalam body response
          final m3u8Matches = RegExp(
            r'https?://[^\s"<>]+?\.m3u8[^\s"<>]*',
            caseSensitive: false,
          ).allMatches(body);
          for (final m in m3u8Matches) {
            final s = m.group(0);
            if (s != null && s.isNotEmpty && !candidates.contains(s)) {
              candidates.add(s);
            }
          }

          // 4. Cek apakah response berupa JSON
          if (body.startsWith('{') || body.startsWith('[')) {
            try {
              final decoded = json.decode(body);
              final jsonStreams = <String>[];
              _extractStreamsFromJson(decoded, jsonStreams);
              for (final s in jsonStreams) {
                final m3u8 = s.replaceAll(RegExp(r'\.flv(?=\?|$)', caseSensitive: false), '.m3u8');
                if (!candidates.contains(m3u8)) candidates.add(m3u8);
                if (!candidates.contains(s)) candidates.add(s);
              }
            } catch (_) {}
          }

          if (candidates.isNotEmpty) break;
        }
      } catch (e) {
        debugPrint('[Player] Resolution error with referer $referer: $e');
      }
    }

    return candidates;
  }

  Future<bool> _tryPlayStream(String streamUrl, String rawUrl) async {
    final headerOptions = [
      // Opsi 1: Standard ExoPlayer User-Agent (Paling Kompatibel & Diterima CDN)
      {
        'User-Agent': 'ExoPlayerLib/2.18.7',
      },
      // Opsi 2: Minimal header tanpa referer (Menghindari 403 CDN hotlink protection)
      <String, String>{},
      // Opsi 3: Mobile Chrome Browser User-Agent
      {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14; Mobile; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
      },
    ];

    for (final headers in headerOptions) {
      try {
        await _videoController?.dispose();
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(streamUrl),
          httpHeaders: headers,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

        await controller.initialize().timeout(const Duration(seconds: 5));
        if (_isMuted) controller.setVolume(0);
        controller.play();

        if (mounted) {
          setState(() {
            _videoController = controller;
            _isPlaying = true;
            _isLoading = false;
            _errorMessage = null;
          });
        }
        return true;
      } catch (e) {
        debugPrint('[Player] Play attempt failed for $streamUrl: $e');
      }
    }
    return false;
  }

  Future<void> _playInWebView(String url) async {
    await _videoController?.dispose();
    _videoController = null;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Mobile; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String pageUrl) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (String pageUrl) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isPlaying = true;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[WebView Player Error] ${error.description}');
          },
        ),
      );

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body {
      width: 100vw;
      height: 100vh;
      background-color: #000000;
      overflow: hidden;
    }
    iframe {
      width: 100%;
      height: 100%;
      border: 0;
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
    }
  </style>
</head>
<body>
  <iframe src="$url" allowfullscreen="true" allow="encrypted-media; autoplay; fullscreen" scrolling="no"></iframe>
</body>
</html>
''';

    await controller.loadHtmlString(htmlContent, baseUrl: 'https://daddylive.app/');

    if (mounted) {
      setState(() {
        _webController = controller;
        _isWebView = true;
        _isLoading = false;
        _isPlaying = true;
        _errorMessage = null;
      });
    }
  }

  Future<void> _initPlayer({bool autoFallbackJalur = true}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final rawUrl = _getActiveStreamUrl();
    if (rawUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Link siaran untuk Jalur $_activeJalur belum tersedia saat ini.\nSilakan coba Jalur Server lainnya.';
      });
      return;
    }

    // 1. Coba resolve direct stream HLS (.m3u8) terlebih dahulu untuk SEMUA jenis URL (termasuk DaddyLive)
    setState(() {
      _isWebView = false;
      _webController = null;
    });

    final candidates = await _resolveCandidateStreams(rawUrl);

    for (final cand in candidates) {
      final success = await _tryPlayStream(cand, rawUrl);
      if (success) return;
    }

    // 2. Jika gagal direct stream dan URL adalah Web Embed / HTML, fallback ke WebView
    if (_isWebEmbed(rawUrl) || rawUrl.startsWith('http')) {
      await _playInWebView(rawUrl);
      return;
    }

    // 3. Jika jalur aktif gagal, coba auto-fallback ke jalur lain jika diizinkan
    if (autoFallbackJalur) {
      final otherJalurs = [1, 2, 3].where((j) => j != _activeJalur).toList();
      for (final altJalur in otherJalurs) {
        String altUrl = '';
        if (altJalur == 1) altUrl = widget.match.streamJalur1;
        if (altJalur == 2) altUrl = widget.match.streamJalur2;
        if (altJalur == 3) altUrl = widget.match.streamJalur3;

        if (altUrl.isNotEmpty && altUrl != rawUrl) {
          if (_isWebEmbed(altUrl)) {
            setState(() => _activeJalur = altJalur);
            await _playInWebView(altUrl);
            return;
          }
          final altCandidates = await _resolveCandidateStreams(altUrl);
          for (final cand in altCandidates) {
            final success = await _tryPlayStream(cand, altUrl);
            if (success) {
              if (mounted) {
                setState(() {
                  _activeJalur = altJalur;
                });
              }
              return;
            }
          }
        }
      }
    }

    // Jika seluruh upaya gagal / stream offline
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Siaran pada pertandingan ini belum dimulai atau sedang offline.\nSilakan coba pilih Jalur Server lain atau ketuk "Coba Lagi":';
      });
    }
  }

  void _switchJalur(int jalurIndex) {
    if (_activeJalur == jalurIndex && !_isLoading && _errorMessage == null) {
      _resetControlsTimer();
      return;
    }
    AdService().triggerPopunder();
    setState(() {
      _activeJalur = jalurIndex;
    });
    _initPlayer(autoFallbackJalur: false);
    _resetControlsTimer();
  }

  void _togglePlayPause() {
    _resetControlsTimer();
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    _resetControlsTimer();
    setState(() {
      _isMuted = !_isMuted;
    });
    _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
  }

  void _cycleVideoFit() {
    _resetControlsTimer();
    setState(() {
      if (_videoFit == BoxFit.contain) {
        _videoFit = BoxFit.cover;
      } else if (_videoFit == BoxFit.cover) {
        _videoFit = BoxFit.fill;
      } else {
        _videoFit = BoxFit.contain;
      }
    });
  }

  String _getVideoFitLabel() {
    if (_videoFit == BoxFit.contain) return 'Fit Layar';
    if (_videoFit == BoxFit.cover) return 'Zoom (Penuh)';
    return 'Stretch';
  }

  void _shareMatch() {
    _resetControlsTimer();
    final match = widget.match;
    SharePlus.instance.share(
      ShareParams(
        text:
            'Ayo nonton siaran langsung ${match.title} (${match.league}) gratis di aplikasi MeiwaSports!\n\nLink Dukungan: https://saweria.co/meiwatv',
        subject: 'Nonton ${match.title} di MeiwaSports',
      ),
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _videoController?.dispose();
    _webController = null;
    WakelockPlus.disable();

    // Kembalikan orientasi layar dan system UI saat keluar dari pemutar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return FocusScope(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Tombol remote TV D-Pad akan memunculkan menu kontrol
          if (!_showControls) {
            _showControlsOverlay();
            return KeyEventResult.handled;
          } else {
            _resetControlsTimer();
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. AREA VIDEO PLAYER (WebView Iframe untuk DaddyLive / ExoPlayer untuk Direct HLS)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: Center(
                  child: _isLoading
                      ? _buildLoadingWidget()
                      : _errorMessage != null
                      ? _buildErrorWidget()
                      : _isWebView && _webController != null
                      ? SizedBox.expand(
                          child: WebViewWidget(controller: _webController!),
                        )
                      : _videoController != null &&
                            _videoController!.value.isInitialized
                      ? SizedBox.expand(
                          child: FittedBox(
                            fit: _videoFit,
                            child: SizedBox(
                              width: _videoController!.value.size.width,
                              height: _videoController!.value.size.height,
                              child: VideoPlayer(_videoController!),
                            ),
                          ),
                        )
                      : _buildLoadingWidget(),
                ),
              ),

              // 2. Center Play / Pause Indicator saat di-pause
              if (!_isLoading &&
                  _errorMessage == null &&
                  _videoController != null &&
                  !_isPlaying &&
                  _showControls)
                Center(
                  child: TvFocusableButton(
                    onTap: _togglePlayPause,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cyanAccent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyanAccent.withValues(alpha: 0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  ),
                ),

              // 3. Progress Bar Tipis di Atas saat Loading
              if (_isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    color: AppColors.cyanAccent,
                    backgroundColor: Colors.transparent,
                    minHeight: 3,
                  ),
                ),

              // 4. TOP BAR: Judul, Liga, Saweria, Mute, Reload, Aspect Ratio, Share
              if (_showControls)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final topWidth = constraints.maxWidth;
                      final isTvOrWide = topWidth > 700;

                      return Container(
                        padding: EdgeInsets.fromLTRB(
                          isTvOrWide ? 26 : 14,
                          isTvOrWide ? 22 : 12,
                          isTvOrWide ? 26 : 14,
                          14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.95),
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            // Tombol Kembali
                            TvFocusableButton(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(8),
                              tooltip: 'Kembali',
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Info Pertandingan (Tim & Liga)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getSportIcon(match.sportCategory),
                                        size: 14,
                                        color: AppColors.cyanAccent,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${match.homeTeam} vs ${match.awayTeam}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isTvOrWide ? 15.5 : 13.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    match.league.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.cyanAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Live Badge
                            LiveBadge(
                              isLive: match.isLive,
                              text: match.isLive ? 'LIVE' : match.kickoffText,
                            ),
                            const SizedBox(width: 8),

                            // 1. Saweria Donation
                            TvFocusableButton(
                              onTap: () {
                                _resetControlsTimer();
                                AdService().openSaweria();
                              },
                              borderRadius: BorderRadius.circular(14),
                              focusedBorderColor: const Color(0xFFFF9800),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF9800),
                                      Color(0xFFFF5722),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.volunteer_activism_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Saweria',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 2. Tombol Fit / Aspect Ratio
                            TvFocusableButton(
                              onTap: _cycleVideoFit,
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              tooltip: 'Ubah Ukuran Layar',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.aspect_ratio_rounded,
                                      color: AppColors.cyanAccent,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getVideoFitLabel(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 3. Tombol Mute / Suara
                            TvFocusableButton(
                              onTap: _toggleMute,
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(7),
                              tooltip: _isMuted
                                  ? 'Nyalakan Suara'
                                  : 'Matikan Suara',
                              child: Icon(
                                _isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: _isMuted
                                    ? AppColors.liveRed
                                    : AppColors.cyanAccent,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 4. Tombol Reload
                            TvFocusableButton(
                              onTap: () {
                                _resetControlsTimer();
                                _initPlayer();
                              },
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(7),
                              tooltip: 'Muat Ulang Siaran',
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 5. Tombol Share
                            TvFocusableButton(
                              onTap: _shareMatch,
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(7),
                              tooltip: 'Bagikan Siaran',
                              child: const Icon(
                                Icons.share_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 6. Tombol Layar Penuh (Sembunyikan Overlay)
                            TvFocusableButton(
                              onTap: () {
                                setState(() {
                                  _showControls = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(7),
                              tooltip: 'Sembunyikan Menu',
                              child: const Icon(
                                Icons.fullscreen_exit_rounded,
                                color: AppColors.cyanAccent,
                                size: 23,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // 5. BOTTOM BAR: Jalur Server Switcher (Jalur 1 / 2 / 3)
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.95),
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.dns_rounded,
                              color: AppColors.cyanAccent,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'PILIH JALUR SERVER STREAMING (NATIVE HLS):',
                              style: TextStyle(
                                color: AppColors.cyanAccent,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            if (_videoController != null &&
                                _videoController!.value.isInitialized)
                              Text(
                                '${_videoController!.value.size.width.toInt()}x${_videoController!.value.size.height.toInt()} HD',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Builder(
                          builder: (context) {
                            final jalurs = <int>[1];
                            if (widget.match.streamJalur2.isNotEmpty && widget.match.streamJalur2 != widget.match.streamJalur1) {
                              jalurs.add(2);
                            }
                            if (widget.match.streamJalur3.isNotEmpty && widget.match.streamJalur3 != widget.match.streamJalur1 && widget.match.streamJalur3 != widget.match.streamJalur2) {
                              jalurs.add(3);
                            }
                            if (widget.match.streamJalur4.isNotEmpty && widget.match.streamJalur4 != widget.match.streamJalur1 && widget.match.streamJalur4 != widget.match.streamJalur2 && widget.match.streamJalur4 != widget.match.streamJalur3) {
                              jalurs.add(4);
                            }
                            if (jalurs.length == 1) {
                              if (widget.match.streamJalur2.isNotEmpty) jalurs.add(2);
                              if (widget.match.streamJalur3.isNotEmpty) jalurs.add(3);
                            }

                            return Row(
                              children: jalurs.map((j) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: _buildJalurButton(
                                      j,
                                      _getJalurTitle(j),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getJalurTitle(int index) {
    String url = '';
    if (index == 1) url = widget.match.streamJalur1;
    if (index == 2) url = widget.match.streamJalur2;
    if (index == 3) url = widget.match.streamJalur3;
    if (index == 4) url = widget.match.streamJalur4;

    final lower = url.toLowerCase();
    if (lower.contains('daddylive') ||
        lower.contains('domhsd') ||
        lower.contains('streamtp') ||
        lower.contains('dlhd') ||
        lower.contains('bolaloca') ||
        lower.contains('assetrage')) {
      return 'Jalur $index (DaddyLive HD 1080p)';
    } else if (lower.contains('zundrix') ||
        lower.contains('xoilac') ||
        lower.contains('soi-keo') ||
        lower.contains('/truc-tiep/')) {
      return 'Jalur $index (Xoilac Backup)';
    } else if (lower.contains('.m3u8')) {
      return 'Jalur $index (HD Stream)';
    } else if (url.isNotEmpty) {
      return 'Jalur $index (Server HD)';
    } else {
      return 'Jalur $index (Cadangan)';
    }
  }

  Widget _buildLoadingWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            color: AppColors.cyanAccent,
            strokeWidth: 3.5,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Menghubungkan ke Jalur $_activeJalur...',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mengambil siaran langsung ${widget.match.title}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      constraints: const BoxConstraints(maxWidth: 580),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TeamLogoWidget(
                teamName: widget.match.homeTeam,
                logoUrl: widget.match.homeLogo,
                size: 38,
                sportCategory: widget.match.sportCategory,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: AppColors.cyanAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TeamLogoWidget(
                teamName: widget.match.awayTeam,
                logoUrl: widget.match.awayLogo,
                size: 38,
                sportCategory: widget.match.sportCategory,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Siaran belum aktif.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSmallJalurButton(1, _getJalurTitle(1)),
              _buildSmallJalurButton(2, _getJalurTitle(2)),
              _buildSmallJalurButton(3, _getJalurTitle(3)),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Coba Lagi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _initPlayer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJalurButton(int index, String title) {
    final isSelected = _activeJalur == index;

    return TvFocusableButton(
      onTap: () => _switchJalur(index),
      borderRadius: BorderRadius.circular(12),
      focusedBorderColor: AppColors.cyanAccent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyanAccent : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGlow.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallJalurButton(int index, String title) {
    final isSelected = _activeJalur == index;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
        side: BorderSide(
          color: isSelected ? AppColors.cyanAccent : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      onPressed: () => _switchJalur(index),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  IconData _getSportIcon(String sportCategory) {
    final sport = sportCategory.toLowerCase();
    if (sport.contains('basket')) return Icons.sports_basketball_rounded;
    if (sport.contains('voli')) return Icons.sports_volleyball_rounded;
    if (sport.contains('tangkis') || sport.contains('badminton')) {
      return Icons.sports_tennis_rounded;
    }
    if (sport.contains('tenis')) return Icons.sports_tennis_rounded;
    if (sport.contains('moto') ||
        sport.contains('f1') ||
        sport.contains('racing')) {
      return Icons.sports_motorsports_rounded;
    }
    if (sport.contains('esport')) return Icons.sports_esports_rounded;
    return Icons.sports_soccer_rounded;
  }
}
