import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie_model.dart';
import '../services/lk21_scraper_service.dart';
import '../services/remote_config_service.dart';
import '../widgets/tv_focusable_widget.dart';
import '../widgets/tv_movie_card.dart';
import 'category_list_screen.dart';
import 'movie_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LK21ScraperService _scraper = LK21ScraperService();
  final RemoteConfigService _config = RemoteConfigService();

  bool _isLoading = true;
  
  // Category Lists
  List<Movie> _filmTerbaru = [];
  List<Movie> _seriesUnggulan = [];
  List<Movie> _seriesUpdate = [];
  List<Movie> _topBulanIni = [];
  List<Movie> _topRating = [];
  List<Movie> _genreMovies = [];
  
  final PageController _heroPageController = PageController();
  int _currentHeroIndex = 0;
  Timer? _heroTimer;

  static const String saweriaUrl = 'https://saweria.co/meiwatv';

  @override
  void initState() {
    super.initState();
    _initApp();
    _startHeroTimer();
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final heroMovies = _getFeaturedMovies();
      if (heroMovies.length > 1 && _heroPageController.hasClients) {
        final nextIndex = (_currentHeroIndex + 1) % heroMovies.length;
        _heroPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  List<Movie> _getFeaturedMovies() {
    if (_topBulanIni.isNotEmpty) {
      return _topBulanIni.take(5).toList();
    }
    if (_filmTerbaru.isNotEmpty) {
      return _filmTerbaru.take(5).toList();
    }
    return [];
  }

  Color _getQualityColor(String quality, bool isSeries) {
    if (isSeries) return const Color(0xFF8B5CF6);
    final q = quality.toUpperCase();
    if (q.contains('CAM') || q.contains('TS') || q.contains('TELESYNC') || q.contains('WORKPRINT')) {
      return const Color(0xFFEF4444); // Red for CAM
    }
    if (q.contains('HD') || q.contains('FHD') || q.contains('4K') || q.contains('1080') || q.contains('720') || q.contains('BLURAY') || q.contains('WEB')) {
      return const Color(0xFF10B981); // Green for HD
    }
    if (q.contains('SD') || q.contains('DVD') || q.contains('HDRIP')) {
      return const Color(0xFFF59E0B); // Amber for SD
    }
    return const Color(0xFF10B981);
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    setState(() => _isLoading = true);
    await _config.initConfig();
    await _loadAllCategories();
  }

  Future<void> _loadAllCategories() async {
    // Helper to run safely
    void safeRun(Future<List<Movie>> future, Function(List<Movie>) onData) {
      future.then((list) {
        if (mounted && list.isNotEmpty) {
          setState(() {
            onData(list);
            _isLoading = false;
          });
        }
      }).catchError((e) {
        debugPrint('[HomeScreen] Load error: $e');
      });
    }

    // 1. Fetch Film Terbaru
    safeRun(_scraper.fetchFilmTerbaru(), (list) {
      _filmTerbaru = list;
    });

    // 2. Fetch Series Unggulan
    safeRun(_scraper.fetchSeriesUnggulan(), (list) {
      _seriesUnggulan = list;
    });

    // 3. Fetch Series Update
    safeRun(_scraper.fetchSeriesUpdate(), (list) {
      _seriesUpdate = list;
    });

    // 4. Fetch Top Bulan Ini
    safeRun(_scraper.fetchTopBulanIni(), (list) {
      _topBulanIni = list;
    });

    // 5. Fetch Top Rating
    safeRun(_scraper.fetchTopRating(), (list) {
      _topRating = list;
    });

    // 6. Fetch Genre movies (Action)
    safeRun(_scraper.fetchMoviesByGenre('action'), (list) {
      _genreMovies = list;
    });

    // Safety timeout: dismiss spinner after 4 seconds max
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _openDetail(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: movie),
      ),
    );
  }

  void _openCategory(String title, String endpoint) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryListScreen(
          title: title,
          endpoint: endpoint,
        ),
      ),
    );
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[HomeScreen] Could not launch $url: $e');
    }
  }

  void _openSearch() {
    final allMovies = <Movie>[];
    final seen = <String>{};
    for (final m in [
      ..._topBulanIni,
      ..._filmTerbaru,
      ..._seriesUnggulan,
      ..._seriesUpdate,
      ..._topRating,
      ..._genreMovies,
    ]) {
      if (seen.add(m.slug)) {
        allMovies.add(m);
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialRecommendations: allMovies),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFA855F7),
          backgroundColor: const Color(0xFF0E131F),
          onRefresh: _initApp,
          child: CustomScrollView(
            slivers: [
              // 1. Top Header Navbar with Meiwa Studio Logo & Action Buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      // Header Logo Image (meiwa studio.png)
                      Image.asset(
                        'assets/images/header_logo.png',
                        height: 42,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/images/logo_icon.png',
                          height: 38,
                        ),
                      ),
                      const Spacer(),

                      // Saweria Donasi Button
                      TVFocusableWidget(
                        onTap: () => _launchExternalUrl(saweriaUrl),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB703).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.coffee_rounded, color: Color(0xFFFFB703), size: 16),
                              SizedBox(width: 4),
                              Text('Saweria', style: TextStyle(color: Color(0xFFFFB703), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Search Button (TV Focusable)
                      TVFocusableWidget(
                        onTap: _openSearch,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Cari', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Refresh Button
                      TVFocusableWidget(
                        onTap: _initApp,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Hero Top 5 Featured Movies Slider
              Builder(
                builder: (context) {
                  final heroMovies = _getFeaturedMovies();
                    if (heroMovies.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox(height: 8));
                    }

                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: PageView.builder(
                                controller: _heroPageController,
                                itemCount: heroMovies.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentHeroIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final movie = heroMovies[index];
                                  final qColor = _getQualityColor(movie.quality, movie.isSeries);

                                  return TVFocusableWidget(
                                    onTap: () => _openDetail(movie),
                                    scaleFactor: 1.02,
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(18),
                                            child: CachedNetworkImage(
                                              imageUrl: movie.posterUrl,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) => Container(color: const Color(0xFF131A29)),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(18),
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.black.withValues(alpha: 0.95),
                                                  Colors.black.withValues(alpha: 0.7),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 18,
                                            left: 20,
                                            bottom: 18,
                                            right: 120,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEC4899),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        '🔥 TOP ${index + 1} BULAN INI',
                                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: qColor.withValues(alpha: 0.25),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: qColor.withValues(alpha: 0.7)),
                                                      ),
                                                      child: Text(
                                                        movie.isSeries ? 'SERIES' : movie.quality,
                                                        style: TextStyle(color: qColor, fontSize: 9, fontWeight: FontWeight.w900),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  movie.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                                                        ),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                                          SizedBox(width: 4),
                                                          Text('Tonton Sekarang', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (heroMovies.length > 1) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  heroMovies.length,
                                  (dotIndex) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: _currentHeroIndex == dotIndex ? 20 : 6,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: _currentHeroIndex == dotIndex
                                          ? const Color(0xFFA855F7)
                                          : Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // 5. Loading State
                if (_isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Menghubungkan ke Server Film & Drama...',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Section 1: FILM TERBARU
                  if (_filmTerbaru.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildCategorySection(
                        title: '🎬 FILM TERBARU',
                        movies: _filmTerbaru,
                        onSeeAll: () => _openCategory('Film Terbaru', '/latest'),
                      ),
                    ),

                  // Section 2: SERIES UNGGULAN
                  if (_seriesUnggulan.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildCategorySection(
                        title: '⭐ SERIES UNGGULAN',
                        movies: _seriesUnggulan,
                        onSeeAll: () => _openCategory('Series Unggulan', '/top-series-today'),
                      ),
                    ),

                  // Section 3: SERIES UPDATE
                  if (_seriesUpdate.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildCategorySection(
                        title: '📺 SERIES UPDATE',
                        movies: _seriesUpdate,
                        onSeeAll: () => _openCategory('Series Update', '/latest-series'),
                      ),
                    ),

                  // Section 4: TOP BULAN INI
                  if (_topBulanIni.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildCategorySection(
                        title: '🔥 TOP BULAN INI',
                        movies: _topBulanIni,
                        onSeeAll: () => _openCategory('Top Bulan Ini', '/populer'),
                      ),
                    ),

                  // Section 5: TOP RATING
                  if (_topRating.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildCategorySection(
                        title: '🏆 TOP RATING',
                        movies: _topRating,
                        onSeeAll: () => _openCategory('Top Rating', '/rating'),
                      ),
                    ),

                  // Section 6: Action / Popular Movies
                  if (_genreMovies.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildCategorySection(
                        title: '🎬 FILM ACTION TERPOPULER',
                        movies: _genreMovies,
                        onSeeAll: () => _openCategory('Semua Film Action', '/genre/action'),
                      ),
                    ),
                ],

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable Horizontal Section with Header & "Semua" Button
  Widget _buildCategorySection({
    required String title,
    required List<Movie> movies,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                // "Semua" / "Lihat Semua" Button (TV Focusable)
                TVFocusableWidget(
                  onTap: onSeeAll,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Semua',
                          style: TextStyle(
                            color: Color(0xFFC084FC),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFC084FC), size: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Movie Cards Carousel
          SizedBox(
            height: 235,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: movies.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final movie = movies[index];
                return SizedBox(
                  width: 135,
                  child: TVMovieCard(
                    movie: movie,
                    onTap: () => _openDetail(movie),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
