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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LK21ScraperService _scraper = LK21ScraperService();
  final RemoteConfigService _config = RemoteConfigService();

  bool _isLoading = true;
  String _selectedGenreSlug = '';
  
  // Category Lists
  List<Movie> _filmTerbaru = [];
  List<Movie> _seriesUnggulan = [];
  List<Movie> _seriesUpdate = [];
  List<Movie> _topBulanIni = [];
  List<Movie> _topRating = [];
  List<Movie> _genreMovies = [];
  List<Movie> _searchResults = [];
  Movie? _featuredMovie;
  
  final TextEditingController _searchController = TextEditingController();

  static const String saweriaUrl = 'https://saweria.co/meiwatv';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    setState(() => _isLoading = true);
    await _config.initConfig();
    await _loadAllCategories();
  }

  Future<void> _loadAllCategories() async {
    try {
      final results = await Future.wait([
        _scraper.fetchFilmTerbaru(),
        _scraper.fetchSeriesUnggulan(),
        _scraper.fetchSeriesUpdate(),
        _scraper.fetchTopBulanIni(),
        _scraper.fetchTopRating(),
        _scraper.fetchMoviesByGenre(_selectedGenreSlug.isNotEmpty ? _selectedGenreSlug : 'action'),
      ]);

      if (mounted) {
        setState(() {
          _filmTerbaru = results[0];
          _seriesUnggulan = results[1];
          _seriesUpdate = results[2];
          _topBulanIni = results[3];
          _topRating = results[4];
          _genreMovies = results[5];

          if (_filmTerbaru.isNotEmpty) {
            _featuredMovie = _filmTerbaru.first;
          } else if (_topBulanIni.isNotEmpty) {
            _featuredMovie = _topBulanIni.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error loading categories: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onGenreSelected(String slug) {
    setState(() {
      _selectedGenreSlug = slug;
      _searchResults.clear();
    });
    _loadGenreMovies(slug);
  }

  Future<void> _loadGenreMovies(String slug) async {
    final list = await _scraper.fetchMoviesByGenre(slug);
    if (mounted) {
      setState(() {
        _genreMovies = list;
      });
    }
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E131F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFA855F7), width: 1.5),
        ),
        title: const Text('Cari Judul Film / Series', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Misal: Reacher, Avatar, Fast...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA855F7)),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          onSubmitted: (query) {
            Navigator.of(ctx).pop();
            _performSearch(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _performSearch(_searchController.text);
            },
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final results = await _scraper.searchMovies(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
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
                        onTap: _showSearchDialog,
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

              // 2. Search Results View (if active)
              if (_searchResults.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        const Text(
                          'Hasil Pencarian Film',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFA855F7)),
                          label: const Text('Tutup', style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold)),
                          onPressed: () => setState(() => _searchResults.clear()),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 900
                          ? 6
                          : (MediaQuery.of(context).size.width > 600 ? 4 : 3),
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movie = _searchResults[index];
                        return TVMovieCard(
                          movie: movie,
                          onTap: () => _openDetail(movie),
                        );
                      },
                      childCount: _searchResults.length,
                    ),
                  ),
                ),
              ] else ...[
                // 3. Hero Featured Movie Banner
                if (_featuredMovie != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                      child: TVFocusableWidget(
                        onTap: () => _openDetail(_featuredMovie!),
                        scaleFactor: 1.02,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: 195,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: _featuredMovie!.posterUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(color: const Color(0xFF131A29)),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.92),
                                      Colors.black.withValues(alpha: 0.6),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 20,
                                left: 20,
                                bottom: 20,
                                right: 120,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEC4899),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '🔥 REKOMENDASI HARI INI',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _featuredMovie!.title,
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
                      ),
                    ),
                  ),

                // 4. Quick Genre Pills Bar
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _config.genres.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final genre = _config.genres[index];
                        final isSelected = _selectedGenreSlug == genre.slug;

                        return TVFocusableWidget(
                          onTap: () {
                            if (genre.slug.isEmpty) {
                              _openCategory('Semua Film Terbaru', '/latest');
                            } else {
                              _onGenreSelected(genre.slug);
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFA855F7) : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFA855F7) : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                genre.title,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

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

                  // Section 6: Dynamic Selected Genre Row
                  if (_genreMovies.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildCategorySection(
                        title: '🗂️ ${_selectedGenreSlug.isNotEmpty ? "GENRE: ${_config.genres.firstWhere((g) => g.slug == _selectedGenreSlug, orElse: () => const GenreCategory(title: 'Pilihan', slug: '')).title.toUpperCase()}" : "GENRE: ACTION & POPULER"}',
                        movies: _genreMovies,
                        onSeeAll: () => _openCategory(
                          _selectedGenreSlug.isNotEmpty
                              ? 'Genre: ${_config.genres.firstWhere((g) => g.slug == _selectedGenreSlug, orElse: () => const GenreCategory(title: 'Genre', slug: '')).title}'
                              : 'Semua Film Action',
                          _selectedGenreSlug.isNotEmpty ? '/genre/$_selectedGenreSlug' : '/genre/action',
                        ),
                      ),
                    ),
                ],
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
