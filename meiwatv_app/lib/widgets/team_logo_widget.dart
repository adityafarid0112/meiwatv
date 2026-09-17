import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TeamLogoWidget extends StatelessWidget {
  final String teamName;
  final String? logoUrl;
  final double size;
  final Color accentColor;
  final String? sportCategory;

  const TeamLogoWidget({
    super.key,
    required this.teamName,
    this.logoUrl,
    this.size = 46,
    this.accentColor = AppColors.primary,
    this.sportCategory,
  });

  // Pemetaan bendera negara untuk turnamen internasional / timnas
  static const Map<String, String> _countryCodeMap = {
    'indonesia': 'id',
    'ina': 'id',
    'vietnam': 'vn',
    'jepang': 'jp',
    'japan': 'jp',
    'korea': 'kr',
    'south korea': 'kr',
    'china': 'cn',
    'tiongkok': 'cn',
    'thailand': 'th',
    'malaysia': 'my',
    'singapura': 'sg',
    'singapore': 'sg',
    'filipina': 'ph',
    'philippines': 'ph',
    'inggris': 'gb-eng',
    'england': 'gb-eng',
    'britania': 'gb',
    'spanyol': 'es',
    'spain': 'es',
    'jerman': 'de',
    'germany': 'de',
    'prancis': 'fr',
    'france': 'fr',
    'italia': 'it',
    'italy': 'it',
    'belanda': 'nl',
    'netherlands': 'nl',
    'portugal': 'pt',
    'argentina': 'ar',
    'brasil': 'br',
    'brazil': 'br',
    'amerika': 'us',
    'usa': 'us',
    'australia': 'au',
    'india': 'in',
    'taiwan': 'tw',
    'hong kong': 'hk',
    'denmark': 'dk',
    'swedia': 'se',
    'switzerland': 'ch',
    'swiss': 'ch',
  };

  String? _detectCountryCode(String name) {
    final lower = name.toLowerCase();
    for (final entry in _countryCodeMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  IconData _getSportIcon() {
    final cat = (sportCategory ?? '').toLowerCase();
    if (cat.contains('basket')) return Icons.sports_basketball_rounded;
    if (cat.contains('voli') || cat.contains('volley')) return Icons.sports_volleyball_rounded;
    if (cat.contains('badminton') || cat.contains('tangkis')) return Icons.sports_tennis_rounded;
    if (cat.contains('tenis') || cat.contains('tennis')) return Icons.sports_tennis_rounded;
    return Icons.sports_soccer_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final validUrl = logoUrl != null &&
        logoUrl!.trim().isNotEmpty &&
        logoUrl!.startsWith('http') &&
        !logoUrl!.endsWith('/company/21-1.png'); // Lewati default placeholder jika ada

    if (validUrl) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: accentColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: logoUrl!,
            fit: BoxFit.contain,
            placeholder: (context, url) => _buildPlaceholder(),
            errorWidget: (context, url, error) => _buildFallbackContent(),
          ),
        ),
      );
    }

    // Jika tidak ada direct logoUrl valid, periksa deteksi negara atau inisial
    return _buildFallbackContainer();
  }

  Widget _buildPlaceholder() {
    return Center(
      child: SizedBox(
        width: size * 0.4,
        height: size * 0.4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: accentColor,
        ),
      ),
    );
  }

  Widget _buildFallbackContainer() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            accentColor.withValues(alpha: 0.3),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: _buildFallbackContent(),
      ),
    );
  }

  Widget _buildFallbackContent() {
    final countryCode = _detectCountryCode(teamName);
    if (countryCode != null) {
      return CachedNetworkImage(
        imageUrl: 'https://flagcdn.com/w80/$countryCode.png',
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _buildInitials(),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    final initial = teamName.trim().isNotEmpty
        ? teamName.trim().substring(0, 1).toUpperCase()
        : 'T';

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _getSportIcon(),
            size: size * 0.55,
            color: accentColor.withValues(alpha: 0.18),
          ),
          Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
