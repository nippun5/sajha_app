import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../../../core/auth/backend_auth.dart';
import '../../../core/network/backend_config.dart';
import '../../../models/business_model.dart';
import '../data/business_submission.dart';

class LiveBusinessException implements Exception {
  const LiveBusinessException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LiveBusinessRequest {
  const LiveBusinessRequest({
    required this.id,
    required this.businessName,
    required this.category,
    required this.status,
    required this.visibility,
    required this.revision,
    required this.submittedAt,
    required this.raw,
  });
  final String id;
  final String businessName;
  final String category;
  final String status;
  final String visibility;
  final int revision;
  final DateTime submittedAt;
  final Map<String, dynamic> raw;
  String get location => raw['onlineOnly'] == true
      ? 'Online only'
      : raw['address']?.toString() ?? '';
  String? get declineReason => raw['declineReason'] as String?;
  factory LiveBusinessRequest.fromJson(Map<String, dynamic> map) =>
      LiveBusinessRequest(
        id: map['id'] as String,
        businessName: map['businessName'] as String,
        category: map['category'] as String,
        status: map['status'] as String,
        visibility: map['visibility'] as String? ?? 'active',
        revision: (map['revision'] as num).toInt(),
        submittedAt: DateTime.parse(map['submittedAt'] as String),
        raw: map,
      );
}

class LiveBusinessApi {
  LiveBusinessApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static bool get enabled => BackendConfig.configuredBase.isNotEmpty;
  Uri _uri(String path) => BackendConfig.resolve('/api/v1$path');

  Future<String> _token({bool refresh = false}) =>
      BackendAuth.instance.accessTokenForApi(forceRefresh: refresh);

  LiveBusinessException _error(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is Map) {
        final error = body['error'] as Map;
        return LiveBusinessException(error['message']?.toString() ??
            'Request failed (${response.statusCode})');
      }
    } catch (_) {/* Return a safe fallback rather than response contents. */}
    return LiveBusinessException('Request failed (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _json(http.Response response) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _error(response);
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const LiveBusinessException('Unexpected server response.');
    }
    return body;
  }

  Future<List<BusinessModel>> browse() async {
    try {
      final response = await _client
          .get(_uri('/businesses'))
          .timeout(const Duration(seconds: 15));
      final data = await _json(response);
      final rows = data['items'];
      if (rows is! List) throw const FormatException('Missing business list');
      return rows.map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        final path = m['imageUrl']?.toString() ?? '';
        final photo = path.startsWith('/')
            ? BackendConfig.resolve(path).toString()
            : path;
        return BusinessModel(
          id: m['id'] as String,
          name: m['name'] as String,
          imageUrl: photo,
          description: m['description'] as String? ?? '',
          address: m['address'] as String? ?? '',
          phone: m['phone'] as String? ?? '',
          website: m['website'] as String? ?? '',
          category: m['category'] as String,
          rating: (m['rating'] as num?)?.toDouble() ?? 0.0,
          reviewCount: (m['reviewCount'] as num?)?.toInt() ?? 0,
          openingHours: Map<String, String>.from(m['openingHours'] as Map),
          latitude: (m['latitude'] as num?)?.toDouble(),
          longitude: (m['longitude'] as num?)?.toDouble(),
          geoapifyPlaceId: m['geoapifyPlaceId'] as String?,
          city: m['city'] as String?,
          state: m['state'] as String?,
          countryCode: m['countryCode'] as String?,
          onlineOnly: m['onlineOnly'] == true,
        );
      }).toList();
    } on SocketException {
      throw const LiveBusinessException('Cannot connect to Spring Boot.');
    } on TimeoutException {
      throw const LiveBusinessException(
          'Business directory request timed out.');
    } on FormatException {
      throw const LiveBusinessException(
          'The server returned invalid business data.');
    }
  }

  Future<List<LiveBusinessRequest>> mine() async {
    Future<http.Response> request(String token) => _client.get(
          _uri('/me/business-requests'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 15));
    var response = await request(await _token());
    if (response.statusCode == 401)
      response = await request(await _token(refresh: true));
    final data = await _json(response);
    final rows = data['items'];
    if (rows is! List)
      throw const LiveBusinessException('Invalid request list.');
    return rows
        .map((e) =>
            LiveBusinessRequest.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Uint8List> ownerBanner(String id) async {
    Future<http.Response> request(String token) => _client.get(
          _uri('/me/business-requests/${Uri.encodeComponent(id)}/banner'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 15));
    var response = await request(await _token());
    if (response.statusCode == 401)
      response = await request(await _token(refresh: true));
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw _error(response);
    return response.bodyBytes;
  }

  Future<LiveBusinessRequest> submit(BusinessSubmission submission,
      {String? correctionId}) async {
    if (submission.bannerBytes.length > 4 * 1024 * 1024) {
      throw const LiveBusinessException(
          'Select a JPEG or PNG banner under 4 MB.');
    }
    Future<http.Response> request(String token) async {
      final path = correctionId == null
          ? '/business-requests'
          : '/me/business-requests/${Uri.encodeComponent(correctionId)}';
      final req = http.MultipartRequest(
          correctionId == null ? 'POST' : 'PUT', _uri(path));
      req.headers['Authorization'] = 'Bearer $token';
      req.fields['details'] = jsonEncode(submission.toApiPayload());
      req.files.add(http.MultipartFile.fromBytes(
        'banner',
        submission.bannerBytes,
        filename: 'banner.jpg',
      ));
      final streamed =
          await _client.send(req).timeout(const Duration(seconds: 30));
      return http.Response.fromStream(streamed);
    }

    var response = await request(await _token());
    if (response.statusCode == 401)
      response = await request(await _token(refresh: true));
    return LiveBusinessRequest.fromJson(await _json(response));
  }
}
