import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie_model.dart';
import '../services/lk21_scraper_service.dart';
import '../services/remote_config_service.dart';
import '../widgets/tv_focusable_widget.dart';
import '../widgets/tv_movie_card.dart';
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
  List<Movie> _popularMovies = [];
  List<Movie> _genreMovies = [];
  Movie? _featuredMovie;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    setState(() => _isLoading = true);
    await _config.initConfig();
    await _loadMovies();
  }

  Future<void> _loadMovies() async {
    try {
      final popular = await _scraper.fetchPopularMovies();
      final genreList = await _scraper.fetchMoviesByGenre(_selectedGenreSlug);

      if (mounted) {
        setState(() {
          _popularMovies = popular;
          _genreMovies = genreList;
          if (_popularMovies.isNotEmpty) {
            _featuredMovie = _popularMovies.first;
          } else if (_genreMovies.isNotEmpty) {
            _featuredMovie = _genreMovies.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error loading movies: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onGenreSelected(String slug) {
    if (_selectedGenreSlug == slug) return;
    setState(() {
      _selectedGenreSlug = slug;
      _isLoading = true;
    });
    _loadGenreMovies(slug);
  }

  Future<void> _loadGenreMovies(String slug) async {
    final list = await _scraper.fetchMoviesByGenre(slug);
    if (mounted) {
      setState(() {
        _genreMovies = list;
        _isLoading = false;
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
        _genreMovies = results;
        _selectedGenreSlug = 'search';
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
              // 1. Top Header Navbar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      // Brand Logo Image (meiwa studio.png)
                      Image.asset(
                        'assets/images/header_logo.png',
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/images/logo_icon.png',
                          height: 34,
                        ),
                      ),
                      const Spacer(),
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
                              Icon(Icons.search_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text('Cari Film', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Refresh / Reload Mirror Button
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
                          child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Hero Featured Movie Banner (if available)
              if (_featuredMovie != null && _selectedGenreSlug != 'search')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: TVFocusableWidget(
                      onTap: () => _openDetail(_featuredMovie!),
                      scaleFactor: 1.02,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 200,
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
                                    Colors.black.withValues(alpha: 0.9),
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
                                      '🔥 FILM PILIHAN HARI INI',
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

              // 3. Category / Genre Bar
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _config.genres.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final genre = _config.genres[index];
                      final isSelected = _selectedGenreSlug == genre.slug;

                      return TVFocusableWidget(
                        onTap: () => _onGenreSelected(genre.slug),
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
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
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

              // 4. Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        _selectedGenreSlug.isEmpty
                            ? 'Katalog Film & Series'
                            : (_selectedGenreSlug == 'search' ? 'Hasil Pencarian' : 'Genre: ${_config.genres.firstWhere((g) => g.slug == _selectedGenreSlug, orElse: () => const GenreCategory(title: 'Film', slug: '')).title}'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (_genreMovies.isNotEmpty)
                        Text(
                          '${_genreMovies.length} Judul',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 5. Loading State
              if (_isLoading)
                const SliverFillRemaining(
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
                          'Menghubungkan ke Mirror LK21...',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              // 6. Empty State
              else if (_genreMovies.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.movie_outlined, color: Colors.white24, size: 64),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada film ditemukan',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Silakan coba ganti genre atau gunakan pencarian lain.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA855F7),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _onGenreSelected(''),
                          child: const Text('Tampilkan Semua Film'),
                        ),
                      ],
                    ),
                  ),
                )
              // 7. Movie Grid
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                        final movie = _genreMovies[index];
                        return TVMovieCard(
                          movie: movie,
                          onTap: () => _openDetail(movie),
                        );
                      },
                      childCount: _genreMovies.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
