import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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
      default:
        return widget.match.streamJalur1;
    }
  }

  String _getRefererForUrl(String url) {
    if (widget.match.streamJalur2.isNotEmpty &&
        widget.match.streamJalur2.startsWith('http')) {
      try {
        final uri = Uri.parse(widget.match.streamJalur2);
        return '${uri.scheme}://${uri.host}/';
      } catch (_) {}
    }
    if (widget.match.streamJalur3.isNotEmpty &&
        widget.match.streamJalur3.startsWith('http')) {
      try {
        final uri = Uri.parse(widget.match.streamJalur3);
        return '${uri.scheme}://${uri.host}/';
      } catch (_) {}
    }
    return 'https://scoopnashville.com/';
  }

  /// Ekstraksi link direct video (.m3u8 / .flv / .mp4) dari berbagai format web sumber
  Future<String?> _resolveDirectStreamUrl(String rawUrl) async {
    if (rawUrl.isEmpty) return null;
    final lower = rawUrl.toLowerCase();

    // 1. Jika URL sudah berformat direct media m3u8 atau mp4
    if (lower.contains('.m3u8') || lower.contains('.mp4')) {
      return rawUrl;
    }

    try {
      final referer = _getRefererForUrl(rawUrl);
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14; Mobile; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
        'Referer': referer,
        'Origin': referer.endsWith('/')
            ? referer.substring(0, referer.length - 1)
            : referer,
      };

      final response = await http
          .get(Uri.parse(rawUrl), headers: headers)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final body = response.body;

        // 2. Ekstraksi var urlStream = "https://...";
        final urlStreamMatch = RegExp(
          r'var\s+urlStream\s*=\s*["\x27](https?://[^"\x27\s]+)["\x27]',
          caseSensitive: false,
        ).firstMatch(body);
        if (urlStreamMatch != null) {
          final stream = urlStreamMatch.group(1);
          if (stream != null && stream.isNotEmpty) return stream;
        }

        // 3. Ekstraksi link m3u8 langsung di dalam body response
        final m3u8Match = RegExp(
          r'https?://[^\s"<>]+?\.m3u8[^\s"<>]*',
          caseSensitive: false,
        ).firstMatch(body);
        if (m3u8Match != null) {
          final stream = m3u8Match.group(0);
          if (stream != null && stream.isNotEmpty) return stream;
        }

        // 4. Ekstraksi list_stream JSON array jika berupa web page
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
                final resolved = await _resolveDirectStreamUrl(innerUrl);
                if (resolved != null) return resolved;
              }
            }
          }
        }

        // 5. Ekstraksi iframe src di halaman pertandingan
        final iframeMatch = RegExp(
          r'<iframe[^>]+src=["\x27](https?://[^"\x27\s]+)["\x27]',
          caseSensitive: false,
        ).firstMatch(body);
        if (iframeMatch != null) {
          final iframeUrl = iframeMatch.group(1);
          if (iframeUrl != null && iframeUrl != rawUrl) {
            final resolved = await _resolveDirectStreamUrl(iframeUrl);
            if (resolved != null) return resolved;
          }
        }

        // 6. Ekstraksi channel id (contoh: channel17) untuk direct HLS CDN stream
        final channelMatch = RegExp(
          r'(channel[\-_]?[0-9a-zA-Z]+)',
          caseSensitive: false,
        ).firstMatch(rawUrl);
        if (channelMatch != null) {
          final ch = channelMatch.group(1);
          if (ch != null && ch.isNotEmpty) {
            final candidates = [
              'https://live.domainkqt.cc/live/$ch.m3u8',
              'https://lfastcdn.domainkqt.cc/live/$ch/playlist.m3u8',
              'https://quickscoreboardz.com/live/$ch.m3u8',
            ];
            for (final cand in candidates) {
              return cand;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Player] Direct stream resolution info: $e');
    }

    // Coba fallback channel direct regex dari URL mentah
    final channelFallback = RegExp(
      r'(channel[\-_]?[0-9a-zA-Z]+)',
      caseSensitive: false,
    ).firstMatch(rawUrl);
    if (channelFallback != null) {
      final ch = channelFallback.group(1);
      if (ch != null) {
        return 'https://lfastcdn.domainkqt.cc/live/$ch/playlist.m3u8';
      }
    }

    return null;
  }

  Future<void> _initPlayer() async {
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

    // Resolusi link direct .m3u8 dari sumber
    final directStream = await _resolveDirectStreamUrl(rawUrl);

    if (directStream != null && directStream.isNotEmpty) {
      try {
        await _videoController?.dispose();
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(directStream),
          httpHeaders: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14; Mobile; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
            'Referer': _getRefererForUrl(rawUrl),
            'Origin': _getRefererForUrl(rawUrl),
          },
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

        await controller.initialize();
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
        return;
      } catch (e) {
        debugPrint('[Player] Native VideoPlayer init error: $e');
      }
    }

    // Jika jalur ini belum aktif / offline
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Siaran pada Jalur $_activeJalur sedang offline atau belum dimulai.\nSilakan pilih Jalur Server lain di bawah ini:';
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
    _initPlayer();
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
              // 1. AREA VIDEO PLAYER NATIVE MURNI (ExoPlayer)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: Center(
                  child: _isLoading
                      ? _buildLoadingWidget()
                      : _errorMessage != null
                          ? _buildErrorWidget()
                          : _videoController != null &&
                                  _videoController!.value.isInitialized
                              ? SizedBox.expand(
                                  child: FittedBox(
                                    fit: _videoFit,
                                    child: SizedBox(
                                      width: _videoController!.value.size.width,
                                      height:
                                          _videoController!.value.size.height,
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
                              tooltip: _isMuted ? 'Nyalakan Suara' : 'Matikan Suara',
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

                        Row(
                          children: [
                            Expanded(child: _buildJalurButton(1, 'Jalur 1 (HD Server)')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildJalurButton(2, 'Jalur 2 (Fast Server)')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildJalurButton(3, 'Jalur 3 (Backup Server)')),
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
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
          ),
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
              _buildSmallJalurButton(1, 'Jalur 1'),
              _buildSmallJalurButton(2, 'Jalur 2'),
              _buildSmallJalurButton(3, 'Jalur 3'),
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
    if (sport.contains('moto') || sport.contains('f1') || sport.contains('racing')) {
      return Icons.sports_motorsports_rounded;
    }
    if (sport.contains('esport')) return Icons.sports_esports_rounded;
    return Icons.sports_soccer_rounded;
  }
}
