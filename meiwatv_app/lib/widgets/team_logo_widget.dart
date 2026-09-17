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

  // Pemetaan bendera negara lengkap (Bahasa Indonesia, Inggris, & Vietnam)
  static const Map<String, String> _countryCodeMap = {
    // Asia Tenggara & Timur
    'indonesia': 'id',
    'vietnam': 'vn',
    'việt nam': 'vn',
    'viet nam': 'vn',
    'jepang': 'jp',
    'japan': 'jp',
    'nhật bản': 'jp',
    'nhat ban': 'jp',
    'korea': 'kr',
    'korea selatan': 'kr',
    'hàn quốc': 'kr',
    'han quoc': 'kr',
    'south korea': 'kr',
    'korea utara': 'kp',
    'triều tiên': 'kp',
    'north korea': 'kp',
    'china': 'cn',
    'tiongkok': 'cn',
    'trung quốc': 'cn',
    'thailand': 'th',
    'thái lan': 'th',
    'thai lan': 'th',
    'malaysia': 'my',
    'singapura': 'sg',
    'singapore': 'sg',
    'filipina': 'ph',
    'philippines': 'ph',
    'taiwan': 'tw',
    'đài loan': 'tw',
    'dai loan': 'tw',
    'hong kong': 'hk',
    'hồng kông': 'hk',
    'myanmar': 'mm',
    'kamboja': 'kh',
    'cambodia': 'kh',
    'laos': 'la',
    'mongolia': 'mn',
    'mông cổ': 'mn',
    'nepal': 'np',
    'bangladesh': 'bd',
    'india': 'in',
    'ấn độ': 'in',
    'pakistan': 'pk',
    'sri lanka': 'lk',
    'kyrgyzstan': 'kg',
    'uzbekistan': 'uz',
    'kazakhstan': 'kz',
    'tajikistan': 'tj',
    'timor leste': 'tl',
    'brunei': 'bn',

    // Eropa
    'inggris': 'gb-eng',
    'england': 'gb-eng',
    'scotland': 'gb-sct',
    'skotlandia': 'gb-sct',
    'wales': 'gb-wls',
    'britania': 'gb',
    'spanyol': 'es',
    'spain': 'es',
    'tây ban nha': 'es',
    'jerman': 'de',
    'germany': 'de',
    'đức': 'de',
    'prancis': 'fr',
    'france': 'fr',
    'pháp': 'fr',
    'italia': 'it',
    'italy': 'it',
    'belanda': 'nl',
    'netherlands': 'nl',
    'hà lan': 'nl',
    'portugal': 'pt',
    'bồ đào nha': 'pt',
    'rusia': 'ru',
    'russia': 'ru',
    'nga': 'ru',
    'polandia': 'pl',
    'poland': 'pl',
    'ba lan': 'pl',
    'denmark': 'dk',
    'đan mạch': 'dk',
    'swedia': 'se',
    'thụy điển': 'se',
    'norwegia': 'no',
    'na uy': 'no',
    'finlandia': 'fi',
    'phần lan': 'fi',
    'switzerland': 'ch',
    'swiss': 'ch',
    'thụy sĩ': 'ch',
    'belgia': 'be',
    'bỉ': 'be',
    'kroasia': 'hr',
    'croatia': 'hr',
    'serbia': 'rs',
    'turki': 'tr',
    'turkey': 'tr',
    'thổ nhĩ kỳ': 'tr',
    'ukraina': 'ua',
    'ukraine': 'ua',
    'austria': 'at',
    'áo': 'at',
    'hungaria': 'hu',
    'yunani': 'gr',
    'greece': 'gr',
    'hy lạp': 'gr',
    'republika ceko': 'cz',
    'czech': 'cz',

    // Amerika & Oseania
    'argentina': 'ar',
    'brasil': 'br',
    'brazil': 'br',
    'amerika serikat': 'us',
    'united states': 'us',
    'usa': 'us',
    'kanada': 'ca',
    'canada': 'ca',
    'meksiko': 'mx',
    'mexico': 'mx',
    'uruguay': 'uy',
    'chile': 'cl',
    'kolombia': 'co',
    'colombia': 'co',
    'australia': 'au',
    'úc': 'au',
    'new zealand': 'nz',
    'fiji': 'fj',
    'papua nugini': 'pg',
    'peru': 'pe',
    'venezuela': 've',
    'paraguay': 'py',
    'ekuator': 'ec',
    'ecuador': 'ec',

    // Afrika & Timur Tengah
    'nigeria': 'ng',
    'algeria': 'dz',
    'maroko': 'ma',
    'morocco': 'ma',
    'mesir': 'eg',
    'egypt': 'eg',
    'senegal': 'sn',
    'ghana': 'gh',
    'kamerun': 'cm',
    'cameroon': 'cm',
    'arab saudi': 'sa',
    'saudi arabia': 'sa',
    'qatar': 'qa',
    'iran': 'ir',
    'irak': 'iq',
    'iraq': 'iq',
    'jordan': 'jo',
    'yordania': 'jo',
    'uae': 'ae',
    'uni emirat arab': 'ae',
    'kuwait': 'kw',
    'oman': 'om',
    'bahrain': 'bh',
  };

  String? _detectCountryCode(String name) {
    var clean = name.toLowerCase().trim();
    // Hilangkan prefix umum timnas/wanita/usia
    clean = clean
        .replaceAll(RegExp(r'^(nữ|nam|u\d+|men|women|timnas|national team)\s+', caseSensitive: false), '')
        .trim();

    // Cocokkan persis (exact match) nama negara
    for (final entry in _countryCodeMap.entries) {
      if (clean == entry.key) {
        return entry.value;
      }
    }

    // Jika diawali/diakhiri nama negara yang jelas
    for (final entry in _countryCodeMap.entries) {
      if (entry.key.length >= 4 && (clean.startsWith('${entry.key} ') || clean.endsWith(' ${entry.key}'))) {
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
    if (cat.contains('lol') || cat.contains('dota') || cat.contains('csgo') || cat.contains('esport')) {
      return Icons.sports_esports_rounded;
    }
    return Icons.sports_soccer_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final countryCode = _detectCountryCode(teamName);
    final hasValidLogo = logoUrl != null &&
        logoUrl!.trim().isNotEmpty &&
        logoUrl!.startsWith('http') &&
        !logoUrl!.endsWith('/company/21-1.png') &&
        !logoUrl!.contains('default');

    // 1. Jika URL logo club/pemain tersedia, utamakan logo asli
    if (hasValidLogo) {
      return _buildLogoFromUrl(logoUrl!, countryCode);
    }

    // 2. Jika tidak ada URL logo dan nama tim adalah nama negara, tampilkan bendera negara
    if (countryCode != null) {
      return _buildCountryFlag(countryCode);
    }

    // 3. Fallback inisial tim dengan ikon olahraga
    return _buildFallbackContainer();
  }

  Widget _buildLogoFromUrl(String url, String? fallbackCountryCode) {
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
          imageUrl: url,
          fit: BoxFit.contain,
          httpHeaders: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
          placeholder: (context, u) => _buildPlaceholder(),
          errorWidget: (context, u, error) {
            if (fallbackCountryCode != null) {
              return _buildCountryFlag(fallbackCountryCode);
            }
            return _buildFallbackContainer();
          },
        ),
      ),
    );
  }

  Widget _buildCountryFlag(String countryCode) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: 'https://flagcdn.com/w160/$countryCode.png',
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildFallbackContainer(),
        ),
      ),
    );
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
            accentColor.withValues(alpha: 0.35),
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
        child: _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    var clean = teamName.trim();
    clean = clean.replaceAll(RegExp(r'^(nữ|nam|u\d+|fc|sc)\s+', caseSensitive: false), '').trim();
    final initial = clean.isNotEmpty ? clean.substring(0, 1).toUpperCase() : 'T';

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _getSportIcon(),
            size: size * 0.52,
            color: accentColor.withValues(alpha: 0.22),
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
