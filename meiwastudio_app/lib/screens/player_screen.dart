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

  // HUD Toast State
  String? _hudText;
  IconData? _hudIcon;
  Timer? _hudTimer;

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

  void _showHud(String text, IconData icon) {
    _hudTimer?.cancel();
    setState(() {
      _hudText = text;
      _hudIcon = icon;
    });
    _hudTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _hudText = null;
          _hudIcon = null;
        });
      }
    });
  }

  // --- TV REMOTE VIDEO ACTIONS ---

  void _tvPlayPause() {
    _controller.runJavaScript("if (window.tvControl) window.tvControl('togglePlay');");
    _showHud('Play / Pause', Icons.play_circle_fill_rounded);
    if (_showControls) _startControlsTimer();
  }

  void _tvSeek(int seconds) {
    _controller.runJavaScript("if (window.tvControl) window.tvControl('seek', $seconds);");
    if (seconds > 0) {
      _showHud('+$seconds Detik', Icons.fast_forward_rounded);
    } else {
      _showHud('$seconds Detik', Icons.fast_rewind_rounded);
    }
    if (_showControls) _startControlsTimer();
  }

  void _tvVolume(double delta) {
    _controller.runJavaScript("if (window.tvControl) window.tvControl('volume', $delta);");
    if (delta > 0) {
      _showHud('Volume +', Icons.volume_up_rounded);
    } else {
      _showHud('Volume -', Icons.volume_down_rounded);
    }
    if (_showControls) _startControlsTimer();
  }

  void _tvToggleMute() {
    _controller.runJavaScript("if (window.tvControl) window.tvControl('toggleMute');");
    _showHud('Mute / Suara', Icons.volume_off_rounded);
    if (_showControls) _startControlsTimer();
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
                // Remove ads
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

    // Build the isolated HTML container with TV control bridge
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
          // TV Remote Command Bridge
          window.tvControl = function(action, val) {
            try {
              function getAllVideos(root) {
                var res = [];
                try {
                  var vids = root.querySelectorAll('video');
                  for (var i = 0; i < vids.length; i++) res.push(vids[i]);
                  var ifrs = root.querySelectorAll('iframe');
                  for (var j = 0; j < ifrs.length; j++) {
                    try {
                      var cw = ifrs[j].contentWindow;
                      if (cw && cw.document) res = res.concat(getAllVideos(cw.document));
                    } catch(e) {}
                  }
                } catch(e) {}
                return res;
              }

              var videos = getAllVideos(document);

              if (action === 'togglePlay' || action === 'play' || action === 'pause') {
                if (videos.length > 0) {
                  var v = videos[0];
                  if (action === 'play') { v.play(); }
                  else if (action === 'pause') { v.pause(); }
                  else {
                    if (v.paused) v.play(); else v.pause();
                  }
                }
                
                // Click play buttons in DOM
                var playBtns = document.querySelectorAll('.jw-display-icon-container, .vjs-big-play-button, .play-button, .play-btn, [class*="play"], button, #play');
                playBtns.forEach(function(b) { try { b.click(); } catch(e){} });

                // Dispatch postMessage to iframe
                var ifrs = document.querySelectorAll('iframe');
                ifrs.forEach(function(ifr) {
                  try {
                    ifr.contentWindow.postMessage({ action: action, command: action }, '*');
                    ifr.contentWindow.postMessage('togglePlay', '*');
                    ifr.contentWindow.postMessage(JSON.stringify({ event: action, type: action }), '*');
                  } catch(e) {}
                });

                // Simulate central click event
                var cx = window.innerWidth / 2;
                var cy = window.innerHeight / 2;
                var el = document.elementFromPoint(cx, cy);
                if (el) {
                  try {
                    el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, clientX: cx, clientY: cy }));
                    el.click();
                  } catch(e){}
                }
              } else if (action === 'seek') {
                var offset = Number(val) || 10;
                if (videos.length > 0) {
                  var v = videos[0];
                  v.currentTime = Math.max(0, Math.min(v.duration || 999999, (v.currentTime || 0) + offset));
                }
                var ifrs = document.querySelectorAll('iframe');
                ifrs.forEach(function(ifr) {
                  try {
                    ifr.contentWindow.postMessage({ action: 'seek', offset: offset }, '*');
                    ifr.contentWindow.postMessage(JSON.stringify({ type: 'seek', offset: offset }), '*');
                  } catch(e) {}
                });
              } else if (action === 'volume') {
                var delta = Number(val) || 0.1;
                if (videos.length > 0) {
                  var v = videos[0];
                  v.muted = false;
                  v.volume = Math.max(0, Math.min(1, (v.volume || 1.0) + delta));
                }
              } else if (action === 'toggleMute') {
                if (videos.length > 0) {
                  var v = videos[0];
                  v.muted = !v.muted;
                }
              }
            } catch(err) {
              console.log('[TVControl Bridge Error]', err);
            }
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
    _hudTimer?.cancel();
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

        // 1. Center / OK / Enter / Space / Media PlayPause
        if (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space ||
            key == LogicalKeyboardKey.mediaPlayPause ||
            key == LogicalKeyboardKey.mediaPlay ||
            key == LogicalKeyboardKey.mediaPause) {
          if (!_showControls) {
            _tvPlayPause();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }

        // 2. D-Pad Left / Fast Rewind (-10s)
        if (key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.mediaRewind) {
          if (!_showControls) {
            _tvSeek(-10);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }

        // 3. D-Pad Right / Fast Forward (+10s)
        if (key == LogicalKeyboardKey.arrowRight ||
            key == LogicalKeyboardKey.mediaFastForward) {
          if (!_showControls) {
            _tvSeek(10);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }

        // 4. D-Pad Up (Show controls / Volume +)
        if (key == LogicalKeyboardKey.arrowUp) {
          if (!_showControls) {
            _showControlsOverlay();
            _tvVolume(0.1);
            return KeyEventResult.handled;
          }
          _startControlsTimer();
          return KeyEventResult.ignored;
        }

        // 5. D-Pad Down (Show controls / Volume -)
        if (key == LogicalKeyboardKey.arrowDown) {
          if (!_showControls) {
            _showControlsOverlay();
            _tvVolume(-0.1);
            return KeyEventResult.handled;
          }
          _startControlsTimer();
          return KeyEventResult.ignored;
        }

        // 6. Mute Key
        if (key == LogicalKeyboardKey.audioVolumeMute) {
          _tvToggleMute();
          return KeyEventResult.handled;
        }

        // 7. Escape / Back Key
        if (key == LogicalKeyboardKey.escape) {
          if (_showControls) {
            setState(() => _showControls = false);
            return KeyEventResult.handled;
          }
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }

        if (_showControls) {
          _startControlsTimer();
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

                // 3. Center HUD Feedback (Play/Pause/Seek/Volume)
                if (_hudText != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA855F7), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_hudIcon != null) ...[
                            Icon(_hudIcon, color: const Color(0xFFC084FC), size: 28),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            _hudText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 4. Persistent Mini Floating Episode Pill (Visible when controls hidden for series)
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

                // 5. Floating Top Bar Overlay Controls & In-Player Episode Selector
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
                              // Back Button
                              TVFocusableWidget(
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

                              // Quick Prev / Next for Series
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
                                const SizedBox(width: 6),
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

                          // Direct In-Player Episode Selector Row
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

                // 6. Floating Bottom TV Player Control Bar (D-Pad Interactive)
                if (_showControls)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.95),
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Seek -10s Button
                          TVFocusableWidget(
                            onTap: () => _tvSeek(-10),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.replay_10_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 6),
                                  Text('-10 Detik', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Play / Pause Primary Button
                          TVFocusableWidget(
                            autofocus: true,
                            onTap: _tvPlayPause,
                            borderRadius: BorderRadius.circular(28),
                            focusGlowColor: const Color(0xFFEC4899),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Play / Pause',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Seek +10s Button
                          TVFocusableWidget(
                            onTap: () => _tvSeek(10),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.forward_10_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 6),
                                  Text('+10 Detik', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Mute / Unmute Button
                          TVFocusableWidget(
                            onTap: _tvToggleMute,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 6),
                                  Text('Suara', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }
}
