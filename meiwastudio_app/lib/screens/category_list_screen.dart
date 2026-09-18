import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../services/lk21_scraper_service.dart';
import '../widgets/tv_focusable_widget.dart';
import '../widgets/tv_movie_card.dart';
import 'movie_detail_screen.dart';

class CategoryListScreen extends StatefulWidget {
  final String title;
  final String endpoint;

  const CategoryListScreen({
    super.key,
    required this.title,
    required this.endpoint,
  });

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final LK21ScraperService _scraper = LK21ScraperService();
  final List<Movie> _movies = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    if (page == 1) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final newItems = await _scraper.fetchEndpoint(widget.endpoint, page: page);
      if (mounted) {
        setState(() {
          if (page == 1) {
            _movies.clear();
            _movies.addAll(newItems);
          } else {
            _movies.addAll(newItems);
          }
          _currentPage = page;
          _hasMore = newItems.isNotEmpty;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('[CategoryListScreen] Error loading page $page: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _openDetail(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E131F),
        elevation: 0,
        leading: TVFocusableWidget(
          autofocus: true,
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              '${_movies.length} Judul • Halaman $_currentPage',
              style: TextStyle(color: const Color(0xFFA855F7).withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => _loadPage(1),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
                  ),
                  SizedBox(height: 14),
                  Text('Memuat daftar film...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                        final movie = _movies[index];
                        return TVMovieCard(
                          movie: movie,
                          onTap: () => _openDetail(movie),
                        );
                      },
                      childCount: _movies.length,
                    ),
                  ),
                ),

                // Pagination / Load More Button
                if (_hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: TVFocusableWidget(
                        onTap: () {
                          if (!_isLoadingMore) {
                            _loadPage(_currentPage + 1);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A29),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
                          ),
                          child: Center(
                            child: _isLoadingMore
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.expand_more_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Muat Halaman Berikutnya',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
    );
  }
}
