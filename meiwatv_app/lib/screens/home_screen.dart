import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/ad_service.dart';
import '../services/match_service.dart';
import '../theme/app_theme.dart';
import '../widgets/adsterra_banner.dart';
import '../widgets/category_chip.dart';
import '../widgets/live_badge.dart';
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
            final isLoading = snapshot.connectionState == ConnectionState.waiting && matches.isEmpty;

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
                       (!leagueLower.contains('basket') &&
                        !leagueLower.contains('volly') &&
                        !leagueLower.contains('volley') &&
                        !leagueLower.contains('tennis') &&
                        !leagueLower.contains('tenis') &&
                        !leagueLower.contains('badminton') &&
                        !leagueLower.contains('tangkis') &&
                        !titleLower.contains('basket') &&
                        !titleLower.contains('tennis') &&
                        !titleLower.contains('badminton'));
              }
              if (_selectedCategory == tabBolaBasket) {
                return sport.contains('basket') ||
                       leagueLower.contains('basket') ||
                       titleLower.contains('basket') ||
                       titleLower.contains('nba');
              }
              if (_selectedCategory == tabBolaVoli) {
                return sport.contains('voli') ||
                       leagueLower.contains('volly') ||
                       leagueLower.contains('volley') ||
                       titleLower.contains('volley') ||
                       titleLower.contains('volly');
              }
              if (_selectedCategory == tabBuluTangkis) {
                return sport.contains('tangkis') ||
                       sport.contains('badminton') ||
                       leagueLower.contains('badminton') ||
                       titleLower.contains('badminton') ||
                       titleLower.contains('bulutangkis');
              }
              if (_selectedCategory == tabTenis) {
                return sport.contains('tenis') ||
                       leagueLower.contains('tennis') ||
                       leagueLower.contains('tenis') ||
                       titleLower.contains('tennis') ||
                       titleLower.contains('tenis');
              }
              if (_selectedCategory == tabLainnya) {
                return sport.contains('lainnya') ||
                       leagueLower.contains('racing') ||
                       leagueLower.contains('esport') ||
                       leagueLower.contains('combat') ||
                       titleLower.contains('f1') ||
                       titleLower.contains('motogp');
              }
              return false;
            }).toList();

            final liveCount = matches.where((m) => m.isLive).length;

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isTvOrDesktop = width > 900;
                final isTablet = width > 600 && width <= 900;

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
                    await _matchService.refreshOnlineMatches();
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Top Bar / Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Logo Meiwa Mobile (Tampilan Bersih Tanpa Teks Lama)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: 46,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Text(
                                    'MEIWATV',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),

                              // Real-time Status Badge & Saweria & Refresh Button
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Tombol Donasi Saweria (Sesuai Link nonton Online)
                                  InkWell(
                                    onTap: () => AdService().openSaweria(),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'Saweria',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
                                    tooltip: 'Perbarui Jadwal & Siaran Live',
                                    onPressed: () async {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Memperbarui data siaran terbaru dari sumber online...'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                      await _matchService.refreshOnlineMatches();
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$liveCount Live Match',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 12,
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
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: SizedBox(
                          height: 42,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              return CategoryChip(
                                label: cat,
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

                    // Featured Hero Banner (If any live match is available)
                    if (matches.any((m) => m.isLive))
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: _buildFeaturedHero(
                            matches.firstWhere((m) => m.isLive),
                            isTvOrDesktop,
                          ),
                        ),
                      ),

                    // Match List / Grid Section Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else if (filteredMatches.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
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
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
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
                                        foregroundColor: Colors.black,
                                      ),
                                      icon: const Icon(Icons.sports_soccer_rounded, size: 16),
                                      onPressed: () {
                                        setState(() => _selectedCategory = tabSepakBola);
                                      },
                                      label: const Text('⚽ Sepak Bola Hari Ini'),
                                    ),
                                    FilledButton.tonalIcon(
                                      icon: const Icon(Icons.sports_basketball_rounded, size: 16),
                                      onPressed: () {
                                        setState(() => _selectedCategory = tabBolaBasket);
                                      },
                                      label: const Text('🏀 Bola Basket'),
                                    ),
                                    FilledButton.tonalIcon(
                                      icon: const Icon(Icons.sports_volleyball_rounded, size: 16),
                                      onPressed: () {
                                        setState(() => _selectedCategory = tabBolaVoli);
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
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            mainAxisExtent: 220,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final match = filteredMatches[index];
                              return TvFocusableCard(
                                match: match,
                                onTap: () => _openPlayer(match),
                              );
                            },
                            childCount: filteredMatches.length,
                          ),
                        ),
                      ),
                      // Iklan Banner Adsterra (Sesuai Link nonton Online)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 24, top: 8),
                          child: AdsterraBanner(
                            height: 60,
                            width: 468,
                            adKey: 'b3ebfb84dfe7f276ec8ca6b0601afc33',
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

  Widget _buildFeaturedHero(MatchModel match, bool isTv) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2A44),
            Color(0xFF0F1826),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const LiveBadge(isLive: true, text: 'PERTANDINGAN UTAMA HARI INI'),
                            const SizedBox(width: 8),
                            Text(
                              match.league.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.cyanAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${match.homeTeam} vs ${match.awayTeam}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _openPlayer(match),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text(
                            'NONTON LANGSUNG (LIVE)',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isTv) ...[
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.tv_rounded,
                      size: 80,
                      color: AppColors.primaryGlow,
                    ),
                  ],
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerScreen(match: match),
      ),
    );
  }
}
