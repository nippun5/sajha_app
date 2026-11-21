import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sajha_app/features/marketplace/live/live_marketplace_api.dart';

Map<String, dynamic> listing({String phone = '+13145550123'}) => {
      'id': '11111111-1111-1111-1111-111111111111',
      'kind': 'product',
      'title': 'Lamp',
      'description': 'A working desk lamp',
      'contactPhone': phone,
      'location': 'St Louis',
      'ownerDisplayName': 'Test Owner',
      'details': {'price': 18, 'category': 'Home', 'condition': 'good'},
      'createdAt': '2026-11-21T14:00:00Z',
      'status': 'active',
      'version': 1,
      'mediaUrls': <String>[],
    };

void main() {
  final base = Uri.parse('http://localhost:8080');
  Uri resolve(String path) => Uri.parse('$base/api/v1$path');

  test('Guest browse sends no token, adapts required contact', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/marketplace/listings');
      expect(request.headers.containsKey('Authorization'), isFalse);
      return http.Response(
          jsonEncode({
            'items': [listing()],
            'page': 0,
            'size': 20,
            'totalItems': 1,
            'totalPages': 1,
          }),
          200);
    });
    final api = LiveMarketplaceApi(client: client, resolve: resolve);
    final page = await api.browse(kind: 'product');
    expect(page.items.single.toMarketItem().contactPhone, '+13145550123');
    expect(page.items.single.priceLabel, r'$18');
    expect(page.totalPages, 1);
  });

  test('Create sends required phone with real access token', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer TEST_ACCESS');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['contactPhone'], '+13145550123');
      expect(body['kind'], 'product');
      expect(request.headers['Idempotency-Key'], 'request-12345678');
      return http.Response(jsonEncode(listing()), 201);
    });
    final api = LiveMarketplaceApi(
        client: client,
        resolve: resolve,
        tokenProvider: (_) async => 'TEST_ACCESS');
    final record = await api.create({
      'kind': 'product',
      'title': 'Lamp',
      'description': 'Working lamp',
      'contactPhone': '+13145550123',
      'location': 'St Louis',
      'details': {'price': 18, 'category': 'Home', 'condition': 'good'},
      'mediaIds': <String>[],
    }, 'request-12345678');
    expect(record.title, 'Lamp');
  });

  test('Unverified server response is not treated as success', () async {
    final client = MockClient((request) async => http.Response(
        jsonEncode({
          'error': {
            'code': 'PHONE_NOT_VERIFIED',
            'message': 'Verify your account phone before posting'
          },
        }),
        403));
    final api = LiveMarketplaceApi(
        client: client,
        resolve: resolve,
        tokenProvider: (_) async => 'TEST_ACCESS');
    expect(() => api.create({'kind': 'product'}, 'request-12345678'),
        throwsA(isA<MarketplaceApiException>()));
  });

  test('Bookmark uses authenticated PUT, never mock store', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.headers['Authorization'], 'Bearer TEST_ACCESS');
      expect(request.url.path, contains('/me/saved-listings/'));
      return http.Response('', 204);
    });
    final api = LiveMarketplaceApi(
        client: client,
        resolve: resolve,
        tokenProvider: (_) async => 'TEST_ACCESS');
    await api.save('11111111-1111-1111-1111-111111111111');
  });
}
