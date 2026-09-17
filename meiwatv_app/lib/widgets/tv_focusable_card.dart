import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import 'live_badge.dart';

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
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
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
                                  const Icon(
                                    Icons.sports_soccer_rounded,
                                    size: 14,
                                    color: AppColors.cyanAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      match.league.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.cyanAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            LiveBadge(
                              isLive: match.isLive,
                              text: match.isLive ? 'LIVE' : match.kickoffText,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Match Teams Versus Layout
                        Row(
                          children: [
                            // Home Team
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTeamAvatar(match.homeTeam, AppColors.primary),
                                  const SizedBox(height: 6),
                                  Text(
                                    match.homeTeam,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // VS Badge
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border, width: 0.8),
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTeamAvatar(match.awayTeam, AppColors.cyanAccent),
                                  const SizedBox(height: 6),
                                  Text(
                                    match.awayTeam,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 8),

                        // Footer: Stream Jalur Indicators & Action CTA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Jalur tag list
                            Row(
                              children: [
                                _buildJalurTag('Jalur 1', match.streamJalur1.isNotEmpty),
                                const SizedBox(width: 4),
                                _buildJalurTag('Jalur 2', match.streamJalur2.isNotEmpty),
                                const SizedBox(width: 4),
                                _buildJalurTag('Jalur 3', match.streamJalur3.isNotEmpty),
                              ],
                            ),

                            // Play Button Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _isFocused ? AppColors.primary : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    size: 16,
                                    color: _isFocused ? Colors.black : AppColors.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Nonton',
                                    style: TextStyle(
                                      color: _isFocused ? Colors.black : AppColors.textPrimary,
                                      fontSize: 11,
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

  Widget _buildTeamAvatar(String teamName, Color accentColor) {
    final initial = teamName.isNotEmpty ? teamName.substring(0, 1).toUpperCase() : 'T';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: accentColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
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
}
