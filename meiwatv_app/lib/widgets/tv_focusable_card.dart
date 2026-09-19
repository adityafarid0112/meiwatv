import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import 'live_badge.dart';
import 'team_logo_widget.dart';

class TvFocusableCard extends StatefulWidget {
  final MatchModel match;
  final VoidCallback onTap;

  const TvFocusableCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  @override
  State<TvFocusableCard> createState() => _TvFocusableCardState();
}

class _TvFocusableCardState extends State<TvFocusableCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isFocused ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isFocused
                    ? [
                        AppColors.surfaceElevated,
                        const Color(0xFF14243B),
                      ]
                    : [
                        AppColors.surface,
                        const Color(0xFF0D1422),
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isFocused ? AppColors.primary : AppColors.border,
                width: _isFocused ? 2.5 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primaryGlow.withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Ambient stadium light banner inside card
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
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header: League & Live Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    _getSportIcon(match.sportCategory, match.league, match.title),
                                    size: 13,
                                    color: _getSportColor(match.sportCategory, match.league, match.title),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      match.league.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _getSportColor(match.sportCategory, match.league, match.title),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            LiveBadge(
                              isLive: match.isLive,
                              text: match.isLive ? 'LIVE' : match.kickoffText,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Match Teams Versus Layout
                        Row(
                          children: [
                            // Home Team
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TeamLogoWidget(
                                    teamName: match.homeTeam,
                                    logoUrl: match.homeLogo,
                                    size: 42,
                                    accentColor: AppColors.primary,
                                    sportCategory: match.sportCategory,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    match.homeTeam,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Center Score or VS Badge
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: match.hasScore
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF1B3258),
                                            Color(0xFF0F1E38),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.cyanAccent.withValues(alpha: 0.8),
                                          width: 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.cyanAccent.withValues(alpha: 0.25),
                                            blurRadius: 5,
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
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          if (match.matchMinute != null &&
                                              match.matchMinute!.isNotEmpty) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              match.matchMinute!,
                                              style: const TextStyle(
                                                color: AppColors.cyanAccent,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: const Text(
                                        'VS',
                                        style: TextStyle(
                                          color: AppColors.goldAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                            ),

                            // Away Team
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TeamLogoWidget(
                                    teamName: match.awayTeam,
                                    logoUrl: match.awayLogo,
                                    size: 42,
                                    accentColor: AppColors.cyanAccent,
                                    sportCategory: match.sportCategory,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    match.awayTeam,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 6),

                        // Footer: Stream Jalur Indicators & Action CTA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Jalur tag list
                            Row(
                              children: [
                                _buildJalurTag('Jalur 1', match.streamJalur1.isNotEmpty),
                                const SizedBox(width: 3),
                                _buildJalurTag('Jalur 2', match.streamJalur2.isNotEmpty),
                                const SizedBox(width: 3),
                                _buildJalurTag('Jalur 3', match.streamJalur3.isNotEmpty),
                              ],
                            ),

                            // Play Button Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isFocused ? AppColors.primary : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    size: 15,
                                    color: _isFocused
                                        ? Colors.white
                                        : AppColors.cyanAccent,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Nonton',
                                    style: TextStyle(
                                      color: _isFocused
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJalurTag(String label, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.surfaceLight : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isAvailable ? AppColors.textSecondary : AppColors.textMuted.withValues(alpha: 0.5),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getSportIcon(String sportCategory, String league, String title) {
    final sport = sportCategory.toLowerCase();
    final l = league.toLowerCase();
    final t = title.toLowerCase();

    if (sport.contains('basket') || l.contains('basket') || t.contains('basket') || t.contains('nba')) {
      return Icons.sports_basketball_rounded;
    }
    if (sport.contains('voli') || sport.contains('volly') || sport.contains('volley') || l.contains('volly') || l.contains('volley')) {
      return Icons.sports_volleyball_rounded;
    }
    if (sport.contains('tangkis') || sport.contains('badminton') || l.contains('badminton') || t.contains('badminton')) {
      return Icons.sports_tennis_rounded;
    }
    if (sport.contains('tenis') || sport.contains('tennis') || l.contains('tennis') || l.contains('tenis')) {
      return Icons.sports_tennis_rounded;
    }
    if (sport.contains('moto') || sport.contains('f1') || sport.contains('formula') || sport.contains('racing') || l.contains('motogp')) {
      return Icons.sports_motorsports_rounded;
    }
    if (sport.contains('esport') || sport.contains('game') || sport.contains('dota') || sport.contains('csgo') || sport.contains('lol')) {
      return Icons.sports_esports_rounded;
    }
    if (sport.contains('ufc') || sport.contains('mma') || sport.contains('tinju') || sport.contains('boxing')) {
      return Icons.sports_mma_rounded;
    }
    return Icons.sports_soccer_rounded;
  }

  Color _getSportColor(String sportCategory, String league, String title) {
    final sport = sportCategory.toLowerCase();
    final l = league.toLowerCase();
    final t = title.toLowerCase();

    if (sport.contains('basket') || l.contains('basket') || t.contains('basket') || t.contains('nba')) {
      return const Color(0xFFFF9800); // Orange
    }
    if (sport.contains('voli') || sport.contains('volly') || sport.contains('volley') || l.contains('volly') || l.contains('volley')) {
      return const Color(0xFFFFD54F); // Yellow
    }
    if (sport.contains('tangkis') || sport.contains('badminton') || l.contains('badminton') || t.contains('badminton')) {
      return const Color(0xFF00E676); // Emerald Green
    }
    if (sport.contains('tenis') || sport.contains('tennis') || l.contains('tennis') || l.contains('tenis')) {
      return const Color(0xFFAEEA00); // Lime
    }
    if (sport.contains('moto') || sport.contains('f1') || sport.contains('racing') || sport.contains('esport') || sport.contains('game')) {
      return const Color(0xFFE040FB); // Magenta
    }
    return AppColors.cyanAccent;
  }
}
