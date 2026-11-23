import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../../core/auth/backend_auth.dart';
import '../../../core/network/backend_config.dart';

class LiveReviewError implements Exception {
  const LiveReviewError(this.message);
  final String message;
  @override
  String toString() => message;
}

class LiveReview {
  const LiveReview(
      {required this.id,
      required this.authorId,
      required this.authorName,
      required this.stars,
      required this.comment,
      required this.updatedAt});
  final String id;
  final String authorId;
  final String authorName;
  final int stars;
  final String comment;
  final DateTime updatedAt;
  factory LiveReview.fromJson(Map<String, dynamic> data) => LiveReview(
      id: data['id'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      stars: (data['stars'] as num).toInt(),
      comment: data['comment'] as String,
      updatedAt: DateTime.parse(data['updatedAt'] as String));
}

class LiveReviewFeed {
  const LiveReviewFeed(
      {required this.items, required this.average, required this.count});
  final List<LiveReview> items;
  final double average;
  final int count;
}

class LiveBusinessReviewApi {
  LiveBusinessReviewApi({http.Client? client})
      : _client = client ?? http.Client();
  final http.Client _client;
  Uri _uri(String path) => BackendConfig.resolve('/api/v1$path');

  LiveReviewError _error(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is Map) {
        return LiveReviewError(decoded['error']['message']?.toString() ??
            'Request failed (${response.statusCode})');
      }
    } catch (_) {/* Avoid displaying arbitrary upstream bodies. */}
    return LiveReviewError('Request failed (${response.statusCode})');
  }

  Map<String, dynamic> _body(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw _error(response);
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {/* Return consistent client error. */}
    throw const LiveReviewError('Invalid review response from server.');
  }

  Future<http.Response> _send(String method, String path,
      {Map<String, dynamic>? data, bool auth = false}) async {
    Future<http.Response> request(String? token) async {
      final headers = <String, String>{'Accept': 'application/json'};
      if (data != null) headers['Content-Type'] = 'application/json';
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final uri = _uri(path);
      switch (method) {
        case 'GET':
          return _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
        case 'POST':
          return _client
              .post(uri,
                  headers: headers,
                  body: data == null ? null : jsonEncode(data))
              .timeout(const Duration(seconds: 15));
        case 'DELETE':
          return _client
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
      }
      throw const LiveReviewError('Unsupported HTTP request.');
    }

    try {
      if (!auth) return await request(null);
      var response =
          await request(await BackendAuth.instance.accessTokenForApi());
      if (response.statusCode == 401) {
        response = await request(
            await BackendAuth.instance.accessTokenForApi(forceRefresh: true));
      }
      return response;
    } on TimeoutException {
      throw const LiveReviewError('Review request timed out.');
    } on SocketException {
      throw const LiveReviewError('Cannot connect to Spring Boot.');
    } on http.ClientException {
      throw const LiveReviewError('Network error. Please retry.');
    }
  }

  Future<LiveReviewFeed> feed(String businessId) async {
    final id = Uri.encodeComponent(businessId);
    final json = _body(await _send('GET', '/businesses/$id/reviews'));
    final rows = (json['items'] as List)
        .map((e) => LiveReview.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final summary = Map<String, dynamic>.from(json['summary'] as Map);
    return LiveReviewFeed(
        items: rows,
        average: (summary['average'] as num).toDouble(),
        count: (summary['count'] as num).toInt());
  }

  Future<LiveReview?> mine(String businessId) async {
    final id = Uri.encodeComponent(businessId);
    final json =
        _body(await _send('GET', '/me/businesses/$id/review', auth: true));
    if (json['review'] == null) return null;
    return LiveReview.fromJson(
        Map<String, dynamic>.from(json['review'] as Map));
  }

  Future<void> save(String id, int stars, String comment) async {
    _body(await _send('POST', '/businesses/${Uri.encodeComponent(id)}/reviews',
        data: {'stars': stars, 'comment': comment}, auth: true));
  }

  Future<void> delete(String id) async {
    final response = await _send(
        'DELETE', '/me/businesses/${Uri.encodeComponent(id)}/review',
        auth: true);
    if (response.statusCode != 204) throw _error(response);
  }

  Future<void> report(String id, String reviewId, String reason) async {
    _body(await _send('POST',
        '/businesses/${Uri.encodeComponent(id)}/reviews/${Uri.encodeComponent(reviewId)}/reports',
        data: {'reason': reason}, auth: true));
  }
}
