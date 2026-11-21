import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/auth/backend_auth.dart';
import '../../../core/network/backend_config.dart';
import '../data/marketplace_mock_store.dart';

class MarketplaceApiException implements Exception {
  const MarketplaceApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;
  @override
  String toString() => message;
}

class LiveListing {
  const LiveListing({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.contactPhone,
    required this.location,
    required this.ownerName,
    required this.details,
    required this.createdAt,
    required this.status,
    required this.version,
    required this.mediaUrls,
  });
  final String id;
  final String kind;
  final String title;
  final String description;
  final String contactPhone;
  final String location;
  final String ownerName;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final String status;
  final int version;
  final List<String> mediaUrls;

  factory LiveListing.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    final rawMedia = json['mediaUrls'];
    if (rawDetails is! Map ||
        json['contactPhone'] is! String ||
        (json['contactPhone'] as String).isEmpty) {
      throw const FormatException(
          'Invalid backend listing: contact is required');
    }
    return LiveListing(
      id: json['id'] as String,
      kind: json['kind'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      contactPhone: json['contactPhone'] as String,
      location: json['location'] as String,
      ownerName: json['ownerDisplayName']?.toString() ?? '',
      details: Map<String, dynamic>.from(rawDetails),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String,
      version: (json['version'] as num).toInt(),
      mediaUrls: rawMedia is List ? rawMedia.cast<String>() : const [],
    );
  }

  MarketKind get marketKind => switch (kind) {
        'product' => MarketKind.buySell,
        'room' => MarketKind.room,
        'job' => MarketKind.job,
        _ => throw FormatException('Unknown marketplace kind: $kind'),
      };

  String get priceLabel {
    switch (kind) {
      case 'product':
        final price = (details['price'] as num).toDouble();
        return '\$${price.toStringAsFixed(0)}';
      case 'room':
        final rent = (details['weeklyRent'] as num).toDouble();
        return '\$${rent.toStringAsFixed(0)}/week';
      case 'job':
        final low = details['salaryMin'];
        final cycle = details['salaryCycle']?.toString() ?? '';
        if (low is num) return '\$${low.toStringAsFixed(0)} $cycle';
        return 'Salary negotiable';
      default:
        return '';
    }
  }

  String get category => switch (kind) {
        'product' => details['category']?.toString() ?? 'Buy & Sell',
        'room' => 'Room',
        'job' => details['jobType']?.toString() ?? 'Job',
        _ => 'Listing',
      };

  MarketItem toMarketItem() => MarketItem(
        id: id,
        kind: marketKind,
        title: title,
        priceLabel: priceLabel,
        category: category,
        location: location,
        description: description,
        createdAt: createdAt,
        imageUrl: mediaUrls.isEmpty ? null : mediaUrls.first,
        contactName: ownerName,
        contactPhone: contactPhone,
        details: details.map((key, value) => MapEntry(key, value.toString())),
        status: status == 'active' ? MarketStatus.active : MarketStatus.closed,
      );
}

class LiveListingPage {
  const LiveListingPage(this.items, this.page, this.totalPages);
  final List<LiveListing> items;
  final int page;
  final int totalPages;
}

typedef AccessTokenProvider = Future<String> Function(bool forceRefresh);
typedef MarketplaceUriResolver = Uri Function(String path);

/// Live API; never uses ProfileDemoStore or a locally forged identity.
/// Inject a MockClient/token provider only in tests.
class LiveMarketplaceApi {
  LiveMarketplaceApi({
    http.Client? client,
    AccessTokenProvider? tokenProvider,
    MarketplaceUriResolver? resolve,
  })  : _client = client ?? http.Client(),
        _token = tokenProvider ??
            ((refresh) => BackendAuth.instance.accessTokenForApi(
                  forceRefresh: refresh,
                )),
        _resolve = resolve ?? ((path) => BackendConfig.resolve('/api/v1$path'));

  final http.Client _client;
  final AccessTokenProvider _token;
  final MarketplaceUriResolver _resolve;

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? jsonBody,
    bool authenticated = false,
    String? idempotencyKey,
  }) async {
    Future<http.Response> execute(String? token) async {
      final headers = <String, String>{'Accept': 'application/json'};
      if (jsonBody != null) headers['Content-Type'] = 'application/json';
      if (token != null) headers['Authorization'] = 'Bearer $token';
      if (idempotencyKey != null) headers['Idempotency-Key'] = idempotencyKey;
      final uri = _resolve(path);
      final payload = jsonBody == null ? null : jsonEncode(jsonBody);
      final future = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: payload),
        'PUT' => _client.put(uri, headers: headers),
        'PATCH' => _client.patch(uri, headers: headers, body: payload),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => throw ArgumentError('Unsupported method: $method'),
      };
      return future.timeout(const Duration(seconds: 15));
    }

    try {
      final bearer = authenticated ? await _token(false) : null;
      var response = await execute(bearer);
      // Only a genuine backend refresh can recover an expired token.
      if (authenticated && response.statusCode == 401) {
        response = await execute(await _token(true));
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      String? code;
      String? message;
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map && parsed['error'] is Map) {
          code = parsed['error']['code']?.toString();
          message = parsed['error']['message']?.toString();
        }
      } on FormatException {
        // Some reverse proxies return HTML; never expose it as user input.
      }
      throw MarketplaceApiException(
        message ?? 'Marketplace request failed (${response.statusCode}).',
        statusCode: response.statusCode,
        code: code,
      );
    } on TimeoutException {
      throw const MarketplaceApiException('Marketplace connection timed out.');
    } on SocketException {
      throw const MarketplaceApiException('Unable to reach the SaJHa backend.');
    } on http.ClientException {
      throw const MarketplaceApiException(
          'Marketplace network request failed.');
    } on BackendAuthException catch (e) {
      throw MarketplaceApiException(e.message,
          statusCode: e.statusCode, code: e.code);
    }
  }

  Map<String, dynamic> _asObject(http.Response response) {
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map<String, dynamic>) return parsed;
    } on FormatException {
      // Do not treat a partial or invalid response as a successful post.
    }
    throw const MarketplaceApiException('Invalid marketplace response.');
  }

  LiveListingPage _asPage(http.Response response) {
    final data = _asObject(response);
    final items = data['items'];
    if (items is! List)
      throw const MarketplaceApiException('Listing page is incomplete.');
    return LiveListingPage(
      items
          .map((e) => LiveListing.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      (data['page'] as num).toInt(),
      (data['totalPages'] as num).toInt(),
    );
  }

  Future<LiveListingPage> browse(
      {required String kind, String q = '', int page = 0}) async {
    final query = <String, String>{'kind': kind, 'page': '$page', 'size': '20'};
    if (q.trim().isNotEmpty) query['q'] = q.trim();
    final path = '/marketplace/listings?${Uri(queryParameters: query).query}';
    return _asPage(await _send('GET', path));
  }

  Future<LiveListing> get(String id) async => LiveListing.fromJson(
        _asObject(await _send(
            'GET', '/marketplace/listings/${Uri.encodeComponent(id)}')),
      );
  Future<LiveListingPage> mine({int page = 0}) async =>
      _asPage(await _send('GET', '/me/listings?page=$page&size=20',
          authenticated: true));
  Future<LiveListingPage> saved({int page = 0}) async =>
      _asPage(await _send('GET', '/me/saved-listings?page=$page&size=20',
          authenticated: true));
  Future<LiveListing> create(
          Map<String, dynamic> submission, String requestKey) async =>
      LiveListing.fromJson(_asObject(await _send(
          'POST', '/marketplace/listings',
          authenticated: true,
          jsonBody: submission,
          idempotencyKey: requestKey)));
  Future<LiveListing> edit(String id, Map<String, dynamic> changes) async =>
      LiveListing.fromJson(_asObject(await _send(
          'PATCH', '/marketplace/listings/${Uri.encodeComponent(id)}',
          authenticated: true, jsonBody: changes)));
  Future<void> delete(String id) async {
    await _send('DELETE', '/marketplace/listings/${Uri.encodeComponent(id)}',
        authenticated: true);
  }

  Future<void> save(String id) async {
    await _send('PUT', '/me/saved-listings/${Uri.encodeComponent(id)}',
        authenticated: true);
  }

  Future<void> unsave(String id) async {
    await _send('DELETE', '/me/saved-listings/${Uri.encodeComponent(id)}',
        authenticated: true);
  }
}
