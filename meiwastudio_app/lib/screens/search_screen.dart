import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../services/lk21_scraper_service.dart';
import '../widgets/tv_focusable_widget.dart';
import '../widgets/tv_movie_card.dart';
import 'movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<Movie> initialRecommendations;

  const SearchScreen({
    super.key,
    this.initialRecommendations = const [],
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LK21ScraperService _scraper = LK21ScraperService();

  List<Movie> _results = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  final List<String> _popularSuggestions = [
    'Avatar',
    'Reacher',
    'Fast & Furious',
    'Transformers',
    'Spider-Man',
    'Marvel',
    'Squid Game',
    'Queen of Tears',
    'One Piece',
    'Drakor',
    'Action',
    'Horror',
  ];

  @override
  void initState() {
    super.initState();
    _results = widget.initialRecommendations;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();

    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      setState(() {
        _results = widget.initialRecommendations;
        _isSearching = false;
      });
      return;
    }

    // 1. Instant local match from preloaded recommendations
    final qLower = cleanQuery.toLowerCase();
    final localMatches = widget.initialRecommendations.where((m) {
      return m.title.toLowerCase().contains(qLower) ||
          m.genres.any((g) => g.toLowerCase().contains(qLower)) ||
          m.slug.toLowerCase().contains(qLower);
    }).toList();

    setState(() {
      if (localMatches.isNotEmpty) {
        _results = localMatches;
      }
      _isSearching = true;
    });

    // 2. Debounced online search across LK21 & NontonDrama
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final onlineResults = await _scraper.searchMovies(cleanQuery);
      if (!mounted) return;

      if (_searchController.text.trim() == cleanQuery) {
        setState(() {
          if (onlineResults.isNotEmpty) {
            // Merge with local results without duplicates
            final seenSlugs = <String>{};
            final merged = <Movie>[];
            for (final m in [...onlineResults, ...localMatches]) {
              if (seenSlugs.add(m.slug)) {
                merged.add(m);
              }
            }
            _results = merged;
          } else if (localMatches.isEmpty) {
            _results = [];
          }
          _isSearching = false;
        });
      }
    });
  }

  void _applySuggestion(String keyword) {
    _searchController.text = keyword;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    _onQueryChanged(keyword);
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
    final query = _searchController.text.trim();
    final hasQuery = query.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E131F),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  // Back Button
                  TVFocusableWidget(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Search Text Field
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSearching
                              ? const Color(0xFFEC4899)
                              : const Color(0xFFA855F7).withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: true,
                        onChanged: _onQueryChanged,
                        onSubmitted: (val) => _onQueryChanged(val),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Cari judul film, anime, series, drakor...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA855F7), size: 20),
                          suffixIcon: hasQuery
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onQueryChanged('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading Progress Bar
            if (_isSearching)
              const LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Color(0xFF0E131F),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
              ),

            // 2. Suggestions Chips Bar
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _popularSuggestions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tag = _popularSuggestions[index];
                  final isSelected = query.toLowerCase() == tag.toLowerCase();

                  return TVFocusableWidget(
                    onTap: () => _applySuggestion(tag),
                    scaleFactor: 1.05,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFA855F7)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFA855F7)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 13,
                            color: isSelected ? Colors.white : const Color(0xFFEC4899),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tag,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. Section Title / Result Info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(
                    hasQuery
                        ? 'HASIL PENCARIAN UNTUK "$query"'
                        : '💡 REKOMENDASI FILM HARI INI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (_results.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_results.length} Film',
                        style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            // 4. Movie Grid or Empty State
            Expanded(
              child: _results.isEmpty && !_isSearching
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.04),
                              ),
                              child: const Icon(Icons.movie_filter_outlined, size: 54, color: Colors.white30),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              hasQuery
                                  ? 'Tidak ada film dengan judul "$query"'
                                  : 'Ketik judul film di kolom pencarian',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Coba gunakan kata kunci populer di atas seperti Avatar, Reacher, atau Drakor.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 900
                            ? 6
                            : (MediaQuery.of(context).size.width > 600 ? 4 : 3),
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final movie = _results[index];
                        return TVMovieCard(
                          movie: movie,
                          onTap: () => _openDetail(movie),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
