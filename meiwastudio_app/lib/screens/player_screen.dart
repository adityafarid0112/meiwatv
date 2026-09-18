import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/movie_model.dart';
import '../services/remote_config_service.dart';
import '../widgets/tv_focusable_widget.dart';

class PlayerScreen extends StatefulWidget {
  final Movie movie;

  const PlayerScreen({super.key, required this.movie});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _showControls = true;
  final RemoteConfigService _config = RemoteConfigService();

  @override
  void initState() {
    super.initState();
    _initWakelockAndOrientation();
    _initWebView();
  }

  Future<void> _initWakelockAndOrientation() async {
    // 1. Keep screen alive (Never sleep / no screensaver during movie)
    try {
      await WakelockPlus.enable();
      debugPrint('[Player] Wakelock enabled successfully (Screen will stay awake).');
    } catch (e) {
      debugPrint('[Player] Wakelock error: $e');
    }

    // 2. Fullscreen immersive mode & Landscape orientation
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initWebView() {
    final rawUrl = widget.movie.embedUrl.isNotEmpty
        ? widget.movie.embedUrl
        : (_config.activeBaseUrl + widget.movie.url);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 12; Android TV Build/STTE.220623.001) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (progress >= 85 && _isLoading) {
              setState(() => _isLoading = false);
            }
          },
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            // Inject script to auto-dismiss common overlay ads & expand player
            _controller.runJavaScript('''
              (function() {
                var ads = document.querySelectorAll('#adContainer, .ads, [class*="ad-"], [id*="ad-"], .popunder, #skipAds');
                ads.forEach(function(el) { if (el) el.remove(); });
                var player = document.getElementById('main-player') || document.querySelector('iframe') || document.querySelector('video');
                if (player) {
                  player.style.width = '100vw';
                  player.style.height = '100vh';
                  player.style.position = 'fixed';
                  player.style.top = '0';
                  player.style.left = '0';
                  player.style.zIndex = '999999';
                }
              })();
            ''');
          },
          onNavigationRequest: (request) {
            final targetUrl = request.url.toLowerCase();
            
            // Check against AdBlock patterns
            for (final pattern in _config.adBlockPatterns) {
              if (targetUrl.contains(pattern)) {
                debugPrint('[Player] Blocked Ad Request: ${request.url}');
                return NavigationDecision.prevent;
              }
            }

            // Block external intent / app store redirects
            if (targetUrl.startsWith('intent://') ||
                targetUrl.startsWith('market://') ||
                targetUrl.startsWith('tg://') ||
                targetUrl.startsWith('whatsapp://') ||
                targetUrl.contains('shopee') ||
                targetUrl.contains('lazada') ||
                targetUrl.contains('tokopedia')) {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(rawUrl));
  }

  @override
  void dispose() {
    // Release wakelock & restore UI orientations
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video Web Player
            WebViewWidget(controller: _controller),

            // Loading Indicator
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat Player: ${widget.movie.title}',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mengaktifkan fitur anti-iklan & layar aktif...',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            // Floating Top Bar Overlay Controls
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      TVFocusableWidget(
                        autofocus: true,
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Kembali',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.movie.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${widget.movie.quality} • Subtitle Indonesia • Screen Awake Active ⚡',
                              style: TextStyle(
                                color: const Color(0xFFA855F7).withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TVFocusableWidget(
                        onTap: () {
                          _controller.reload();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text('Reload', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
