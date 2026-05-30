abstract final class AppConstants {
  // ── App identity ────────────────────────────────────────────
  static const String appName    = 'SaJHa';
  static const String appTagline = 'Your local marketplace';
  static const String logoPath   = 'assets/images/logo.png';

  // ── Named routes ────────────────────────────────────────────
  static const String splashRoute          = '/splash';
  static const String loginRoute           = '/login';
  static const String completeProfileRoute = '/complete-profile';
  static const String shellRoute           = '/';
  static const String postListingRoute     = '/post-listing';

  // ── Splash ──────────────────────────────────────────────────
  static const Duration splashDuration = Duration(milliseconds: 3200);

  // ── Default region (Australia) ──────────────────────────────
  static const String defaultCountryCode = 'AU';
  static const String defaultDialCode    = '+61';
  static const String defaultCountryFlag = '🇦🇺';

  // ── Country picker list ─────────────────────────────────────
  static const List<Map<String, String>> countries = [
    {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia'},
    {'code': '+64', 'flag': '🇳🇿', 'name': 'New Zealand'},
    {'code': '+1',  'flag': '🇺🇸', 'name': 'United States'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'United Kingdom'},
    {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
    {'code': '+977','flag': '🇳🇵', 'name': 'Nepal'},
    {'code': '+880','flag': '🇧🇩', 'name': 'Bangladesh'},
    {'code': '+92', 'flag': '🇵🇰', 'name': 'Pakistan'},
    {'code': '+94', 'flag': '🇱🇰', 'name': 'Sri Lanka'},
    {'code': '+65', 'flag': '🇸🇬', 'name': 'Singapore'},
    {'code': '+60', 'flag': '🇲🇾', 'name': 'Malaysia'},
    {'code': '+63', 'flag': '🇵🇭', 'name': 'Philippines'},
    {'code': '+86', 'flag': '🇨🇳', 'name': 'China'},
    {'code': '+82', 'flag': '🇰🇷', 'name': 'South Korea'},
  ];
}