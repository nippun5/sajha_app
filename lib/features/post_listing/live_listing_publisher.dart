import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/auth/auth_session.dart';
import '../../core/auth/backend_auth.dart';
import '../../core/network/backend_config.dart';
import '../business_location/business_location_service.dart';
import '../marketplace/live/live_marketplace_api.dart';

/// Uploads selected images BEFORE a live create. Does not discard a selected
/// image silently. Server validates the account/contact number and image bytes.
class LiveListingPublisher {
  LiveListingPublisher({http.Client? client, LiveMarketplaceApi? api})
      : _client = client ?? http.Client(),
        _api = api ?? LiveMarketplaceApi();
  final http.Client _client;
  final LiveMarketplaceApi _api;
  final Map<String, String> _staged = {};
  String? _requestKey;

  static bool get isLive => BackendConfig.configuredBase.isNotEmpty;
  static String get verifiedPhone => AuthSession.instance.account?.phone ?? '';

  /// Marketplace posts should show the general area, not a seller's street address.
  /// Business directory entries intentionally use their separate exact-address model.
  static String publicArea(BusinessLocation location) {
    final city = (location.city ?? '').trim();
    final state = (location.state ?? '').trim();
    if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
    if (city.isNotEmpty) return city;
    if (state.isNotEmpty) return state;
    return location.formattedAddress;
  }

  /// Coordinates are intentionally coarse (~1 km) for public marketplace posts.
  static Map<String, dynamic> coords(BusinessLocation? location) =>
      location == null
          ? const {}
          : {
              'latitude': double.parse(location.latitude.toStringAsFixed(2)),
              'longitude': double.parse(location.longitude.toStringAsFixed(2)),
            };

  Future<String> _uploadOne(File file) async {
    if (!await file.exists()) throw StateError('Selected photo is missing.');
    if (await file.length() > 4 * 1024 * 1024) {
      throw StateError('Each photo must be under 4 MB (JPEG/PNG).');
    }
    // A retried submission reuses previously staged media instead of
    // leaking extra unreferenced uploads.
    final key =
        '${file.path}:${await file.length()}:${(await file.lastModified()).millisecondsSinceEpoch}';
    if (_staged.containsKey(key)) return _staged[key]!;

    Future<http.Response> send({required bool refresh}) async {
      final token =
          await BackendAuth.instance.accessTokenForApi(forceRefresh: refresh);
      final req =
          http.MultipartRequest('POST', BackendConfig.resolve('/api/v1/media'));
      req.headers['Authorization'] = 'Bearer $token';
      req.files.add(await http.MultipartFile.fromPath('file', file.path));
      return http.Response.fromStream(
          await _client.send(req).timeout(const Duration(seconds: 30)));
    }

    var response = await send(refresh: false);
    if (response.statusCode == 401) response = await send(refresh: true);
    if (response.statusCode != 201) {
      String message = 'Photo upload failed (${response.statusCode})';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = (body['error'] as Map?)?['message']?.toString() ?? message;
      } catch (_) {}
      throw StateError(message);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final id = json['id'];
    if (id is! String || id.isEmpty)
      throw StateError('Missing photo upload ID');
    _staged[key] = id;
    return id;
  }

  Future<LiveListing> publish({
    required String kind,
    required String title,
    required String description,
    required String location,
    required Map<String, dynamic> details,
    List<File> images = const [],
    String? contactPhone,
  }) async {
    if (!AuthSession.instance.canPost) {
      throw StateError('Sign in and verify your phone before publishing.');
    }
    final phone = verifiedPhone;
    if (!RegExp(r'^\+[1-9][0-9]{6,14}$').hasMatch(phone)) {
      throw StateError(
          'A verified international seller phone number is required.');
    }
    if (contactPhone != null && contactPhone.trim() != phone) {
      throw StateError(
          'Listing contact number must match your verified phone.');
    }
    if (images.length > 5) throw StateError('Use at most five photos.');
    final ids = <String>[];
    for (final image in images) {
      ids.add(await _uploadOne(image));
    }
    _requestKey ??= 'flutter-${DateTime.now().microsecondsSinceEpoch}';
    return _api.create({
      'kind': kind,
      'title': title.trim(),
      'description': description.trim(),
      'contactPhone': phone,
      'location': location.trim(),
      'details': details,
      'mediaIds': ids,
    }, _requestKey!);
  }
}
