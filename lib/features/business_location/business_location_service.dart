import 'dart:convert';
import 'package:http/http.dart' as http;

/// One confirmed physical location, as returned by an autocomplete result or
/// by a user-adjusted map pin. Coordinates always travel with the address.
class BusinessLocation {
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? city;
  final String? state;
  final String? countryCode;

  const BusinessLocation({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.city,
    this.state,
    this.countryCode,
  });

  static BusinessLocation? fromGeoapify(Map<String, dynamic> json) {
    final lat = json['lat'];
    final lon = json['lon'];
    if (lat is! num || lon is! num ||
        lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      return null;
    }
    final address = (json['formatted'] as String? ?? '').trim();
    if (address.isEmpty) return null;
    return BusinessLocation(
      formattedAddress: address,
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      placeId: json['place_id'] as String?,
      city: json['city'] as String? ?? json['town'] as String?,
      state: json['state'] as String?,
      countryCode: json['country_code'] as String?,
    );
  }

  BusinessLocation copyWith({String? formattedAddress}) => BusinessLocation(
        formattedAddress: formattedAddress ?? this.formattedAddress,
        latitude: latitude,
        longitude: longitude,
        placeId: placeId,
        city: city,
        state: state,
        countryCode: countryCode,
      );
}

abstract class BusinessLocationService {
  bool get isConfigured;
  Future<List<BusinessLocation>> autocomplete(String text);
  Future<BusinessLocation?> reverse(double latitude, double longitude);
}

/// Temporary frontend integration. API keys embedded in a distributed app can
/// be extracted; proxy through Spring Boot before public production launch.
class GeoapifyBusinessLocationService implements BusinessLocationService {
  const GeoapifyBusinessLocationService({this.apiKey = const String.fromEnvironment('GEOAPIFY_API_KEY')});

  final String apiKey;

  @override
  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<Map<String, dynamic>> _request(Uri uri) async {
    if (!isConfigured) throw StateError('Geoapify API key not configured.');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode == 429) {
      throw StateError('Address search limit reached. Try again later.');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('Geoapify key is invalid or this API is restricted.');
    }
    if (response.statusCode != 200) {
      throw StateError('Address service unavailable (${response.statusCode}).');
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid address service response.');
    }
    return json;
  }

  @override
  Future<List<BusinessLocation>> autocomplete(String text) async {
    if (text.trim().length < 3) return const [];
    final uri = Uri.https('api.geoapify.com', '/v1/geocode/autocomplete', {
      'text': text.trim(),
      'format': 'json',
      'limit': '5',
      'apiKey': apiKey,
    });
    final data = await _request(uri);
    final results = data['results'];
    if (results is! List) return const [];
    return results.whereType<Map<String, dynamic>>()
        .map(BusinessLocation.fromGeoapify)
        .whereType<BusinessLocation>()
        .toList(growable: false);
  }

  @override
  Future<BusinessLocation?> reverse(double latitude, double longitude) async {
    final uri = Uri.https('api.geoapify.com', '/v1/geocode/reverse', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'json',
      'limit': '1',
      'apiKey': apiKey,
    });
    final data = await _request(uri);
    final results = data['results'];
    if (results is! List || results.isEmpty || results.first is! Map<String, dynamic>) {
      return null;
    }
    // Keep the chosen pin, not the nearest road/building point.
    final nearest = BusinessLocation.fromGeoapify(results.first as Map<String, dynamic>);
    if (nearest == null) return null;
    return BusinessLocation(
      formattedAddress: nearest.formattedAddress,
      latitude: latitude,
      longitude: longitude,
      city: nearest.city,
      state: nearest.state,
      countryCode: nearest.countryCode,
    );
  }
}
