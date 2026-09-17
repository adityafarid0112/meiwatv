import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../models/match_model.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/live_badge.dart';
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
  int _activeJalur = 1; // 1 = Jalur 1, 2 = Jalur 2, 3 = Jalur 3
  bool _isLoading = true;
  bool _isWebMode = false;
  bool _isMuted = false;
  String? _errorMessage;
  bool _showControls = true;
  Timer? _controlsTimer;
  final BoxFit _videoFit = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    // 1. Mencegah TV / HP masuk ke mode Screen Saver / Standby saat siaran diputar
    WakelockPlus.enable();

    // 2. Otomatis masuk ke mode Fullscreen Landscape Immersive saat pertandingan dibuka
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
        return widget.match.streamJalur1;
      case 2:
        return widget.match.streamJalur2;
      case 3:
        return widget.match.streamJalur3;
      default:
        return widget.match.streamJalur1;
    }
  }

  String _getRefererForUrl(String url) {
    if (widget.match.streamJalur2.isNotEmpty && widget.match.streamJalur2.startsWith('http')) {
      try {
        final uri = Uri.parse(widget.match.streamJalur2);
        return '${uri.scheme}://${uri.host}/';
      } catch (_) {}
    }
    if (widget.match.streamJalur3.isNotEmpty && widget.match.streamJalur3.startsWith('http')) {
      try {
        final uri = Uri.parse(widget.match.streamJalur3);
        return '${uri.scheme}://${uri.host}/';
      } catch (_) {}
    }
    return 'https://scoopnashville.com/';
  }

  Future<String?> _resolveDirectStreamUrl(String url) async {
    if (url.isEmpty) return null;
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mp4')) {
      return url;
    }

    try {
      final referer = _getRefererForUrl(url);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14; Mobile; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
          'Referer': referer,
          'Origin': referer.endsWith('/')
              ? referer.substring(0, referer.length - 1)
              : referer,
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final body = response.body;

        // 1. Ekstraksi var urlStream = "https://...";
        final urlStreamMatch = RegExp(
          r'var\s+urlStream\s*=\s*["\x27](https?://[^"\x27\s]+)["\x27]',
          caseSensitive: false,
        ).firstMatch(body);
        if (urlStreamMatch != null) {
          final stream = urlStreamMatch.group(1);
          if (stream != null && stream.isNotEmpty) return stream;
        }

        // 2. Ekstraksi URL .m3u8 langsung di dalam body response
        final m3u8Match = RegExp(
          r'https?://[^\s"<>]+?\.m3u8[^\s"<>]*',
          caseSensitive: false,
        ).firstMatch(body);
        if (m3u8Match != null) {
          final stream = m3u8Match.group(0);
          if (stream != null && stream.isNotEmpty) return stream;
        }

        // 3. Ekstraksi list_stream jika berupa halaman pertandingan langsung
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
              if (innerUrl != null && innerUrl != url) {
                final resolved = await _resolveDirectStreamUrl(innerUrl);
                if (resolved != null) return resolved;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Direct stream resolution info: $e');
    }
    return null;
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = _getActiveStreamUrl();
    if (url.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Link streaming untuk Jalur $_activeJalur belum tersedia.';
      });
      return;
    }

    // 1. Resolusi Direct .m3u8 stream dari CDN untuk Native Video Playback (Bypass Cloudflare 100%)
    final directStream = await _resolveDirectStreamUrl(url);

    if (directStream != null && directStream.isNotEmpty) {
      try {
        await _videoController?.dispose();
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(directStream),
          httpHeaders: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14; Mobile; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
            'Referer': _getRefererForUrl(url),
            'Origin': _getRefererForUrl(url),
          },
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

        await controller.initialize();
        if (_isMuted) controller.setVolume(0);
        controller.play();

        _videoController = controller;
        _isWebMode = false;
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        debugPrint('Native VideoPlayer fallback to WebPlayer: $e');
      }
    }

    // 2. Fallback ke Web Engine jika direct m3u8 belum tersedia
    _loadWebPlayer(url);
  }

  void _loadWebPlayer(String url) {
    _isWebMode = true;
    _videoController?.dispose();
    _videoController = null;

    final referer = _getRefererForUrl(url);
    final origin = referer.endsWith('/') ? referer.substring(0, referer.length - 1) : referer;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 14; Mobile; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36');

    // Aktifkan media autoplay & platform permission pada Android WebView
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setOnPlatformPermissionRequest((request) {
        request.grant();
      });
    }

    controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          final target = request.url.toLowerCase();
          // Selalu izinkan domain stream, CDN, dan verifikasi internal Cloudflare
          if (target.contains('cloudflare') ||
              target.contains('challenges') ||
              target.contains('turnstile') ||
              target.contains('domainkqt') ||
              target.contains('scoopnashville') ||
              target.contains('quickscoreboardz') ||
              target.contains('lfastcdn')) {
            return NavigationDecision.navigate;
          }

          // Blokir redirect iklan berbahaya, popup judi, atau skema eksternal yang merusak video
          if (target.contains('8xbet') ||
              target.contains('15.235') ||
              target.contains('profitablerate') ||
              target.contains('popunder') ||
              target.contains('doubleclick') ||
              target.startsWith('intent:') ||
              target.startsWith('market:')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (String url) {
          if (mounted) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        onPageFinished: (String url) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          // Script auto-play, unmute, dan optimasi fullscreen video
          _injectVideoScript(controller);
        },
        onWebResourceError: (WebResourceError error) {
          debugPrint('WebPlayer Error: ${error.description}');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      ),
    );

    controller.loadRequest(
      Uri.parse(url),
      headers: {
        'Referer': referer,
        'Origin': origin,
      },
    );

    _webController = controller;
  }

  void _injectVideoScript(WebViewController controller) {
    controller.runJavaScript('''
      (function() {
        var style = document.createElement('style');
        style.innerHTML = `
          body, html { 
            background: #000 !important; 
            margin: 0 !important; 
            padding: 0 !important; 
            overflow: hidden !important; 
            width: 100vw !important; 
            height: 100vh !important; 
          }
          video { 
            width: 100vw !important; 
            height: 100vh !important; 
            object-fit: contain !important; 
          }
          .ad-box, .banner, [id*="ad"], [class*="ad-"], [class*="popup"], [class*="ads"] { 
            display: none !important; 
          }
        `;
        document.head.appendChild(style);

        function startPlayback() {
          var videos = document.getElementsByTagName('video');
          for (var i = 0; i < videos.length; i++) {
            videos[i].muted = false;
            videos[i].play().catch(function() {
              videos[i].muted = true;
              videos[i].play();
            });
          }
        }
        startPlayback();
        setTimeout(startPlayback, 1000);
        setTimeout(startPlayback, 2500);
      })();
    ''');
  }

  void _switchJalur(int jalurIndex) {
    if (_activeJalur == jalurIndex && !_isLoading) {
      _resetControlsTimer();
      return;
    }
    AdService().triggerPopunder();
    setState(() {
      _activeJalur = jalurIndex;
    });
    _initPlayer();
    _resetControlsTimer();
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

  void _toggleMute() {
    _resetControlsTimer();
    setState(() {
      _isMuted = !_isMuted;
    });

    if (_isWebMode && _webController != null) {
      _webController!.runJavaScript('''
        var videos = document.getElementsByTagName('video');
        for (var i = 0; i < videos.length; i++) {
          videos[i].muted = ${_isMuted ? 'true' : 'false'};
        }
      ''');
    } else {
      _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    }
  }

  Future<void> _openExternalBrowser() async {
    _resetControlsTimer();
    final url = _getActiveStreamUrl();
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _videoController?.dispose();
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
          // Jika kontrol tersembunyi, tombol remote apapun akan memunculkan menu kontrol
          if (!_showControls) {
            _showControlsOverlay();
            return KeyEventResult.handled;
          } else {
            // Jika kontrol sedang aktif, perpanjang waktu timer auto-hide
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
              // 1. Area Video (Klik / Tap di manapun akan menampilkan / menyembunyikan kontrol)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: Center(
                  child: _isWebMode && _webController != null
                      ? WebViewWidget(controller: _webController!)
                      : _isLoading
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: AppColors.primary),
                                const SizedBox(height: 16),
                                Text(
                                  'Menghubungkan ke Jalur $_activeJalur...',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                              ],
                            )
                          : _errorMessage != null
                              ? Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: AppColors.liveRed, size: 48),
                                      const SizedBox(height: 12),
                                      Text(
                                        _errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                      ),
                                      const SizedBox(height: 20),
                                      Wrap(
                                        spacing: 12,
                                        children: [
                                          _buildJalurButton(1, 'Jalur 1 (HD)'),
                                          _buildJalurButton(2, 'Jalur 2 (Fast)'),
                                          _buildJalurButton(3, 'Jalur 3 (Backup)'),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : _videoController != null && _videoController!.value.isInitialized
                                  ? FittedBox(
                                      fit: _videoFit,
                                      child: SizedBox(
                                        width: _videoController!.value.size.width,
                                        height: _videoController!.value.size.height,
                                        child: VideoPlayer(_videoController!),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                ),
              ),

              // 2. Sleek Progress Bar saat memuat siaran
              if (_isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    color: AppColors.primary,
                    backgroundColor: Colors.transparent,
                    minHeight: 3,
                  ),
                ),

              // 3. Top Bar Navigation & Actions (Saweria, Sound, Reload, Share, Browser, Fullscreen)
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
                          isTvOrWide ? 24 : 12,
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

                            // Info Judul & Liga Pertandingan
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${match.homeTeam} vs ${match.awayTeam}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTvOrWide ? 16 : 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    match.league,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.cyanAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Badge Status Live
                            LiveBadge(
                              isLive: match.isLive,
                              text: match.isLive ? 'LIVE' : 'UPCOMING',
                            ),
                            const SizedBox(width: 8),

                            // 1. Tombol Donasi Saweria (Clickable & Focusable)
                            TvFocusableButton(
                              onTap: () {
                                _resetControlsTimer();
                                AdService().openSaweria();
                              },
                              borderRadius: BorderRadius.circular(16),
                              focusedBorderColor: const Color(0xFFFF9800),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
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
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF9800).withValues(alpha: 0.45),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.volunteer_activism_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Saweria',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 2. Tombol Sound / Mute (Clickable & Focusable)
                            TvFocusableButton(
                              onTap: _toggleMute,
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(8),
                              tooltip: _isMuted ? 'Nyalakan Suara' : 'Matikan Suara',
                              child: Icon(
                                _isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: _isMuted
                                    ? AppColors.liveRed
                                    : AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 3. Tombol Reload / Refresh (Clickable & Focusable)
                            TvFocusableButton(
                              onTap: () {
                                _resetControlsTimer();
                                _initPlayer();
                              },
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(8),
                              tooltip: 'Muat Ulang Siaran',
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 4. Tombol Bagikan / Share (Clickable & Focusable)
                            TvFocusableButton(
                              onTap: _shareMatch,
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(8),
                              tooltip: 'Bagikan Siaran Ini',
                              child: const Icon(
                                Icons.share_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 5. Tombol Transmisi / Browser Eksternal (Clickable & Focusable)
                            TvFocusableButton(
                              onTap: _openExternalBrowser,
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(8),
                              tooltip: 'Buka di Browser Eksternal',
                              child: const Icon(
                                Icons.open_in_browser_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 6. Tombol Fullscreen / Sembunyikan Menu (Clickable & Focusable)
                            TvFocusableButton(
                              onTap: () {
                                setState(() {
                                  _showControls = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(8),
                              tooltip: 'Layar Penuh (Sembunyikan Menu)',
                              child: const Icon(
                                Icons.fullscreen_exit_rounded,
                                color: AppColors.cyanAccent,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // 4. Bottom Bar: Jalur Server Switcher (Jalur 1 / Jalur 2 / Jalur 3)
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
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
                        // Header Server
                        const Row(
                          children: [
                            Icon(Icons.dns_rounded, color: AppColors.cyanAccent, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'PILIH JALUR SERVER STREAMING:',
                              style: TextStyle(
                                color: AppColors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Tombol Jalur 1, Jalur 2, Jalur 3
                        Row(
                          children: [
                            Expanded(child: _buildJalurButton(1, 'Jalur 1 (HD)')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildJalurButton(2, 'Jalur 2 (Fast)')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildJalurButton(3, 'Jalur 3 (Backup)')),
                          ],
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

  Widget _buildJalurButton(int index, String title) {
    final isSelected = _activeJalur == index;

    return TvFocusableButton(
      onTap: () => _switchJalur(index),
      borderRadius: BorderRadius.circular(12),
      focusedBorderColor: AppColors.cyanAccent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
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
                  )
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
}
