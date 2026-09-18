import 'dart:async';
import 'package:flutter/gestures.dart';
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
  bool _isPlaying = true;
  bool _isMuted = false;
  Timer? _controlsTimer;
  final RemoteConfigService _config = RemoteConfigService();
  final LK21ScraperService _scraper = LK21ScraperService();

  // TV Virtual Cursor & Native Pointer Simulation State
  bool _isCursorMode = false;
  Offset _cursorPos = const Offset(640, 360);
  Offset? _lastClickPos;
  bool _showClickRipple = false;
  Timer? _cursorIdleTimer;
  
  late SeriesEpisode? _currentEpisode;
  List<SeriesEpisode> _episodes = [];
  List<VideoServer> _servers = [];
  VideoServer? _activeServer;
  String _activeEmbedUrl = '';

  @override
  void initState() {
    super.initState();
    _episodes = List.from(widget.movie.episodes);
    _servers = List.from(widget.movie.servers);
    _currentEpisode = widget.initialEpisode ??
        (_episodes.isNotEmpty ? _episodes.first : null);
    if (_currentEpisode != null && _currentEpisode!.servers.isNotEmpty) {
      _servers = List.from(_currentEpisode!.servers);
    }
    _initWakelockAndOrientation();
    _setupWebViewController();
    _loadSelectedEpisode();
    _startControlsTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        setState(() {
          _cursorPos = Offset(size.width / 2, size.height / 2);
        });
      }
    });

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
          if (_servers.isEmpty && detail.servers.isNotEmpty) {
            _servers = detail.servers;
          }
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

  // Simulated Native OS Taps (Directly triggers underlying platform view / iframe player)
  void _simulateNativeTap(Offset globalPosition) {
    try {
      final int pointerId = DateTime.now().millisecondsSinceEpoch % 100000;
      final downEvent = PointerDownEvent(
        pointer: pointerId,
        position: globalPosition,
        kind: PointerDeviceKind.touch,
      );
      GestureBinding.instance.handlePointerEvent(downEvent);

      Future.delayed(const Duration(milliseconds: 60), () {
        final upEvent = PointerUpEvent(
          pointer: pointerId,
          position: globalPosition,
          kind: PointerDeviceKind.touch,
        );
        GestureBinding.instance.handlePointerEvent(upEvent);
      });
    } catch (e) {
      debugPrint('[Player] Error simulating native tap: $e');
    }
  }

  void _simulateDoubleTap(Offset globalPosition) {
    _simulateNativeTap(globalPosition);
    Future.delayed(const Duration(milliseconds: 140), () {
      _simulateNativeTap(globalPosition);
    });
  }

  void _triggerClickEffect(Offset pos) {
    setState(() {
      _lastClickPos = pos;
      _showClickRipple = true;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _showClickRipple = false);
      }
    });
  }

  void _moveCursor(double dx, double dy, Size size) {
    setState(() {
      _isCursorMode = true;
      _cursorPos = Offset(
        (_cursorPos.dx + dx).clamp(15.0, size.width - 15.0),
        (_cursorPos.dy + dy).clamp(15.0, size.height - 15.0),
      );
    });
    _resetCursorTimer();
  }

  void _clickAtCursor() {
    _triggerClickEffect(_cursorPos);
    _simulateNativeTap(_cursorPos);
    _resetCursorTimer();
  }

  void _resetCursorTimer() {
    _cursorIdleTimer?.cancel();
    _cursorIdleTimer = Timer(const Duration(seconds: 14), () {
      if (mounted && _isCursorMode) {
        setState(() => _isCursorMode = false);
      }
    });
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    _controller.runJavaScript("if (window.tvControl) window.tvControl('togglePlay');");
    try {
      final size = MediaQuery.of(context).size;
      final centerPos = Offset(size.width / 2, size.height / 2);
      _simulateNativeTap(centerPos);
      _triggerClickEffect(centerPos);
    } catch (_) {}
    _startControlsTimer();
  }

  String? _seekFeedbackText;
  Timer? _seekFeedbackTimer;

  void _showSeekFeedback(String text) {
    _seekFeedbackTimer?.cancel();
    setState(() {
      _seekFeedbackText = text;
    });
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _seekFeedbackText = null;
        });
      }
    });
  }

  void _rewind10({bool showFeedback = true}) {
    _controller.runJavaScript("if (window.tvControl) window.tvControl('rewind10');");
    try {
      final size = MediaQuery.of(context).size;
      final pos = Offset(size.width * 0.25, size.height / 2);
      _simulateDoubleTap(pos);
      _triggerClickEffect(pos);
    } catch (_) {}
    if (showFeedback) _showSeekFeedback('-10 Detik ⏪');
    _startControlsTimer();
  }

  void _forward10({bool showFeedback = true}) {
    _controller.runJavaScript("if (window.tvControl) window.tvControl('forward10');");
    try {
      final size = MediaQuery.of(context).size;
      final pos = Offset(size.width * 0.75, size.height / 2);
      _simulateDoubleTap(pos);
      _triggerClickEffect(pos);
    } catch (_) {}
    if (showFeedback) _showSeekFeedback('+10 Detik ⏩');
    _startControlsTimer();
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _controller.runJavaScript("if (window.tvControl) window.tvControl('toggleMute');");
    _showSeekFeedback(_isMuted ? 'Mute 🔇' : 'Suara Aktif 🔊');
    _startControlsTimer();
  }

  void _toggleFullscreen() {
    _controller.runJavaScript("if (window.tvControl) window.tvControl('toggleFullscreen');");
    try {
      final size = MediaQuery.of(context).size;
      final fsPos = Offset(size.width - 25, size.height - 25);
      _simulateNativeTap(fsPos);
      _triggerClickEffect(fsPos);
    } catch (_) {}
    _startControlsTimer();
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
                try {
                  // 1. Permanently remove and disable all ad overlays, traps, and popunders
                  var css = `
                    #uyeouyeo, a#uyeouyeo, .message-box, #loading-spinner, 
                    .spinner-overlay, #overlay, #adContainer, .ads, 
                    [class*="ad-"], [id*="ad-"], .popunder, #skipAds,
                    [href*="yellowishgather"], [href*="decafeligiblyhad"] {
                      display: none !important;
                      visibility: hidden !important;
                      opacity: 0 !important;
                      pointer-events: none !important;
                      width: 0 !important;
                      height: 0 !important;
                      z-index: -9999 !important;
                    }
                  `;
                  var style = document.createElement('style');
                  style.innerHTML = css;
                  document.head.appendChild(style);

                  var ads = document.querySelectorAll('#uyeouyeo, a#uyeouyeo, .message-box, #loading-spinner, .spinner-overlay, #overlay, #adContainer, .ads, [class*="ad-"], [id*="ad-"], .popunder, #skipAds');
                  ads.forEach(function(el) { if (el) el.remove(); });

                  // 2. Mock window.open so popup scripts think ad was handled cleanly
                  window.open = function() {
                    return { closed: true, focus: function(){}, blur: function(){}, close: function(){} };
                  };
                  window.alert = function() {};
                  window.confirm = function() { return false; };
                  window.prompt = function() { return null; };
                  window.onbeforeunload = null;

                  // 3. Auto click play on video player
                  setTimeout(function() {
                    var playBtn = document.querySelector('.jw-display-icon-container, .vjs-big-play-button, .play-button, .play-btn, [class*="play"], button.play, #customPlayButton, .play-wrapper');
                    if (playBtn) playBtn.click();
                  }, 800);
                } catch(e) {}
              })();
            ''');

            // Dispatch auto-play tap on Hydrax player center
            Future.delayed(const Duration(milliseconds: 1800), () {
              if (mounted) {
                try {
                  final size = MediaQuery.of(context).size;
                  _simulateNativeTap(Offset(size.width / 2, size.height / 2));
                  debugPrint('[Player] Auto-play tap dispatched to Hydrax center');
                } catch (_) {}
              }
            });
          },
          onNavigationRequest: (request) {
            final targetUrl = request.url.toLowerCase();

            // 1. Specifically block known redirect and ad destinations
            if (targetUrl.contains('abyss.to') ||
                targetUrl.contains('yellowishgather') ||
                targetUrl.contains('decafeligiblyhad') ||
                targetUrl.contains('profitablecpmrate') ||
                targetUrl.contains('highrevenueformat') ||
                targetUrl.contains('google.com') ||
                targetUrl.contains('doubleclick') ||
                targetUrl.contains('betting') ||
                targetUrl.contains('slot') ||
                targetUrl.contains('judol') ||
                targetUrl.contains('shopee') ||
                targetUrl.contains('lazada') ||
                targetUrl.contains('tokopedia') ||
                targetUrl.contains('play.google.com') ||
                targetUrl.startsWith('intent://') ||
                targetUrl.startsWith('market://') ||
                targetUrl.startsWith('tg://') ||
                targetUrl.startsWith('whatsapp://')) {
              debugPrint('[Player] ⛔ Blocked Ad/Redirect: \${request.url}');
              return NavigationDecision.prevent;
            }

            // 2. Strict Allowlist: Only allow genuine video stream hosts and players
            if (targetUrl.contains('videonode.de') ||
                targetUrl.contains('playcdn.de') ||
                targetUrl.contains('abyssplayer.com') ||
                targetUrl.contains('iamcdn.net') ||
                targetUrl.contains('turbovid') ||
                targetUrl.contains('emturbovid') ||
                targetUrl.contains('streamwish') ||
                targetUrl.contains('filelions') ||
                targetUrl.contains('dood') ||
                targetUrl.contains('lk21') ||
                targetUrl.contains('nontondrama') ||
                targetUrl.contains('short.ink') ||
                targetUrl.contains('about:blank') ||
                targetUrl.contains('blob:') ||
                targetUrl.contains('data:') ||
                targetUrl.contains('.m3u8') ||
                targetUrl.contains('.mp4') ||
                targetUrl.contains('.ts')) {
              return NavigationDecision.navigate;
            }

            // 3. Reject everything else to prevent any unexpected redirects
            debugPrint('[Player] ⛔ Blocked Unknown External Navigation: \${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      );
  }

  Future<void> _loadSelectedEpisode() async {
    setState(() => _isLoading = true);

    String embedUrl = '';
    List<VideoServer> availableServers = [];

    if (_currentEpisode != null) {
      if (_currentEpisode!.servers.isNotEmpty) {
        availableServers = List.from(_currentEpisode!.servers);
        embedUrl = _currentEpisode!.embedUrl;
      } else {
        final epDetail = await _scraper.fetchEpisodeDetails(_currentEpisode!);
        _currentEpisode = epDetail;
        availableServers = List.from(epDetail.servers);
        embedUrl = epDetail.embedUrl;
      }
    } else {
      if (widget.movie.servers.isNotEmpty) {
        availableServers = List.from(widget.movie.servers);
        embedUrl = widget.movie.embedUrl;
      } else {
        final detail = await _scraper.fetchMovieDetail(widget.movie);
        availableServers = List.from(detail.servers);
        embedUrl = detail.embedUrl;
        if (_episodes.isEmpty && detail.episodes.isNotEmpty) {
          _episodes = detail.episodes;
        }
      }
    }

    if (availableServers.isNotEmpty) {
      // Prioritize HYDRAX (1080p FHD) first, then TURBOVIP (720p HD), then others
      VideoServer? preferred;
      if (_activeServer != null) {
        preferred = availableServers.firstWhere(
          (s) => s.serverKey == _activeServer!.serverKey,
          orElse: () => availableServers.firstWhere(
            (s) => s.serverKey == 'hydrax',
            orElse: () => availableServers.firstWhere(
              (s) => s.serverKey == 'turbovip',
              orElse: () => availableServers.first,
            ),
          ),
        );
      } else {
        preferred = availableServers.firstWhere(
          (s) => s.serverKey == 'hydrax',
          orElse: () => availableServers.firstWhere(
            (s) => s.serverKey == 'turbovip',
            orElse: () => availableServers.first,
          ),
        );
      }
      _activeServer = preferred;
      embedUrl = preferred.url;
    }

    if (embedUrl.isEmpty) {
      embedUrl = widget.movie.url;
    }

    setState(() {
      _servers = availableServers;
      _activeEmbedUrl = embedUrl;
    });

    _renderPlayerHtml(_activeEmbedUrl);
  }

  String _selectedQuality = '1080p';
  final List<String> _qualityOptions = ['1080p', '720p', '480p', 'Auto'];

  void _switchQuality(String quality) {
    setState(() {
      _selectedQuality = quality;
    });
    _controller.runJavaScript("if (window.tvControl) window.tvControl('setQuality', '$quality');");

    try {
      final size = MediaQuery.of(context).size;
      final settingsPos = Offset(size.width - 65, size.height - 35);
      _simulateNativeTap(settingsPos);
      _triggerClickEffect(settingsPos);

      setState(() {
        _isCursorMode = true;
        _showControls = false;
        _cursorPos = Offset(size.width - 65, size.height - 75);
      });
      _resetCursorTimer();
      _showSeekFeedback('Menu Hydrax Terbuka: Pilih $quality (Tekan OK) 🖱️');
    } catch (_) {
      _showSeekFeedback('Kualitas: ${quality == "Auto" ? "Auto HD" : "$quality FHD"}');
      _startControlsTimer();
    }
  }

  void _renderPlayerHtml(String embedUrl) {
    final htmlContent = '''
      <!DOCTYPE html>
      <html lang="id">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <title>\${widget.movie.title}</title>
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
          src="$embedUrl"
          scrolling="no"
          frameborder="0"
          allowfullscreen="true"
          webkitallowfullscreen="true"
          mozallowfullscreen="true"
          allow="screen-wake-lock; autoplay; fullscreen; picture-in-picture">
        </iframe>
        <script>
          // 1. Mock window.open so popup scripts think ad opened without crashing player
          window.open = function(url) {
            return {
              closed: true,
              focus: function() {},
              blur: function() {},
              close: function() {}
            };
          };
          window.alert = function() {};
          window.confirm = function() { return false; };
          window.prompt = function() { return null; };
          window.onbeforeunload = null;

          // 2. Auto clear ad traps & overlays
          function cleanAdTraps() {
            try {
              var iframe = document.getElementById('mainPlayerIframe');
              if (iframe && iframe.contentDocument) {
                var doc = iframe.contentDocument;
                var uye = doc.getElementById('uyeouyeo');
                if (uye) uye.remove();
                var ov = doc.getElementById('overlay');
                if (ov) {
                  try { ov.click(); } catch(e) {}
                  ov.remove();
                }
                var sp = doc.getElementById('loading-spinner');
                if (sp) sp.remove();
              }
            } catch(e) {}
          }
          setInterval(cleanAdTraps, 400);

          // 3. TV Remote Controller Bridge
          window.tvControl = function(action, param) {
            try {
              function findJw() {
                if (typeof window.jwplayer === 'function') {
                  try { return window.jwplayer(); } catch(e) {}
                }
                var iframes = document.querySelectorAll('iframe');
                for (var i = 0; i < iframes.length; i++) {
                  try {
                    var win = iframes[i].contentWindow;
                    if (win && typeof win.jwplayer === 'function') {
                      return win.jwplayer();
                    }
                  } catch(e) {}
                }
                return null;
              }

              function findVideo(doc) {
                if (!doc) return null;
                var v = doc.querySelector('video');
                if (v) return v;
                var iframes = doc.querySelectorAll('iframe');
                for (var i = 0; i < iframes.length; i++) {
                  try {
                    var iv = findVideo(iframes[i].contentDocument || iframes[i].contentWindow.document);
                    if (iv) return iv;
                  } catch(e) {}
                }
                return null;
              }

              var jw = findJw();
              var v = findVideo(document);

              if (action === 'togglePlay') {
                if (jw && typeof jw.play === 'function') {
                  var state = jw.getState();
                  if (state === 'playing') jw.pause(); else jw.play();
                } else if (v) {
                  if (v.paused) v.play(); else v.pause();
                } else {
                  var playBtn = document.querySelector('.jw-display-icon-container, .vjs-big-play-button, .play-button, .play-btn, [class*="play"], button.play, #customPlayButton, .play-wrapper');
                  if (playBtn) playBtn.click();
                }
              } else if (action === 'rewind10') {
                if (jw && typeof jw.seek === 'function') {
                  var pos = jw.getPosition() || 0;
                  jw.seek(Math.max(0, pos - 10));
                } else if (v) {
                  v.currentTime = Math.max(0, v.currentTime - 10);
                } else {
                  var rBtn = document.querySelector('[class*="rewind"], .jw-icon-rewind, [aria-label*="Rewind"], [aria-label*="10s"]');
                  if (rBtn) rBtn.click();
                }
              } else if (action === 'forward10') {
                if (jw && typeof jw.seek === 'function') {
                  var pos = jw.getPosition() || 0;
                  var dur = jw.getDuration() || (pos + 10);
                  jw.seek(Math.min(dur, pos + 10));
                } else if (v) {
                  v.currentTime = Math.min((v.duration || (v.currentTime + 10)), v.currentTime + 10);
                } else {
                  var fBtn = document.querySelector('[class*="forward"], .jw-icon-forward, [aria-label*="Forward"], [aria-label*="10s"]');
                  if (fBtn) fBtn.click();
                }
              } else if (action === 'toggleMute') {
                if (jw && typeof jw.setMute === 'function') {
                  jw.setMute(!jw.getMute());
                } else if (v) {
                  v.muted = !v.muted;
                }
              } else if (action === 'setQuality') {
                if (jw && typeof jw.getLevels === 'function') {
                  var levels = jw.getLevels() || [];
                  for (var idx = 0; idx < levels.length; idx++) {
                    var lbl = (levels[idx].label || '').toLowerCase();
                    if (lbl.includes(param.toLowerCase())) {
                      jw.setCurrentLevel(idx);
                      return;
                    }
                  }
                  if (param.toLowerCase() === 'auto' && levels.length > 0) {
                    jw.setCurrentLevel(0);
                  }
                }
              } else if (action === 'toggleFullscreen') {
                if (jw && typeof jw.setFullscreen === 'function') {
                  jw.setFullscreen(!jw.getFullscreen());
                } else {
                  var fsBtn = document.querySelector('#fullscreen-btn, .jw-icon-fullscreen, .vjs-fullscreen-control, [class*="fullscreen"]');
                  if (fsBtn) {
                    fsBtn.click();
                  } else {
                    var el = document.documentElement;
                    if (document.fullscreenElement) {
                      if (document.exitFullscreen) document.exitFullscreen();
                    } else {
                      if (el.requestFullscreen) el.requestFullscreen();
                    }
                  }
                }
              }
            } catch(e) {
              console.error('tvControl error:', e);
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

    final embedUri = Uri.tryParse(embedUrl);
    final effectiveBaseUrl = (embedUri != null && embedUri.host.isNotEmpty)
        ? '${embedUri.scheme}://${embedUri.host}'
        : _config.activeBaseUrl;

    _controller.loadHtmlString(
      htmlContent,
      baseUrl: effectiveBaseUrl,
    );
  }

  void _switchEpisode(SeriesEpisode ep) {
    if (_currentEpisode?.episodeNo == ep.episodeNo && _currentEpisode?.season == ep.season) {
      return;
    }
    setState(() {
      _currentEpisode = ep;
      if (ep.servers.isNotEmpty) {
        _servers = List.from(ep.servers);
      }
    });
    _showSeekFeedback('Episode \${ep.episodeNo}');
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
    _seekFeedbackTimer?.cancel();
    _cursorIdleTimer?.cancel();
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

        // Dedicated Media Remote Keys
        if (key == LogicalKeyboardKey.mediaPlayPause || key == LogicalKeyboardKey.mediaPlay || key == LogicalKeyboardKey.mediaPause) {
          _togglePlay();
          return KeyEventResult.handled;
        } else if (key == LogicalKeyboardKey.mediaRewind) {
          _rewind10();
          return KeyEventResult.handled;
        } else if (key == LogicalKeyboardKey.mediaFastForward) {
          _forward10();
          return KeyEventResult.handled;
        }

        // 1. When in TV Virtual Cursor Mode (Remote D-Pad navigates cursor)
        if (_isCursorMode) {
          final size = MediaQuery.of(context).size;
          const step = 42.0;

          if (key == LogicalKeyboardKey.arrowLeft) {
            _moveCursor(-step, 0, size);
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.arrowRight) {
            _moveCursor(step, 0, size);
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.arrowUp) {
            _moveCursor(0, -step, size);
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.arrowDown) {
            _moveCursor(0, step, size);
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.select ||
                     key == LogicalKeyboardKey.enter ||
                     key == LogicalKeyboardKey.space ||
                     key == LogicalKeyboardKey.numpadEnter) {
            _clickAtCursor();
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.escape ||
                     key == LogicalKeyboardKey.goBack) {
            setState(() {
              _isCursorMode = false;
              _showControls = true;
            });
            _startControlsTimer();
            return KeyEventResult.handled;
          }
        }

        // 2. TV Remote D-Pad Navigation when controls are hidden
        if (!_showControls) {
          final size = MediaQuery.of(context).size;

          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.numpadEnter) {
            // Direct click on Hydrax center (Play / Pause)
            _togglePlay();
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.arrowLeft ||
                     key == LogicalKeyboardKey.arrowRight ||
                     key == LogicalKeyboardKey.arrowUp ||
                     key == LogicalKeyboardKey.arrowDown) {
            // Immediately activate TV Virtual Cursor so remote D-pad controls Hydrax!
            setState(() {
              _isCursorMode = true;
              _cursorPos = Offset(size.width / 2, size.height / 2);
            });
            const step = 42.0;
            if (key == LogicalKeyboardKey.arrowLeft) _moveCursor(-step, 0, size);
            if (key == LogicalKeyboardKey.arrowRight) _moveCursor(step, 0, size);
            if (key == LogicalKeyboardKey.arrowUp) _moveCursor(0, -step, size);
            if (key == LogicalKeyboardKey.arrowDown) _moveCursor(0, step, size);
            return KeyEventResult.handled;
          }
        } else {
          // If controls are open, reset timer on each D-pad press
          _startControlsTimer();

          if (key == LogicalKeyboardKey.escape) {
            setState(() => _showControls = false);
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: PopScope(
        canPop: !_isCursorMode && !_showControls,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isCursorMode) {
            setState(() {
              _isCursorMode = false;
              _showControls = true;
            });
            _startControlsTimer();
          } else if (!_showControls) {
            setState(() => _showControls = true);
            _startControlsTimer();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // 1. Direct Web Player (Isolated inside local HTML iframe) - Allows all direct touches & pointer events
              Positioned.fill(
                child: WebViewWidget(controller: _controller),
              ),

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
                                : 'Menghubungkan Server: ${widget.movie.title}',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _activeServer != null
                                ? 'Server: ${_activeServer!.name} • Anti-Iklan • Layar Selalu Hidup ⚡'
                                : 'Player In-App Aktif • Anti-Iklan • Layar Selalu Hidup ⚡',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 2.5 Animated HUD Feedback Badge (Seek -10s, +10s, Mute, Quality change)
                if (_seekFeedbackText != null)
                  Center(
                    child: AnimatedOpacity(
                      opacity: _seekFeedbackText != null ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFA855F7), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFA855F7).withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          _seekFeedbackText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 2.6 Animated Click Ripple (Visual touch indicator on TV / Pointer tap)
                if (_showClickRipple && _lastClickPos != null)
                  Positioned(
                    left: _lastClickPos!.dx - 22,
                    top: _lastClickPos!.dy - 22,
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 320),
                        builder: (context, val, child) {
                          return Opacity(
                            opacity: (1.0 - val).clamp(0.0, 1.0),
                            child: Container(
                              width: 44 * (0.6 + val * 0.4),
                              height: 44 * (0.6 + val * 0.4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF38BDF8), width: 2.5),
                                color: const Color(0xFFA855F7).withValues(alpha: 0.35 * (1 - val)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // 2.7 TV Virtual Cursor Guidance Banner (Visible when Cursor Mode is Active)
                if (_isCursorMode)
                  Positioned(
                    top: 14,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mouse_rounded, color: Color(0xFF38BDF8), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Mode Kursor TV Aktif • Arahkan & Tekan OK untuk Klik Player Hydrax',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isCursorMode = false;
                                  _showControls = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Tutup (Back)',
                                  style: TextStyle(color: Color(0xFFC084FC), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 2.8 Glowing TV Pointer Cursor (Precise position with luminous ring)
                if (_isCursorMode)
                  Positioned(
                    left: _cursorPos.dx - 12,
                    top: _cursorPos.dy - 12,
                    child: IgnorePointer(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Luminous outer aura
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.7),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          // High-contrast angled navigation cursor
                          Transform.rotate(
                            angle: -0.5,
                            child: const Icon(
                              Icons.navigation_rounded,
                              color: Color(0xFF38BDF8),
                              size: 26,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                              ],
                            ),
                          ),
                          // Precision Center Dot
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Persistent Mini Floating Episode & Quality Pill (Visible when controls hidden)
                if (!_showControls && !_isCursorMode)
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
                            const Icon(Icons.hd_rounded, color: Color(0xFF38BDF8), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _activeServer != null
                                  ? _activeServer!.qualityLabel
                                  : (isSeries && _currentEpisode != null ? 'EPS ${_currentEpisode!.episodeNo}' : '1080p FHD'),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 4. Floating Top Bar Overlay Controls, Server/Quality Selector, & Episode Selector
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
                                autofocus: false,
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
                                          : '${widget.movie.quality} • 1080p FHD • Subtitle Indonesia • Layar Selalu Hidup ⚡',
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
                              const SizedBox(width: 8),

                              // Kursor TV Mode Toggle Button (D-Pad Focusable)
                              TVFocusableWidget(
                                onTap: () {
                                  final size = MediaQuery.of(context).size;
                                  setState(() {
                                    _isCursorMode = !_isCursorMode;
                                    if (_isCursorMode) {
                                      _showControls = false;
                                      _cursorPos = Offset(size.width / 2, size.height / 2);
                                    }
                                  });
                                  if (_isCursorMode) {
                                    _showSeekFeedback('Mode Kursor TV Aktif 🖱️ (Gunakan Tombol Arah & OK)');
                                    _resetCursorTimer();
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isCursorMode ? const Color(0xFF0284C7) : Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _isCursorMode ? Colors.white : const Color(0xFF38BDF8).withValues(alpha: 0.6),
                                      width: _isCursorMode ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.mouse_rounded, color: Color(0xFF38BDF8), size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isCursorMode ? 'Kursor Aktif' : 'Kursor TV',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Unified Hydrax Quality Resolution Row (D-Pad Focusable Chips)
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.high_quality_rounded, color: Color(0xFF38BDF8), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Kualitas Video (HYDRAX Source):',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  'Aktif: $_selectedQuality',
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (final q in _qualityOptions) ...[
                                  Builder(builder: (context) {
                                    final isCurrent = _selectedQuality == q;
                                    String label = q;
                                    if (q == '1080p') label = '1080p Full HD';
                                    if (q == '720p') label = '720p HD';
                                    if (q == '480p') label = '480p SD';
                                    if (q == 'Auto') label = 'Auto (Adaptif)';

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: TVFocusableWidget(
                                        onTap: () => _switchQuality(q),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            gradient: isCurrent
                                                ? const LinearGradient(
                                                    colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
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
                                              Icon(
                                                q == '1080p'
                                                    ? Icons.hd_rounded
                                                    : (q == '720p' ? Icons.high_quality_rounded : Icons.sd_rounded),
                                                color: isCurrent ? Colors.white : const Color(0xFF38BDF8),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                label,
                                                style: TextStyle(
                                                  color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.9),
                                                  fontSize: 11,
                                                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),

                          // Direct In-Player Episode Selector Row (D-Pad Focusable Chips)
                          if (isSeries && _episodes.isNotEmpty) ...[
                            const SizedBox(height: 10),
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
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 36,
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

                // 5. Floating Bottom Player Control Bar (Play/Pause, -10s, +10s, Mute, Status, Fullscreen)
                if (_showControls)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
                        children: [
                          // Play / Pause Button (D-Pad Focusable)
                          TVFocusableWidget(
                            autofocus: true,
                            onTap: _togglePlay,
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Rewind 10s Button (D-Pad Focusable)
                          TVFocusableWidget(
                            onTap: _rewind10,
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(
                                Icons.replay_10_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Forward 10s Button (D-Pad Focusable)
                          TVFocusableWidget(
                            onTap: _forward10,
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(
                                Icons.forward_10_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Mute / Volume Button (D-Pad Focusable)
                          TVFocusableWidget(
                            onTap: _toggleMute,
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Icon(
                                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                color: _isMuted ? const Color(0xFFF87171) : Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Active Quality & Engine Badge
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.hd_rounded, color: Color(0xFF38BDF8), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        _activeServer != null
                                            ? '${_activeServer!.qualityLabel} (${_activeServer!.name})'
                                            : '1080p FHD (HYDRAX)',
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Fullscreen Button (D-Pad Focusable)
                          TVFocusableWidget(
                            onTap: _toggleFullscreen,
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 22,
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
    );
  }
}
