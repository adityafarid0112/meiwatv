import 'dart:async';
import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import 'live_badge.dart';
import 'team_logo_widget.dart';

class HeroMatchSlider extends StatefulWidget {
  final List<MatchModel> matches;
  final bool isTv;
  final void Function(MatchModel) onMatchTap;

  const HeroMatchSlider({
    super.key,
    required this.matches,
    required this.isTv,
    required this.onMatchTap,
  });

  @override
  State<HeroMatchSlider> createState() => _HeroMatchSliderState();
}

class _HeroMatchSliderState extends State<HeroMatchSlider> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.matches.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.matches.length <= 1) return;
      final nextPage = (_currentPage + 1) % widget.matches.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matches.isEmpty) return const SizedBox.shrink();
    final count = widget.matches.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.isTv ? 245 : 225,
          child: PageView.builder(
            controller: _pageController,
            itemCount: count,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final match = widget.matches[index];
              return _buildCard(match);
            },
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (index) {
              final isActive = index == _currentPage;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryLight : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primaryGlow.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildCard(MatchModel match) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2E4A),
            Color(0xFF0F1826),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Ambient neon accent line
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: match.isLive
                        ? [AppColors.liveRed, AppColors.goldAccent]
                        : [AppColors.primary, AppColors.cyanAccent],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header: Status Badge & League Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LiveBadge(
                        isLive: match.isLive,
                        text: match.isLive
                            ? 'PERTANDINGAN UTAMA (LIVE)'
                            : 'PERTANDINGAN UTAMA',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.league.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: AppColors.cyanAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Center Teams Layout with Official Logos / Country Flags
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        // Home Team
                        Expanded(
                          child: Row(
                            children: [
                              TeamLogoWidget(
                                teamName: match.homeTeam,
                                logoUrl: match.homeLogo,
                                size: 48,
                                accentColor: AppColors.primary,
                                sportCategory: match.sportCategory,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  match.homeTeam,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Score or VS Badge
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: match.hasScore
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1F3D6D),
                                        Color(0xFF10213E),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.cyanAccent,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.cyanAccent.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        match.scoreText ??
                                            '${match.homeScore} - ${match.awayScore}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      if (match.matchMinute != null &&
                                          match.matchMinute!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          match.matchMinute!,
                                          style: const TextStyle(
                                            color: AppColors.cyanAccent,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.goldAccent.withValues(alpha: 0.7),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'VS',
                                    style: TextStyle(
                                      color: AppColors.goldAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                        ),

                        // Away Team
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  match.awayTeam,
                                  maxLines: 2,
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              TeamLogoWidget(
                                teamName: match.awayTeam,
                                logoUrl: match.awayLogo,
                                size: 48,
                                accentColor: AppColors.cyanAccent,
                                sportCategory: match.sportCategory,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Action CTA Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Kickoff info
                      Row(
                        children: [
                          Icon(
                            match.isLive
                                ? Icons.sensors_rounded
                                : Icons.schedule_rounded,
                            size: 15,
                            color: match.isLive
                                ? AppColors.liveRed
                                : AppColors.cyanAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            match.isLive ? 'Sedang Berlangsung' : match.kickoffText,
                            style: TextStyle(
                              color: match.isLive
                                  ? AppColors.liveRed
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      // CTA Button
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => widget.onMatchTap(match),
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'SIARAN LANGSUNG (LIVE)',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: Colors.white,
                          ),
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
  }
}
