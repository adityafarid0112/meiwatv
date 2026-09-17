import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
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
  bool _isWebMode = true;
  bool _isMuted = false;
  String? _errorMessage;
  bool _showControls = true;
  final BoxFit _videoFit = BoxFit.contain;

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
      headers: const {
        'Referer': 'https://tft-forests.org/',
      },
    );

    _webController = controller;
  }

  void _injectVideoScript(WebViewController controller) {
    controller.runJavaScript('''
      (function() {
        // Hilangkan elemen pengganggu / overlay luar
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

        // Cari dan putar video secara otomatis
        function startPlayback() {
          var videos = document.getElementsByTagName('video');
          for (var i = 0; i < videos.length; i++) {
            videos[i].muted = false;
            videos[i].play().catch(function() {
              // Jika browser menolak autoplay dengan suara, mute lalu play
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
      return;
    }
    AdService().triggerPopunder();
    setState(() {
      _activeJalur = jalurIndex;
    });
    _initPlayer();
  }

  void _shareMatch() {
    final match = widget.match;
    SharePlus.instance.share(
      ShareParams(
        text:
            'Ayo nonton siaran langsung ${match.title} (${match.league}) gratis di aplikasi MeiwaTV!\n\nLink Dukungan: https://saweria.co/meiwatv',
        subject: 'Nonton ${match.title} di MeiwaTV',
      ),
    );
  }

  void _toggleMute() {
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final topWidth = constraints.maxWidth;
                      final isTvOrWide = topWidth > 700;
                      final isCompact = topWidth < 550;

                      return Container(
                        padding: EdgeInsets.fromLTRB(
                          isTvOrWide ? 24 : 12,
                          isTvOrWide ? 22 : 8,
                          isTvOrWide ? 24 : 12,
                          10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.94),
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
                              padding: const EdgeInsets.all(6),
                              tooltip: 'Kembali',
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
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
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCompact ? 13 : 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    match.league,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.cyanAccent,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isCompact) ...[
                              LiveBadge(
                                isLive: match.isLive,
                                text: match.isLive ? 'LIVE' : 'UPCOMING',
                              ),
                              const SizedBox(width: 6),
                            ],
                            // Tombol Donasi Saweria (Focusable for TV & Mobile)
                            TvFocusableButton(
                              onTap: () => AdService().openSaweria(),
                              borderRadius: BorderRadius.circular(16),
                              focusedBorderColor: const Color(0xFFFF9800),
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
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF9800,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.volunteer_activism_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    SizedBox(width: 3),
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
                            const SizedBox(width: 4),
                            // Tombol Audio
                            TvFocusableButton(
                              onTap: _toggleMute,
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(6),
                              tooltip: _isMuted ? 'Nyalakan Suara' : 'Matikan Suara',
                              child: Icon(
                                _isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: _isMuted
                                    ? AppColors.liveRed
                                    : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Tombol Muat Ulang Siaran
                            TvFocusableButton(
                              onTap: () => _initPlayer(),
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(6),
                              tooltip: 'Muat Ulang Siaran',
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            if (!isCompact) ...[
                              const SizedBox(width: 4),
                              // Tombol Bagikan / Share
                              TvFocusableButton(
                                onTap: _shareMatch,
                                borderRadius: BorderRadius.circular(12),
                                padding: const EdgeInsets.all(6),
                                tooltip: 'Bagikan Siaran Ini',
                                child: const Icon(
                                  Icons.share_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Tombol Browser Eksternal
                              TvFocusableButton(
                                onTap: _openExternalBrowser,
                                borderRadius: BorderRadius.circular(12),
                                padding: const EdgeInsets.all(6),
                                tooltip: 'Buka di Browser Eksternal',
                                child: const Icon(
                                  Icons.open_in_browser_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ] else ...[
                              // Popup menu for extra options on mobile portrait
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: AppColors.surfaceElevated,
                                onSelected: (value) {
                                  if (value == 'share') _shareMatch();
                                  if (value == 'browser') _openExternalBrowser();
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.share_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Bagikan Siaran'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'browser',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.open_in_browser_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Buka di Browser'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(width: 4),
                            // Tombol Layar Penuh (Tunggal & Konsisten)
                            TvFocusableButton(
                              onTap: () => setState(() => _showControls = false),
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.all(6),
                              tooltip: 'Layar Penuh (Sembunyikan Menu)',
                              child: const Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Floating Menu Button When Controls are Hidden
              if (!_showControls)
                Positioned(
                  top: 20,
                  left: 20,
                  child: TvFocusableButton(
                    onTap: () => setState(() => _showControls = true),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primary, width: 1.2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, color: AppColors.cyanAccent, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Menu / Server',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

    return TvFocusableButton(
      onTap: () => _switchJalur(index),
      borderRadius: BorderRadius.circular(10),
      focusedBorderColor: AppColors.cyanAccent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
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
