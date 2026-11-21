import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sajha_app/core/auth/auth_session.dart';
import 'package:sajha_app/core/auth/backend_auth.dart';

class MemoryRefreshStore implements RefreshTokenStore {
  String? value;
  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async {
    value = token;
  }
}

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

Map<String, Object> tokens(String access, String refresh) => {
      'accessToken': access,
      'refreshToken': refresh,
      'tokenType': 'Bearer',
      'expiresIn': 900,
    };

Map<String, Object> account({bool verified = false}) => {
      'id': 'server-user-1',
      'name': 'SaJHa Tester',
      'email': 'test@example.com',
      'phone': '+15551234567',
      'phoneVerified': verified,
      'roles': ['USER'],
      'verifiedContactPhones': verified ? ['+15551234567'] : [],
    };

void main() {
  setUp(() => AuthSession.instance.clearLocalSession());
  tearDown(() => AuthSession.instance.clearLocalSession());

  test('email login creates real session but unverified users cannot post',
      () async {
    final store = MemoryRefreshStore();
    final auth = BackendAuth.testing(
      baseUrl: 'https://api.test',
      tokenStore: store,
      client: MockClient((req) async {
        if (req.url.path == '/api/v1/auth/login') {
          expect(req.method, 'POST');
          expect(jsonDecode(req.body)['email'], 'test@example.com');
          return jsonResponse(tokens('accessA', 'refreshA'));
        }
        if (req.url.path == '/api/v1/me') {
          final authHeader = req.headers.entries
              .where((entry) => entry.key.toLowerCase() == 'authorization')
              .single
              .value;
          expect(authHeader, 'Bearer accessA');
          return jsonResponse(account());
        }
        return http.Response('not found', 404);
      }),
    );

    await auth.signIn(email: 'test@example.com', password: 'A-long-password');
    expect(store.value, 'refreshA');
    expect(AuthSession.instance.isSignedIn, true);
    expect(AuthSession.instance.canPost, false);
  });

  test('registration sends required phone and follows up with server account',
      () async {
    final auth = BackendAuth.testing(
      baseUrl: 'https://api.test',
      tokenStore: MemoryRefreshStore(),
      client: MockClient((req) async {
        if (req.url.path == '/api/v1/auth/register') {
          expect(req.method, 'POST');
          expect(jsonDecode(req.body)['phone'], '+15551234567');
          return jsonResponse(tokens('accessA', 'refreshA'), 201);
        }
        if (req.url.path == '/api/v1/me') return jsonResponse(account());
        return http.Response('not found', 404);
      }),
    );
    await auth.register(
      name: 'SaJHa Tester',
      email: 'test@example.com',
      password: 'A-long-password',
      phone: '+15551234567',
    );
    expect(AuthSession.instance.isPhoneVerified, false);
    expect(AuthSession.instance.canPost, false);
  });

  test('verification is granted only after server /me reports phoneVerified',
      () async {
    var serverVerified = false;
    final auth = BackendAuth.testing(
      baseUrl: 'https://api.test',
      tokenStore: MemoryRefreshStore(),
      client: MockClient((req) async {
        switch (req.url.path) {
          case '/api/v1/auth/login':
            return jsonResponse(tokens('accessA', 'refreshA'));
          case '/api/v1/me':
            return jsonResponse(account(verified: serverVerified));
          case '/api/v1/me/phone/challenges':
            expect(jsonDecode(req.body)['phone'], '+15551234567');
            return jsonResponse({'challengeId': 'challenge-id'}, 201);
          case '/api/v1/me/phone/verify':
            serverVerified = true;
            return jsonResponse(
                {'phoneVerified': true, 'phone': '+15551234567'});
        }
        return http.Response('not found', 404);
      }),
    );
    await auth.signIn(email: 'test@example.com', password: 'A-long-password');
    final challenge = await auth.startPhoneVerification('+15551234567');
    expect(AuthSession.instance.canPost, false);
    expect(
        await auth.verifyPhone(challengeId: challenge, code: '123456'), true);
    expect(AuthSession.instance.canPost, true);
  });

  test('offline/disabled SMS returns error and does not verify account',
      () async {
    final auth = BackendAuth.testing(
      baseUrl: 'https://api.test',
      tokenStore: MemoryRefreshStore(),
      client: MockClient((req) async {
        switch (req.url.path) {
          case '/api/v1/auth/login':
            return jsonResponse(tokens('accessA', 'refreshA'));
          case '/api/v1/me':
            return jsonResponse(account());
          case '/api/v1/me/phone/challenges':
            return jsonResponse({
              'error': {
                'code': 'SMS_UNAVAILABLE',
                'message': 'SMS provider unavailable.'
              }
            }, 503);
        }
        return http.Response('not found', 404);
      }),
    );
    await auth.signIn(email: 'test@example.com', password: 'A-long-password');
    await expectLater(
      auth.startPhoneVerification('+15551234567'),
      throwsA(isA<BackendAuthException>()
          .having((e) => e.code, 'code', 'SMS_UNAVAILABLE')),
    );
    expect(AuthSession.instance.canPost, false);
  });

  test('restart rotates refresh token and logout sends current token',
      () async {
    final store = MemoryRefreshStore()..value = 'oldRefresh';
    var logoutUsed = '';
    final auth = BackendAuth.testing(
      baseUrl: 'https://api.test',
      tokenStore: store,
      client: MockClient((req) async {
        if (req.url.path == '/api/v1/auth/refresh') {
          expect(jsonDecode(req.body)['refreshToken'], 'oldRefresh');
          return jsonResponse(tokens('newAccess', 'newRefresh'));
        }
        if (req.url.path == '/api/v1/me')
          return jsonResponse(account(verified: true));
        if (req.url.path == '/api/v1/auth/logout') {
          logoutUsed = jsonDecode(req.body)['refreshToken'] as String;
          return http.Response('', 204);
        }
        return http.Response('not found', 404);
      }),
    );
    await auth.restoreSession();
    expect(store.value, 'newRefresh');
    expect(AuthSession.instance.canPost, true);
    await auth.signOut();
    expect(logoutUsed, 'newRefresh');
    expect(store.value, isNull);
    expect(AuthSession.instance.isSignedIn, false);
  });

  test('invalid stored refresh token fails closed', () async {
    final store = MemoryRefreshStore()..value = 'invalid';
    final auth = BackendAuth.testing(
      baseUrl: 'https://api.test',
      tokenStore: store,
      client: MockClient((req) async => jsonResponse({
            'error': {
              'code': 'INVALID_REFRESH',
              'message': 'Refresh token invalid'
            }
          }, 401)),
    );
    await auth.restoreSession();
    expect(store.value, isNull);
    expect(AuthSession.instance.isSignedIn, false);
    expect(AuthSession.instance.canPost, false);
  });
}
