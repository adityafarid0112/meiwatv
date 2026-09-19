import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/match_model.dart';
import '../services/ad_service.dart';
import '../services/match_service.dart';
import '../theme/app_theme.dart';
import '../widgets/adsterra_banner.dart';
import '../widgets/category_chip.dart';
import '../widgets/hero_match_slider.dart';
import '../widgets/tv_focusable_button.dart';
import '../widgets/tv_focusable_card.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MatchService _matchService = MatchService();
  static const String tabLive = '🔴 Live';
  static const String tabSepakBola = '⚽ Sepak Bola';
  static const String tabBolaBasket = '🏀 Bola Basket';
  static const String tabBolaVoli = '🏐 Bola Voli';
  static const String tabBuluTangkis = '🏸 Bulu Tangkis';
  static const String tabTenis = '🎾 Tenis';
  static const String tabLainnya = '🏎️ Olahraga Lainnya';

  String _selectedCategory = tabLive;
  final List<String> _categories = [
    tabLive,
    tabSepakBola,
    tabBolaBasket,
    tabBolaVoli,
    tabBuluTangkis,
    tabTenis,
    tabLainnya,
  ];

  @override
  void initState() {
    super.initState();
    AdService().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<MatchModel>>(
          stream: _matchService.getMatchesStream(),
          builder: (context, snapshot) {
            final matches = snapshot.data ?? [];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                matches.isEmpty;

            // Filter matches based on selected category
            final filteredMatches = matches.where((match) {
              if (_selectedCategory == tabLive) {
                // Tab Live: Kumpulan dari semua kategori siaran olahraga yang sedang live
                return match.isLive;
              }

              final sport = match.sportCategory.toLowerCase();
              final leagueLower = match.league.toLowerCase();
              final titleLower = match.title.toLowerCase();

              if (_selectedCategory == tabSepakBola) {
                return sport.contains('sepak bola') ||
                    sport.contains('football');
              }
              if (_selectedCategory == tabBolaBasket) {
                return sport.contains('basket') ||
                    leagueLower.contains('basket') ||
                    titleLower.contains('basket') ||
                    titleLower.contains('nba');
              }
              if (_selectedCategory == tabBolaVoli) {
                return sport.contains('voli') ||
                    sport.contains('volly') ||
                    sport.contains('volley') ||
                    leagueLower.contains('volly') ||
                    leagueLower.contains('volley');
              }
              if (_selectedCategory == tabBuluTangkis) {
                return sport.contains('tangkis') ||
                    sport.contains('badminton') ||
                    leagueLower.contains('badminton') ||
                    titleLower.contains('badminton');
              }
              if (_selectedCategory == tabTenis) {
                return sport.contains('tenis') ||
                    sport.contains('tennis') ||
                    leagueLower.contains('tennis') ||
                    leagueLower.contains('tenis');
              }
              if (_selectedCategory == tabLainnya) {
                return sport.contains('lainnya') ||
                    (!sport.contains('sepak bola') &&
                        !sport.contains('basket') &&
                        !sport.contains('voli') &&
                        !sport.contains('tangkis') &&
                        !sport.contains('tenis'));
              }
              return false;
            }).toList();

            final liveCount = matches.where((m) => m.isLive).length;

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isTvOrDesktop = width > 900;
                final isTablet = width > 600 && width <= 900;
                final horizontalPadding = isTvOrDesktop ? 32.0 : (isTablet ? 22.0 : 14.0);

                int crossAxisCount = 1;
                if (isTvOrDesktop) {
                  crossAxisCount = 3;
                } else if (isTablet) {
                  crossAxisCount = 2;
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () async {
                    await _matchService.refreshOnlineMatches(forceDirectScrape: true);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Top Bar / Header with TV-safe overscan padding
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            isTvOrDesktop ? 26 : 10,
                            horizontalPadding,
                            8,
                          ),
                          child: Row(
                            children: [
                              // Logo Meiwa Sports
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  'assets/images/meiwa sports.png',
                                  height: width < 500
                                      ? 30
                                      : (isTvOrDesktop ? 46 : 38),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Text(
                                        'MEIWA SPORTS',
                                        style: TextStyle(
                                          color: AppColors.cyanAccent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                ),
                              ),
                              const Spacer(),

                              // Real-time Status Badge & Saweria & Refresh Button
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Tombol Donasi Saweria (Focusable with D-pad)
                                  TvFocusableButton(
                                    onTap: () => AdService().openSaweria(),
                                    borderRadius: BorderRadius.circular(14),
                                    focusedBorderColor: const Color(0xFFFF9800),
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
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFF9800,
                                            ).withValues(alpha: 0.35),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.volunteer_activism_rounded,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          if (width >= 350) ...[
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Saweria',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Tombol Share (Focusable with D-pad)
                                  TvFocusableButton(
                                    onTap: () {
                                      SharePlus.instance.share(
                                        ShareParams(
                                          text:
                                              'Ayo tonton siaran langsung sepak bola, basket, bulu tangkis, tenis dan olahraga lainnya gratis tanpa buffering di MeiwaSports!\n\nLink Donasi & Support: https://saweria.co/meiwatv',
                                          subject:
                                              'Aplikasi Streaming Olahraga MeiwaSports',
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    padding: const EdgeInsets.all(4),
                                    tooltip: 'Bagikan Aplikasi MeiwaSports',
                                    child: const Icon(
                                      Icons.share_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Tombol Refresh (Focusable with D-pad)
                                  TvFocusableButton(
                                    onTap: () async {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Memperbarui data siaran terbaru dari sumber online...',
                                          ),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                      await _matchService.refreshOnlineMatches();
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    padding: const EdgeInsets.all(4),
                                    tooltip: 'Perbarui Jadwal & Siaran Live',
                                    child: const Icon(
                                      Icons.refresh_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppColors.liveRed,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$liveCount Live',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // League & Category Selector Chips (Horizontal Scrollable with D-Pad)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            4,
                            horizontalPadding,
                            14,
                          ),
                          child: SizedBox(
                            height: 44,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final count = _getCategoryCount(cat, matches);
                                return CategoryChip(
                                  label: '$cat ($count)',
                                  isSelected: _selectedCategory == cat,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = cat;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Featured Hero Slider
                      if (matches.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              0,
                              horizontalPadding,
                              18,
                            ),
                            child: _buildFeaturedHeroSlider(
                              matches,
                              isTvOrDesktop,
                            ),
                          ),
                        ),

                      // Match List / Grid Section Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedCategory == tabLive
                                    ? '🔴 SIARAN LIVE SEKARANG'
                                    : '$_selectedCategory HARI INI (00:00 - 23:59)',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${filteredMatches.length} Pertandingan',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Match Content Grid or Loading Indicator
                      if (isLoading)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (filteredMatches.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 16,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.sports_soccer_outlined,
                                    size: 52,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedCategory == tabLive
                                        ? 'Saat ini belum ada siaran yang sedang kick-off langsung.\nSilakan cek jadwal lengkap hari ini di bawah:'
                                        : 'Tidak ada pertandingan dalam kategori ini hari ini.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: const Icon(
                                          Icons.sports_soccer_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(
                                            () => _selectedCategory =
                                                tabSepakBola,
                                          );
                                        },
                                        label: const Text(
                                          '⚽ Sepak Bola Hari Ini',
                                        ),
                                      ),
                                      FilledButton.tonalIcon(
                                        icon: const Icon(
                                          Icons.sports_basketball_rounded,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          setState(
                                            () => _selectedCategory =
                                                tabBolaBasket,
                                          );
                                        },
                                        label: const Text('🏀 Bola Basket'),
                                      ),
                                      FilledButton.tonalIcon(
                                        icon: const Icon(
                                          Icons.sports_volleyball_rounded,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          setState(
                                            () =>
                                                _selectedCategory = tabBolaVoli,
                                          );
                                        },
                                        label: const Text('🏐 Bola Voli'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (_selectedCategory == tabLive) ...[
                        for (final section in _groupLiveMatches(filteredMatches)) ...[
                          SliverToBoxAdapter(
                            child: _buildLiveSportSeparator(
                              section: section,
                              horizontalPadding: horizontalPadding,
                              isTv: isTvOrDesktop,
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              0,
                              horizontalPadding,
                              16,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    mainAxisExtent: isTvOrDesktop ? 175 : 182,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final match = section.matches[index];
                                return TvFocusableCard(
                                  match: match,
                                  onTap: () => _openPlayer(match),
                                );
                              }, childCount: section.matches.length),
                            ),
                          ),
                        ],
                        // Iklan Banner Adsterra
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 24, top: 8),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: AdsterraBanner(
                                  height: 60,
                                  width: 468,
                                  adKey: 'b3ebfb84dfe7f276ec8ca6b0601afc33',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            16,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  mainAxisExtent: isTvOrDesktop ? 175 : 182,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final match = filteredMatches[index];
                              return TvFocusableCard(
                                match: match,
                                onTap: () => _openPlayer(match),
                              );
                            }, childCount: filteredMatches.length),
                          ),
                        ),
                        // Iklan Banner Adsterra (Sesuai Link nonton Online)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 24, top: 8),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: AdsterraBanner(
                                  height: 60,
                                  width: 468,
                                  adKey: 'b3ebfb84dfe7f276ec8ca6b0601afc33',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedHeroSlider(List<MatchModel> matches, bool isTv) {
    // Ambil pertandingan live, jika kurang dari 4 sertakan juga jadwal hari ini
    final liveMatches = matches.where((m) => m.isLive).toList();
    final sliderItems = liveMatches.isNotEmpty
        ? liveMatches.take(6).toList()
        : matches.take(5).toList();

    if (sliderItems.isEmpty) return const SizedBox.shrink();

    return HeroMatchSlider(
      matches: sliderItems,
      isTv: isTv,
      onMatchTap: _openPlayer,
    );
  }

  int _getCategoryCount(String cat, List<MatchModel> all) {
    if (cat == tabLive) {
      return all.where((m) => m.isLive).length;
    }
    return all.where((match) {
      final sport = match.sportCategory.toLowerCase();
      final leagueLower = match.league.toLowerCase();
      final titleLower = match.title.toLowerCase();

      if (cat == tabSepakBola) {
        return sport.contains('sepak bola') || sport.contains('football');
      }
      if (cat == tabBolaBasket) {
        return sport.contains('basket') ||
            leagueLower.contains('basket') ||
            titleLower.contains('basket') ||
            titleLower.contains('nba');
      }
      if (cat == tabBolaVoli) {
        return sport.contains('voli') ||
            sport.contains('volly') ||
            sport.contains('volley') ||
            leagueLower.contains('volly') ||
            leagueLower.contains('volley');
      }
      if (cat == tabBuluTangkis) {
        return sport.contains('tangkis') ||
            sport.contains('badminton') ||
            leagueLower.contains('badminton') ||
            titleLower.contains('badminton');
      }
      if (cat == tabTenis) {
        return sport.contains('tenis') ||
            sport.contains('tennis') ||
            leagueLower.contains('tennis') ||
            leagueLower.contains('tenis');
      }
      if (cat == tabLainnya) {
        return sport.contains('lainnya') ||
            (!sport.contains('sepak bola') &&
                !sport.contains('basket') &&
                !sport.contains('voli') &&
                !sport.contains('tangkis') &&
                !sport.contains('tenis'));
      }
      return false;
    }).length;
  }

  List<_LiveSportSection> _groupLiveMatches(List<MatchModel> liveMatches) {
    final Map<String, List<MatchModel>> groups = {
      'Sepak Bola': [],
      'Bola Basket': [],
      'Bulu Tangkis': [],
      'Tenis': [],
      'Bola Voli': [],
      'Olahraga Lainnya': [],
    };

    for (final match in liveMatches) {
      final sport = match.sportCategory.toLowerCase();
      final league = match.league.toLowerCase();
      final title = match.title.toLowerCase();

      if (sport.contains('sepak bola') ||
          sport.contains('football') ||
          sport.contains('soccer')) {
        groups['Sepak Bola']!.add(match);
      } else if (sport.contains('basket') ||
          league.contains('basket') ||
          title.contains('basket') ||
          title.contains('nba')) {
        groups['Bola Basket']!.add(match);
      } else if (sport.contains('tangkis') ||
          sport.contains('badminton') ||
          league.contains('badminton') ||
          title.contains('badminton')) {
        groups['Bulu Tangkis']!.add(match);
      } else if (sport.contains('tenis') ||
          sport.contains('tennis') ||
          league.contains('tennis') ||
          league.contains('tenis')) {
        groups['Tenis']!.add(match);
      } else if (sport.contains('voli') ||
          sport.contains('volly') ||
          sport.contains('volley') ||
          league.contains('volly') ||
          league.contains('volley')) {
        groups['Bola Voli']!.add(match);
      } else {
        groups['Olahraga Lainnya']!.add(match);
      }
    }

    final List<_LiveSportSection> sections = [];
    if (groups['Sepak Bola']!.isNotEmpty) {
      sections.add(
        _LiveSportSection(
          title: '⚽ Sepak Bola Live',
          icon: Icons.sports_soccer_rounded,
          accentColor: AppColors.cyanAccent,
          matches: groups['Sepak Bola']!,
        ),
      );
    }
    if (groups['Bola Basket']!.isNotEmpty) {
      sections.add(
        _LiveSportSection(
          title: '🏀 Bola Basket Live',
          icon: Icons.sports_basketball_rounded,
          accentColor: const Color(0xFFFF9800),
          matches: groups['Bola Basket']!,
        ),
      );
    }
    if (groups['Bulu Tangkis']!.isNotEmpty) {
      sections.add(
        _LiveSportSection(
          title: '🏸 Bulu Tangkis Live',
          icon: Icons.sports_tennis_rounded,
          accentColor: const Color(0xFF00E676),
          matches: groups['Bulu Tangkis']!,
        ),
      );
    }
    if (groups['Tenis']!.isNotEmpty) {
      sections.add(
        _LiveSportSection(
          title: '🎾 Tenis Live',
          icon: Icons.sports_tennis_rounded,
          accentColor: const Color(0xFFAEEA00),
          matches: groups['Tenis']!,
        ),
      );
    }
    if (groups['Bola Voli']!.isNotEmpty) {
      sections.add(
        _LiveSportSection(
          title: '🏐 Bola Voli Live',
          icon: Icons.sports_volleyball_rounded,
          accentColor: const Color(0xFFFFD54F),
          matches: groups['Bola Voli']!,
        ),
      );
    }
    if (groups['Olahraga Lainnya']!.isNotEmpty) {
      sections.add(
        _LiveSportSection(
          title: '🏎️ Olahraga Lainnya & E-Sports Live',
          icon: Icons.sports_motorsports_rounded,
          accentColor: const Color(0xFFE040FB),
          matches: groups['Olahraga Lainnya']!,
        ),
      );
    }

    return sections;
  }

  Widget _buildLiveSportSeparator({
    required _LiveSportSection section,
    required double horizontalPadding,
    required bool isTv,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              section.accentColor.withValues(alpha: 0.16),
              AppColors.surfaceElevated,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: section.accentColor, width: 4),
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
            right: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
            bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: section.accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: section.accentColor.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Icon(
                section.icon,
                size: 16,
                color: section.accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                section.title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.liveRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.liveRed.withValues(alpha: 0.6),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.liveRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${section.matches.length} LIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlayer(MatchModel match) {
    AdService().triggerPopunder();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => PlayerScreen(match: match)));
  }
}

class _LiveSportSection {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<MatchModel> matches;

  _LiveSportSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.matches,
  });
}
