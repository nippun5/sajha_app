import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../network/backend_config.dart';
import 'auth_session.dart';

class BackendAuthException implements Exception {
  const BackendAuthException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract class RefreshTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureRefreshTokenStore implements RefreshTokenStore {
  SecureRefreshTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'sajha_refresh_token_v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// The ONLY bridge allowed to set a trusted UI session. Never use preview
/// data, a decoded JWT, or client-side OTP input as proof of phone verification.
class BackendAuth {
  BackendAuth._(this._client, this._store, this._baseOverride);

  static final BackendAuth instance = BackendAuth._(
    http.Client(),
    SecureRefreshTokenStore(),
    null,
  );

  /// Injectable constructor for MockClient tests. Never supply a fake client
  /// or token store in a release build.
  factory BackendAuth.testing({
    required http.Client client,
    required RefreshTokenStore tokenStore,
    required String baseUrl,
  }) =>
      BackendAuth._(client, tokenStore, baseUrl);

  final http.Client _client;
  final RefreshTokenStore _store;
  final String? _baseOverride;
  String? _accessToken;
  DateTime? _expiresAt;
  Future<void>? _refreshInFlight;

  Uri _endpoint(String path) {
    try {
      return BackendConfig.resolve('/api/v1$path', overrideBase: _baseOverride);
    } on StateError catch (error) {
      throw BackendAuthException(error.message.toString());
    }
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? jsonBody,
    String? bearer,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (jsonBody != null) headers['Content-Type'] = 'application/json';
    if (bearer != null) headers['Authorization'] = 'Bearer $bearer';
    final uri = _endpoint(path);
    try {
      final future = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(
            uri,
            headers: headers,
            body: jsonBody == null ? null : jsonEncode(jsonBody),
          ),
        _ => throw StateError('Unsupported method $method'),
      };
      return await future.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const BackendAuthException('Connection timed out. Try again.');
    } on SocketException {
      throw const BackendAuthException('Cannot reach the SaJHa server.');
    } on http.ClientException {
      throw const BackendAuthException('Network request failed. Try again.');
    } on HandshakeException {
      throw const BackendAuthException('Secure connection failed.');
    }
  }

  Map<String, dynamic> _body(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      if (value is Map<String, dynamic>) return value;
    } on FormatException {
      // The server could return an HTML error from a reverse proxy.
    }
    throw const BackendAuthException('Unexpected response from server.');
  }

  void _requireSuccess(http.Response response, {int? exactStatus}) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        (exactStatus == null || response.statusCode == exactStatus)) {
      return;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      throw const BackendAuthException('Unexpected success response.');
    }
    String? code;
    String? message;
    try {
      final error = jsonDecode(response.body);
      if (error is Map && error['error'] is Map) {
        code = error['error']['code']?.toString();
        message = error['error']['message']?.toString();
      }
    } on FormatException {
      // Keep a generic message if a reverse proxy returned non-JSON.
    }
    throw BackendAuthException(
      message?.isNotEmpty == true
          ? message!
          : 'Request failed (${response.statusCode}).',
      code: code,
      statusCode: response.statusCode,
    );
  }

  Future<void> _acceptTokens(Map<String, dynamic> body) async {
    final access = body['accessToken'];
    final refresh = body['refreshToken'];
    final expiresIn = body['expiresIn'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty ||
        expiresIn is! num ||
        expiresIn <= 0 ||
        body['tokenType'] != 'Bearer') {
      throw const BackendAuthException('Invalid authentication response.');
    }
    // Save the *new* rotated refresh token before trusting the response.
    await _store.write(refresh);
    _accessToken = access;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn.toInt()));
  }

  Future<Map<String, dynamic>> _currentAccount() async {
    await _ensureAccess();
    var response = await _request('GET', '/me', bearer: _accessToken);
    if (response.statusCode == 401) {
      await _rotateRefresh();
      response = await _request('GET', '/me', bearer: _accessToken);
    }
    if (response.statusCode == 401) {
      await _clearLocal();
    }
    _requireSuccess(response);
    return _body(response);
  }

  void _setSession(Map<String, dynamic> body) {
    final id = body['id'];
    final name = body['name'];
    final verified = body['phoneVerified'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.isEmpty ||
        verified is! bool) {
      throw const BackendAuthException('Account response is incomplete.');
    }
    AuthSession.instance.setTrustedAccount(
      account: SajhaAccount(
        id: id,
        displayName: name,
        email: body['email'] is String ? body['email'] as String : null,
        phone: body['phone'] is String ? body['phone'] as String : null,
      ),
      phoneVerified: verified,
    );
  }

  Future<void> _clearLocal() async {
    _accessToken = null;
    _expiresAt = null;
    try {
      await _store.clear();
    } finally {
      AuthSession.instance.clearLocalSession();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await _request('POST', '/auth/login', jsonBody: {
      'email': email.trim(),
      'password': password,
    });
    _requireSuccess(response);
    // Never retain the previous account's phoneVerified flag while
    // replacing credentials with a newly authenticated account.
    AuthSession.instance.clearLocalSession();
    await _acceptTokens(_body(response));
    _setSession(await _currentAccount());
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    if (!RegExp(r'^\+[1-9][0-9]{6,14}$').hasMatch(phone)) {
      throw const BackendAuthException('Use an international phone number.');
    }
    final response = await _request('POST', '/auth/register', jsonBody: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'phone': phone,
    });
    _requireSuccess(response, exactStatus: 201);
    AuthSession.instance.clearLocalSession();
    await _acceptTokens(_body(response));
    _setSession(await _currentAccount());
  }

  Future<void> _ensureAccess() async {
    if (_accessToken != null &&
        _expiresAt != null &&
        _expiresAt!.isAfter(DateTime.now().add(const Duration(seconds: 30)))) {
      return;
    }
    await _rotateRefresh();
  }

  Future<void> _rotateRefresh() {
    final inflight = _refreshInFlight;
    if (inflight != null) return inflight;
    final operation = _doRefresh();
    _refreshInFlight = operation;
    return operation.whenComplete(() => _refreshInFlight = null);
  }

  Future<void> _doRefresh() async {
    final refresh = await _store.read();
    if (refresh == null || refresh.isEmpty) {
      throw const BackendAuthException('Please sign in to continue.',
          statusCode: 401);
    }
    final response = await _request('POST', '/auth/refresh', jsonBody: {
      'refreshToken': refresh,
    });
    if (response.statusCode == 401) {
      await _clearLocal();
    }
    _requireSuccess(response);
    await _acceptTokens(_body(response));
  }

  /// Called once before runApp. A network outage doesn't erase the saved
  /// refresh token; it DOES leave AuthSession as guest (fail closed).
  Future<void> restoreSession() async {
    AuthSession.instance.clearLocalSession();
    try {
      final refresh = await _store.read();
      if (refresh == null || refresh.isEmpty) return;
      await _rotateRefresh();
      _setSession(await _currentAccount());
    } on BackendAuthException {
      // Guest until the next valid sign-in / restore attempt.
    } catch (_) {
      // Storage/configuration errors must not create a trusted session.
    }
  }

  Future<String> startPhoneVerification(String phone) async {
    await _ensureAccess();
    final response = await _request(
      'POST',
      '/me/phone/challenges',
      bearer: _accessToken,
      jsonBody: {'phone': phone},
    );
    _requireSuccess(response, exactStatus: 201);
    final id = _body(response)['challengeId'];
    if (id is! String || id.isEmpty) {
      throw const BackendAuthException('Verification challenge missing.');
    }
    return id;
  }

  Future<bool> verifyPhone({
    required String challengeId,
    required String code,
  }) async {
    await _ensureAccess();
    final response = await _request(
      'POST',
      '/me/phone/verify',
      bearer: _accessToken,
      jsonBody: {'challengeId': challengeId, 'code': code},
    );
    _requireSuccess(response);
    final verifiedResponse = _body(response);
    if (verifiedResponse['phoneVerified'] is! bool) {
      throw const BackendAuthException('Verification response is invalid.');
    }
    // Never elevate from just client code or the start-OTP response.
    _setSession(await _currentAccount());
    return AuthSession.instance.isPhoneVerified;
  }

  /// Local tokens are cleared even if server revocation cannot be reached.
  /// In an offline logout, server refresh revocation remains unconfirmed.
  Future<void> signOut() async {
    try {
      await _ensureAccess();
      // Refresh rotation may have changed the stored token. Read it AFTER
      // _ensureAccess so the server revokes the current session token.
      final refresh = await _store.read();
      if (refresh != null && refresh.isNotEmpty) {
        final response = await _request(
          'POST',
          '/auth/logout',
          bearer: _accessToken,
          jsonBody: {'refreshToken': refresh},
        );
        _requireSuccess(response, exactStatus: 204);
      }
    } catch (_) {
      // Always sign out locally even when the network is unavailable.
    } finally {
      await _clearLocal();
    }
  }
}
