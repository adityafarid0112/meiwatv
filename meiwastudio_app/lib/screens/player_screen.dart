import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/movie_model.dart';
import '../services/lk21_scraper_service.dart';
import '../services/remote_config_service.dart';
import '../widgets/tv_focusable_widget.dart';

class PlayerScreen extends StatefulWidget {
  final Movie movie;
  final SeriesEpisode? initialEpisode;

  const PlayerScreen({
    super.key,
    required this.movie,
    this.initialEpisode,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _showControls = true;
  bool _showEpisodePanel = false;
  Timer? _controlsTimer;
  final RemoteConfigService _config = RemoteConfigService();
  final LK21ScraperService _scraper = LK21ScraperService();
  
  late SeriesEpisode? _currentEpisode;
  String _activeEmbedUrl = '';

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.initialEpisode ??
        (widget.movie.episodes.isNotEmpty ? widget.movie.episodes.first : null);
    _initWakelockAndOrientation();
    _setupWebViewController();
    _loadSelectedEpisode();
    _startControlsTimer();
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

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && !_showEpisodePanel) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (!_showControls) _showEpisodePanel = false;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _setupWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 12; Android TV Build/STTE.220623.001) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (progress >= 70 && _isLoading) {
              setState(() => _isLoading = false);
            }
          },
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _controller.runJavaScript('''
              (function() {
                var ads = document.querySelectorAll('#adContainer, .ads, [class*="ad-"], [id*="ad-"], .popunder, #skipAds');
                ads.forEach(function(el) { if (el) el.remove(); });
              })();
            ''');
          },
          onNavigationRequest: (request) {
            final targetUrl = request.url.toLowerCase();
            
            // Allow primary player and video stream hosts
            if (targetUrl.contains('videonode.de') ||
                targetUrl.contains('playcdn.de') ||
                targetUrl.contains('lk21') ||
                targetUrl.contains('nontondrama') ||
                targetUrl.contains('about:blank') ||
                targetUrl.contains('blob:') ||
                targetUrl.contains('.m3u8') ||
                targetUrl.contains('.mp4')) {
              return NavigationDecision.navigate;
            }

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
                targetUrl.contains('tokopedia') ||
                targetUrl.contains('play.google.com')) {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _loadSelectedEpisode() async {
    setState(() => _isLoading = true);

    String embedUrl = '';
    if (_currentEpisode != null) {
      if (_currentEpisode!.embedUrl.isNotEmpty && _currentEpisode!.embedUrl.contains('videonode')) {
        embedUrl = _currentEpisode!.embedUrl;
      } else {
        embedUrl = await _scraper.fetchEpisodeEmbedUrl(_currentEpisode!.url);
      }
    } else {
      if (widget.movie.embedUrl.isNotEmpty && widget.movie.embedUrl.contains('videonode')) {
        embedUrl = widget.movie.embedUrl;
      } else {
        final detail = await _scraper.fetchMovieDetail(widget.movie);
        embedUrl = detail.embedUrl;
      }
    }

    if (embedUrl.isEmpty) {
      embedUrl = widget.movie.url;
    }

    _activeEmbedUrl = embedUrl;

    // Build the isolated HTML container with an iframe
    // This CRITICALLY ensures window.self !== window.top so anti-framing redirects NEVER trigger!
    final htmlContent = '''
      <!DOCTYPE html>
      <html lang="id">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <title>${widget.movie.title}</title>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          html, body {
            width: 100vw;
            height: 100vh;
            background-color: #000000;
            overflow: hidden;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          iframe {
            width: 100vw;
            height: 100vh;
            border: none;
            position: fixed;
            top: 0;
            left: 0;
            z-index: 999999;
          }
        </style>
      </head>
      <body>
        <iframe
          src="$_activeEmbedUrl"
          scrolling="no"
          frameborder="0"
          allowfullscreen="true"
          webkitallowfullscreen="true"
          mozallowfullscreen="true"
          allow="screen-wake-lock; autoplay; fullscreen; picture-in-picture">
        </iframe>
      </body>
      </html>
    ''';

    _controller.loadHtmlString(
      htmlContent,
      baseUrl: _config.activeBaseUrl,
    );
  }

  void _switchEpisode(SeriesEpisode ep) {
    if (_currentEpisode?.episodeNo == ep.episodeNo && _currentEpisode?.season == ep.season) {
      return;
    }
    setState(() {
      _currentEpisode = ep;
      _showEpisodePanel = false;
    });
    _loadSelectedEpisode();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
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
    final episodes = widget.movie.episodes;
    final isSeries = widget.movie.isSeries || episodes.isNotEmpty;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            children: [
              // 1. Direct Web Player (Isolated inside local HTML iframe)
              WebViewWidget(controller: _controller),

              // 2. Loading Spinner
              if (_isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.9),
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
                          _currentEpisode != null
                              ? 'Memuat ${widget.movie.title} - ${_currentEpisode!.title}'
                              : 'Menghubungkan Player: ${widget.movie.title}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Player In-App Aktif • Anti-Iklan • Layar Selalu Hidup ⚡',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Floating Top Bar Overlay Controls
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
                          Colors.black.withValues(alpha: 0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        // Back Button
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
                        // Title & Episode Info
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
                                _currentEpisode != null
                                    ? '${_currentEpisode!.title} • Full HD • Screen Awake Active ⚡'
                                    : '${widget.movie.quality} • Subtitle Indonesia • Screen Awake Active ⚡',
                                style: const TextStyle(
                                  color: Color(0xFFC084FC),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Episode List Button (for Drama / Series)
                        if (isSeries && episodes.isNotEmpty) ...[
                          TVFocusableWidget(
                            onTap: () {
                              setState(() => _showEpisodePanel = !_showEpisodePanel);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _showEpisodePanel ? const Color(0xFFA855F7) : Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Episode (${episodes.length})',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Reload Button
                        TVFocusableWidget(
                          onTap: _loadSelectedEpisode,
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

              // 4. In-Player Side Episode Selector Panel (Matching Screenshot 2)
              if (_showEpisodePanel && isSeries && episodes.isNotEmpty)
                Positioned(
                  top: 60,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E131F).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.movie_filter_rounded, color: Color(0xFFA855F7), size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'PILIH EPISODE',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _showEpisodePanel = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        // Grid of Episode numbers
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.3,
                            ),
                            itemCount: episodes.length,
                            itemBuilder: (context, index) {
                              final ep = episodes[index];
                              final isCurrent = _currentEpisode?.episodeNo == ep.episodeNo &&
                                                _currentEpisode?.season == ep.season;

                              return TVFocusableWidget(
                                onTap: () => _switchEpisode(ep),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? const Color(0xFFA855F7)
                                        : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCurrent ? const Color(0xFFA855F7) : Colors.white12,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${ep.episodeNo}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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
}
