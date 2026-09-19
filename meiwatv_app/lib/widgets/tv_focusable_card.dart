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
    final sportColor = _getSportColor(match.sportCategory, match.league, match.title);
    final sportIcon = _getSportIcon(match.sportCategory, match.league, match.title);

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
          scale: _isFocused ? 1.035 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isFocused
                    ? [
                        const Color(0xFF1E2F4D),
                        const Color(0xFF111E33),
                      ]
                    : [
                        const Color(0xFF131D2E),
                        const Color(0xFF0A101C),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? AppColors.primary
                    : AppColors.border.withValues(alpha: 0.8),
                width: _isFocused ? 2.2 : 1.0,
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
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // 1. Sport-Themed Vector Arena Graphics & Stadium Spotlight
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SportCardBackdropPainter(
                        sportCategory: match.sportCategory,
                        isLive: match.isLive,
                      ),
                    ),
                  ),

                  // 2. Ambient Top Neon Indicator Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 3.5,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: match.isLive
                              ? [AppColors.liveRed, AppColors.goldAccent]
                              : [sportColor, AppColors.cyanAccent],
                        ),
                      ),
                    ),
                  ),

                  // 3. Main Card Content (Optimized to fill height without awkward gap)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(11.0, 9.0, 11.0, 9.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Header: Sport Category & League + Live / Kickoff Badge ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3.5),
                                    decoration: BoxDecoration(
                                      color: sportColor.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: sportColor.withValues(alpha: 0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Icon(
                                      sportIcon,
                                      size: 12,
                                      color: sportColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      match.league.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: sportColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
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

                        // --- Versus Area: Home vs Away ---
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Home Team
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TeamLogoWidget(
                                      teamName: match.homeTeam,
                                      logoUrl: match.homeLogo,
                                      size: 40,
                                      accentColor: AppColors.primary,
                                      sportCategory: match.sportCategory,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      match.homeTeam,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Center Score or VS Pill
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: match.hasScore
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF1B3560),
                                              Color(0xFF0F203D),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.cyanAccent.withValues(alpha: 0.8),
                                            width: 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.cyanAccent.withValues(alpha: 0.25),
                                              blurRadius: 6,
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
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF18263D),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.goldAccent.withValues(alpha: 0.5),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: const Text(
                                          'VS',
                                          style: TextStyle(
                                            color: AppColors.goldAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
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
                                      size: 40,
                                      accentColor: AppColors.cyanAccent,
                                      sportCategory: match.sportCategory,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      match.awayTeam,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- Footer: Jalur 1, 2, 3 Indicators & Nonton CTA ---
                        Container(
                          padding: const EdgeInsets.only(top: 6.0),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.border.withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Jalur Capsules with Live Active Dots
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildJalurTag('Jalur 1', match.streamJalur1.isNotEmpty),
                                  const SizedBox(width: 3.5),
                                  _buildJalurTag('Jalur 2', match.streamJalur2.isNotEmpty),
                                  const SizedBox(width: 3.5),
                                  _buildJalurTag('Jalur 3', match.streamJalur3.isNotEmpty),
                                ],
                              ),

                              // Play Button Indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isFocused
                                        ? [AppColors.primary, AppColors.cyanAccent]
                                        : [
                                            const Color(0xFF1B3050),
                                            const Color(0xFF11223B),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _isFocused
                                        ? AppColors.cyanAccent
                                        : AppColors.border.withValues(alpha: 0.7),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      size: 14,
                                      color: _isFocused ? Colors.white : AppColors.cyanAccent,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Nonton',
                                      style: TextStyle(
                                        color: _isFocused ? Colors.white : AppColors.textPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFF142136) : const Color(0xFF0E1624),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isAvailable
              ? AppColors.cyanAccent.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.2),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4.5,
            height: 4.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAvailable ? const Color(0xFF00E676) : Colors.grey.withValues(alpha: 0.4),
              boxShadow: isAvailable
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: 0.7),
                        blurRadius: 3,
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: isAvailable ? AppColors.textSecondary : AppColors.textMuted.withValues(alpha: 0.5),
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

/// CustomPainter for Sport-Themed Pitch / Court Field Markings & Stadium Lights
class _SportCardBackdropPainter extends CustomPainter {
  final String sportCategory;
  final bool isLive;

  _SportCardBackdropPainter({
    required this.sportCategory,
    required this.isLive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cat = sportCategory.toLowerCase();

    // 1. Stadium Floodlight Spotlight from top center
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.6),
        radius: 0.95,
        colors: [
          (isLive ? AppColors.liveRed : AppColors.primary).withValues(alpha: 0.12),
          AppColors.cyanAccent.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // 2. Vector Field / Pitch / Court Line Markings
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.045);

    if (cat.contains('basket')) {
      // Basketball Court: 3-Point arc & Key circle
      final bottomCenter = Offset(size.width * 0.5, size.height * 1.05);
      canvas.drawCircle(bottomCenter, size.width * 0.45, linePaint);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.72),
          width: size.width * 0.32,
          height: size.height * 0.5,
        ),
        linePaint,
      );
    } else if (cat.contains('tenis') || cat.contains('voli') || cat.contains('badminton')) {
      // Court Grid & Net Line
      canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), linePaint);
      canvas.drawLine(Offset(size.width * 0.22, 0), Offset(size.width * 0.22, size.height), linePaint);
      canvas.drawLine(Offset(size.width * 0.78, 0), Offset(size.width * 0.78, size.height), linePaint);
    } else {
      // Football Pitch: Center Circle & Halfway Line
      final pitchCenter = Offset(size.width * 0.5, size.height * 0.48);
      canvas.drawCircle(pitchCenter, size.width * 0.24, linePaint);
      canvas.drawLine(Offset(0, size.height * 0.48), Offset(size.width, size.height * 0.48), linePaint);

      // Subtle Corner Arcs
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(0, 0), radius: 20),
        0,
        1.57,
        false,
        linePaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width, 0), radius: 20),
        1.57,
        1.57,
        false,
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SportCardBackdropPainter oldDelegate) {
    return oldDelegate.sportCategory != sportCategory || oldDelegate.isLive != isLive;
  }
}
