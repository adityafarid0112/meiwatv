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
  Timer? _controlsTimer;
  final RemoteConfigService _config = RemoteConfigService();
  final LK21ScraperService _scraper = LK21ScraperService();
  
  late SeriesEpisode? _currentEpisode;
  List<SeriesEpisode> _episodes = [];
  String _activeEmbedUrl = '';

  @override
  void initState() {
    super.initState();
    _episodes = List.from(widget.movie.episodes);
    _currentEpisode = widget.initialEpisode ??
        (_episodes.isNotEmpty ? _episodes.first : null);
    _initWakelockAndOrientation();
    _setupWebViewController();
    _loadSelectedEpisode();
    _startControlsTimer();

    // If episodes list is empty and it's a drama/series, fetch in background
    if (_episodes.isEmpty && (widget.movie.isSeries || widget.movie.url.contains('/series/') || widget.movie.url.contains('nontondrama'))) {
      _fetchEpisodesBackground();
    }
  }

  Future<void> _fetchEpisodesBackground() async {
    try {
      final detail = await _scraper.fetchMovieDetail(widget.movie);
      if (mounted && detail.episodes.isNotEmpty) {
        setState(() {
          _episodes = detail.episodes;
          _currentEpisode ??= _episodes.first;
        });
      }
    } catch (e) {
      debugPrint('[Player] Error fetching episodes in background: $e');
    }
  }

  Future<void> _initWakelockAndOrientation() async {
    try {
      await WakelockPlus.enable();
      debugPrint('[Player] Wakelock enabled successfully (Screen will stay awake).');
    } catch (e) {
      debugPrint('[Player] Wakelock error: $e');
    }

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  void _showControlsOverlay() {
    setState(() => _showControls = true);
    _startControlsTimer();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
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
      ..addJavaScriptChannel(
        'FlutterPlayer',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'toggleControls') {
            _toggleControls();
          } else if (message.message == 'showControls') {
            _showControlsOverlay();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (progress >= 60 && _isLoading) {
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
                
                // Auto click play if poster exists
                setTimeout(function() {
                  var playBtn = document.querySelector('.jw-display-icon-container, .vjs-big-play-button, .play-button, .play-btn, [class*="play"], button.play');
                  if (playBtn) playBtn.click();
                }, 1000);
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
        if (_episodes.isEmpty && detail.episodes.isNotEmpty) {
          _episodes = detail.episodes;
        }
      }
    }

    if (embedUrl.isEmpty) {
      embedUrl = widget.movie.url;
    }

    _activeEmbedUrl = embedUrl;

    // Build the clean, isolated HTML container
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
            z-index: 1;
          }
        </style>
      </head>
      <body>
        <iframe
          id="mainPlayerIframe"
          src="$_activeEmbedUrl"
          scrolling="no"
          frameborder="0"
          allowfullscreen="true"
          webkitallowfullscreen="true"
          mozallowfullscreen="true"
          allow="screen-wake-lock; autoplay; fullscreen; picture-in-picture">
        </iframe>
        <script>
          window.tvControl = function(action) {
            try {
              var v = document.querySelector('video');
              if (v) {
                if (action === 'togglePlay') {
                  if (v.paused) v.play(); else v.pause();
                }
              } else {
                var playBtn = document.querySelector('.jw-display-icon-container, .vjs-big-play-button, .play-button, .play-btn, [class*="play"], button.play');
                if (playBtn) playBtn.click();
              }
              var cx = window.innerWidth / 2;
              var cy = window.innerHeight / 2;
              var el = document.elementFromPoint(cx, cy);
              if (el) {
                el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, clientX: cx, clientY: cy }));
                el.click();
              }
            } catch(e) {}
          };

          window.addEventListener('click', function() {
            if (window.FlutterPlayer) {
              FlutterPlayer.postMessage('toggleControls');
            }
          });
        </script>
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
    });
    _startControlsTimer();
    _loadSelectedEpisode();
  }

  void _playNextEpisode() {
    if (_episodes.isEmpty || _currentEpisode == null) return;
    final currentIndex = _episodes.indexWhere((e) => e.episodeNo == _currentEpisode!.episodeNo && e.season == _currentEpisode!.season);
    if (currentIndex != -1 && currentIndex < _episodes.length - 1) {
      _switchEpisode(_episodes[currentIndex + 1]);
    }
  }

  void _playPreviousEpisode() {
    if (_episodes.isEmpty || _currentEpisode == null) return;
    final currentIndex = _episodes.indexWhere((e) => e.episodeNo == _currentEpisode!.episodeNo && e.season == _currentEpisode!.season);
    if (currentIndex > 0) {
      _switchEpisode(_episodes[currentIndex - 1]);
    }
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
    final isSeries = widget.movie.isSeries || _episodes.isNotEmpty;

    return FocusScope(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        final key = event.logicalKey;

        // If controls are hidden, any navigation/select key will open controls and make icons selectable!
        if (!_showControls) {
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.arrowDown ||
              key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.mediaPlayPause) {
            _showControlsOverlay();
            _controller.runJavaScript("if (window.tvControl) window.tvControl('togglePlay');");
            return KeyEventResult.handled;
          }
        } else {
          // If controls are open, reset timer on each D-pad press so menu doesn't disappear
          _startControlsTimer();

          if (key == LogicalKeyboardKey.escape) {
            setState(() => _showControls = false);
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: PopScope(
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

                // 3. Persistent Mini Floating Episode Pill (Visible when controls hidden for series)
                if (!_showControls && isSeries && _episodes.isNotEmpty)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: TVFocusableWidget(
                      onTap: _toggleControls,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.playlist_play_rounded, color: Color(0xFFC084FC), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _currentEpisode != null ? 'EPS ${_currentEpisode!.episodeNo}' : 'Episode',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 4. Floating Top Bar Overlay Controls & In-Player Episode Selector
                if (_showControls)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.95),
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Action Row
                          Row(
                            children: [
                              // Back Button (D-Pad Focusable with Glow)
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
                                          ? '${_currentEpisode!.title} • Layar Selalu Hidup ⚡'
                                          : '${widget.movie.quality} • Subtitle Indonesia • Layar Selalu Hidup ⚡',
                                      style: const TextStyle(
                                        color: Color(0xFFC084FC),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quick Prev / Next for Series (D-Pad Focusable)
                              if (isSeries && _episodes.length > 1) ...[
                                TVFocusableWidget(
                                  onTap: _playPreviousEpisode,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    child: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TVFocusableWidget(
                                  onTap: _playNextEpisode,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],

                              // Reload Button (D-Pad Focusable)
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

                          // Direct In-Player Episode Selector Row (D-Pad Focusable Chips)
                          if (isSeries && _episodes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.playlist_play_rounded, color: Color(0xFFA855F7), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Daftar Episode (${_episodes.length} Episode Tersedia):',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 38,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _episodes.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final ep = _episodes[index];
                                  final isCurrent = _currentEpisode?.episodeNo == ep.episodeNo &&
                                                    _currentEpisode?.season == ep.season;

                                  return TVFocusableWidget(
                                    onTap: () => _switchEpisode(ep),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: isCurrent
                                            ? const LinearGradient(
                                                colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                                              )
                                            : null,
                                        color: isCurrent ? null : Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.2),
                                          width: isCurrent ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isCurrent) ...[
                                            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            'EPS ${ep.episodeNo}',
                                            style: TextStyle(
                                              color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.9),
                                              fontSize: 12,
                                              fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
