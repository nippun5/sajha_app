import 'package:flutter/foundation.dart';

/// Pass a base URL at launch, not a production secret:
/// --dart-define=SAJHA_API_BASE_URL=https://api.example.com
abstract final class BackendConfig {
  static const String configuredBase = String.fromEnvironment(
    'SAJHA_API_BASE_URL',
    defaultValue: '',
  );

  static Uri resolve(String endpoint, {String? overrideBase}) {
    final raw = (overrideBase ?? configuredBase).trim();
    if (raw.isEmpty) {
      throw StateError('SAJHA_API_BASE_URL is not configured.');
    }
    final base = Uri.tryParse(raw);
    if (base == null ||
        !base.hasScheme ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        !['https', 'http'].contains(base.scheme)) {
      throw StateError('Invalid SaJHa API base URL.');
    }
    if (kReleaseMode && base.scheme != 'https') {
      throw StateError('Production authentication requires HTTPS.');
    }
    if (!endpoint.startsWith('/api/v1/')) {
      throw ArgumentError.value(endpoint, 'endpoint', 'Expected /api/v1 path');
    }
    final prefix = base.toString().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$prefix$endpoint');
  }
}
