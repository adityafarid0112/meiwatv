import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie_model.dart';
import '../services/lk21_scraper_service.dart';
import '../widgets/tv_focusable_widget.dart';
import 'player_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _currentMovie;
  final LK21ScraperService _scraper = LK21ScraperService();
  bool _isLoadingDetail = true;
  int _selectedSeason = 1;

  static const String adsterraUrl1 = 'https://www.profitableratecpmnetwork.com/r1x7jbv2ys?key=c06365de807e3e8605b4e7e665953775';
  static const String adsterraUrl2 = 'https://www.profitableratecpmnetwork.com/nhgf41xe?key=c1f7258bb9659ab225647c310b68619e';
  static int _adCounter = 0;

  void _triggerPopUnder() {
    try {
      _adCounter++;
      final targetAd = (_adCounter % 2 == 1) ? adsterraUrl1 : adsterraUrl2;
      launchUrl(Uri.parse(targetAd), mode: LaunchMode.externalApplication);
      debugPrint('[Adsterra] Pop-under triggered on Play: $targetAd');
    } catch (e) {
      debugPrint('[Adsterra] Pop-under error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoadingDetail = true);
    final updated = await _scraper.fetchMovieDetail(widget.movie);
    if (mounted) {
      setState(() {
        _currentMovie = updated;
        _isLoadingDetail = false;
      });
    }
  }

  void _openPlayer({SeriesEpisode? episode}) {
    // Trigger pop-under ad every time play is clicked
    _triggerPopUnder();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          movie: _currentMovie,
          initialEpisode: episode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final episodes = _currentMovie.episodes;
    final isSeries = _currentMovie.isSeries || episodes.isNotEmpty;

    // Filter episodes for current selected season
    final seasonEpisodes = episodes.where((e) => e.season == _selectedSeason).toList();
    final allSeasons = episodes.map((e) => e.season).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: CustomScrollView(
        slivers: [
          // 1. Sliver App Bar with Backdrop & Poster
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: const Color(0xFF07090E),
            leading: TVFocusableWidget(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
            ),
            actions: [
              TVFocusableWidget(
                onTap: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'Nonton ${_currentMovie.title} gratis dengan subtitle Indonesia di MeiwaStudio: https://meiwa.my.id',
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop Image
                  CachedNetworkImage(
                    imageUrl: _currentMovie.posterUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(color: const Color(0xFF131A29)),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          const Color(0xFF07090E).withValues(alpha: 0.75),
                          const Color(0xFF07090E),
                        ],
                      ),
                    ),
                  ),
                  // Poster + Title Row inside Header
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Main Poster
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: _currentMovie.posterUrl,
                            width: 110,
                            height: 165,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Metadata
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentMovie.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (_currentMovie.rating.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            _currentMovie.rating,
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      isSeries ? 'SERIES' : _currentMovie.quality,
                                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currentMovie.year,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Play Action Buttons (Matching Screenshot 1 for Series, Single for Movie)
                  if (isSeries && episodes.isNotEmpty) ...[
                    Row(
                      children: [
                        // Play Awal Button
                        Expanded(
                          child: TVFocusableWidget(
                            autofocus: true,
                            onTap: () => _openPlayer(episode: episodes.first),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Play Awal', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Play Terbaru Button
                        Expanded(
                          child: TVFocusableWidget(
                            onTap: () => _openPlayer(episode: episodes.last),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Play Eps ${episodes.last.episodeNo}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Standard Movie Play Button
                    TVFocusableWidget(
                      autofocus: true,
                      onTap: () => _openPlayer(),
                      scaleFactor: 1.04,
                      borderRadius: BorderRadius.circular(16),
                      focusGlowColor: const Color(0xFFA855F7),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'NONTON FILM SEKARANG',
                              style: TextStyle(
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
                  ],

                  const SizedBox(height: 20),

                  // Genre Tags
                  if (_currentMovie.genres.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentMovie.genres.map((g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Series Episode Grid Section (Matching Screenshot 1)
                  if (isSeries && episodes.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          'Daftar Episode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        if (allSeasons.length > 1)
                          DropdownButton<int>(
                            value: _selectedSeason,
                            dropdownColor: const Color(0xFF0E131F),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFA855F7)),
                            items: allSeasons.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text('Season $s'),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSeason = val);
                            },
                          )
                        else
                          Text(
                            '${episodes.length} Episode Tersedia',
                            style: TextStyle(color: const Color(0xFFA855F7).withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Grid of Episode Buttons
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 8 : 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: seasonEpisodes.isNotEmpty ? seasonEpisodes.length : episodes.length,
                      itemBuilder: (context, index) {
                        final ep = seasonEpisodes.isNotEmpty ? seasonEpisodes[index] : episodes[index];
                        return TVFocusableWidget(
                          onTap: () => _openPlayer(episode: ep),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF131A29),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Center(
                              child: Text(
                                '${ep.episodeNo}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ] else if (_isLoadingDetail && isSeries) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFFA855F7)))),
                            SizedBox(width: 10),
                            Text('Memuat daftar episode...', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Synopsis Header & Text
                  const Text(
                    'Sinopsis & Deskripsi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentMovie.synopsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Feature Cards / Highlights
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E131F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.hd_outlined, 'Kualitas Video', isSeries ? 'Series Full HD' : '${_currentMovie.quality} Full HD'),
                        const Divider(color: Colors.white10, height: 18),
                        _buildInfoRow(Icons.subtitles_outlined, 'Subtitle', 'Bahasa Indonesia (Aktif)'),
                        const Divider(color: Colors.white10, height: 18),
                        _buildInfoRow(Icons.timer_outlined, 'Durasi / Total', _currentMovie.duration.isNotEmpty ? _currentMovie.duration : (episodes.isNotEmpty ? '${episodes.length} Eps' : 'Penuh')),
                        const Divider(color: Colors.white10, height: 18),
                        _buildInfoRow(Icons.screen_lock_portrait_outlined, 'Layar Aktif', 'Anti Sleep / Tanpa Screensaver ⚡'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFA855F7), size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
