import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../models/match_model.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/live_badge.dart';

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
  bool _isWebMode = true;
  bool _isMuted = false;
  String? _errorMessage;
  bool _showControls = true;
  BoxFit _videoFit = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    // Prioritaskan Jalur 1, lalu 2, lalu 3
    if (widget.match.streamJalur1.isNotEmpty) {
      _activeJalur = 1;
    } else if (widget.match.streamJalur2.isNotEmpty) {
      _activeJalur = 2;
    } else {
      _activeJalur = 3;
    }
    _initPlayer();
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

  bool _isDirectVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.m3u8') || lower.endsWith('.mp4') || (lower.endsWith('.flv') && !lower.contains('/ajax/chanel/'));
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

    // Jika URL adalah direct stream video file
    if (_isDirectVideoUrl(url)) {
      _isWebMode = false;
      try {
        await _videoController?.dispose();
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(url),
          httpHeaders: const {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://xlz.domainkqt.cc/',
            'Origin': 'https://xlz.domainkqt.cc',
          },
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

        await _videoController!.initialize();
        _videoController!.play();
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        _loadWebPlayer(url);
      }
    } else {
      // Embed URL -> Mainkan via High Performance In-App Web Engine
      _loadWebPlayer(url);
    }
  }

  void _loadWebPlayer(String url) {
    _isWebMode = true;
    _videoController?.dispose();
    _videoController = null;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

    // Aktifkan media autoplay pada Android WebView
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
          // Blokir redirect iklan, popup judi, atau skema eksternal yang merusak video
          if (target.contains('8xbet') ||
              target.contains('15.235') ||
              target.contains('profitablerate') ||
              target.contains('googleads') ||
              target.contains('doubleclick') ||
              target.contains('pop') ||
              target.startsWith('intent:') ||
              target.startsWith('market:')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (String url) {
          // Jangan tutupi layar penuh saat memuat subframe
        },
        onPageFinished: (String url) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          // Inject custom styling & auto-play script aman (tanpa pause toggle)
          _webController?.runJavaScript('''
            (function() {
              // 1. Sembunyikan semua iklan & banner odds tanpa merusak layout player
              var style = document.createElement('style');
              style.innerHTML = `
                .popup-ads-banner, .a-v9, .odds-button, .odds-button2, a[href*="8xbet"], a[href*="15.235"], .banner-bottom, .banner-bottom-11, .countdown, .show-ads-banner, #player .popup-ads-banner {
                  display: none !important;
                  visibility: hidden !important;
                  opacity: 0 !important;
                  pointer-events: none !important;
                  height: 0 !important;
                }
                html, body {
                  background: #000 !important;
                  margin: 0 !important;
                  padding: 0 !important;
                  overflow: hidden !important;
                  width: 100% !important;
                  height: 100% !important;
                }
                #player, .dplayer {
                  position: absolute !important;
                  top: 0 !important;
                  left: 0 !important;
                  width: 100% !important;
                  height: 100% !important;
                  background: #000 !important;
                }
                video {
                  width: 100% !important;
                  height: 100% !important;
                  object-fit: contain !important;
                }
              `;
              document.head.appendChild(style);

              // 2. Play video secara aman jika sedang pause
              function startVideo() {
                var v = document.querySelector('video');
                if (v && v.paused) {
                  v.play().catch(function(){});
                }
              }
              startVideo();
              setTimeout(startVideo, 500);
              setTimeout(startVideo, 1200);
              setTimeout(startVideo, 2500);
            })();
          ''');
        },
        onWebResourceError: (WebResourceError error) {
          // Abaikan resource error minor dari script iklan pihak ketiga
        },
      ),
    );

    controller.loadRequest(
      Uri.parse(url),
      headers: const {
        'Referer': 'https://tft-forests.org/',
      },
    );

    _webController = controller;
  }

  void _switchJalur(int jalurIndex) {
    if (_activeJalur == jalurIndex && !_isLoading) {
      return;
    }
    setState(() {
      _activeJalur = jalurIndex;
    });
    _initPlayer();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isWebMode) {
      _webController?.runJavaScript('''
        (function() {
          var v = document.querySelector('video');
          if (v) {
            v.muted = ${_isMuted ? 'true' : 'false'};
            if (v.paused) v.play().catch(function(){});
          }
          if (typeof dp !== 'undefined' && dp.video) {
            dp.video.muted = ${_isMuted ? 'true' : 'false'};
          }
        })();
      ''');
    } else {
      _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    }
  }

  void _toggleAspectRatio() {
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

  Future<void> _openExternalBrowser() async {
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
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (_activeJalur > 1) _switchJalur(_activeJalur - 1);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (_activeJalur < 3) _switchJalur(_activeJalur + 1);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            if (_videoController != null && _videoController!.value.isInitialized) {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
              setState(() {});
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Video Display Area (Web or Native Video)
              Center(
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

              // Non-blocking sleek progress bar at the very top
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

              // Top Bar Navigation & Info Overlay
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
                          Colors.black.withValues(alpha: 0.88),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${match.homeTeam} vs ${match.awayTeam}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                match.league,
                                style: const TextStyle(
                                  color: AppColors.cyanAccent,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LiveBadge(isLive: match.isLive, text: match.isLive ? 'LIVE' : 'UPCOMING'),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Dukung Kami via Saweria',
                          icon: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFFF9800)),
                          onPressed: () => AdService().openSaweria(),
                        ),
                        IconButton(
                          tooltip: _isMuted ? 'Nyalakan Suara' : 'Matikan Suara',
                          icon: Icon(
                            _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: _isMuted ? AppColors.liveRed : AppColors.primary,
                          ),
                          onPressed: _toggleMute,
                        ),
                        IconButton(
                          tooltip: 'Rasio Layar',
                          icon: const Icon(Icons.aspect_ratio_rounded, color: AppColors.cyanAccent),
                          onPressed: _toggleAspectRatio,
                        ),
                        IconButton(
                          tooltip: 'Buka di Browser Eksternal',
                          icon: const Icon(Icons.open_in_browser_rounded, color: AppColors.primary),
                          onPressed: _openExternalBrowser,
                        ),
                        IconButton(
                          tooltip: 'Muat Ulang Siaran',
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.cyanAccent),
                          onPressed: () => _initPlayer(),
                        ),
                        IconButton(
                          tooltip: 'Sembunyikan Menu',
                          icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                          onPressed: () => setState(() => _showControls = false),
                        ),
                      ],
                    ),
                  ),
                ),

              // Floating Menu Button When Controls are Hidden
              if (!_showControls)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => setState(() => _showControls = true),
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Menu / Server',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Bottom Bar: Jalur Switcher Panel (Jalur 1 / Jalur 2 / Jalur 3)
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.94),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Server Selector Header
                        const Row(
                          children: [
                            Icon(Icons.dns_rounded, color: AppColors.primary, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'PILIH JALUR SERVER STREAMING:',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Jalur 1, Jalur 2, Jalur 3 Switch Buttons
                        Row(
                          children: [
                            Expanded(child: _buildJalurButton(1, 'Jalur 1 (HD)')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildJalurButton(2, 'Jalur 2 (Fast)')),
                            const SizedBox(width: 8),
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

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          _switchJalur(index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
          foregroundColor: isSelected ? Colors.black : Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => _switchJalur(index),
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
