import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../network/backend_config.dart';

class PasswordRecoveryException implements Exception {
  const PasswordRecoveryException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Public password recovery endpoints; NO access token or refresh token needed.
/// A reset does NOT create an authenticated session.
class PasswordRecoveryApi {
  PasswordRecoveryApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  final http.Client _client;
  final String? _baseUrl;

  Uri _url(String endpoint) => BackendConfig.resolve(
        '/api/v1/auth/password/$endpoint',
        overrideBase: _baseUrl,
      );

  Future<http.Response> _post(String endpoint, Map<String, String> body) async {
    try {
      return await _client
          .post(
            _url(endpoint),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const PasswordRecoveryException('Request timed out. Try again.');
    } on http.ClientException {
      throw const PasswordRecoveryException('Cannot reach SaJHa server.');
    } on StateError catch (e) {
      throw PasswordRecoveryException(e.message.toString());
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map && json['error'] is Map) {
        final msg = (json['error'] as Map)['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {
      // No detailed error text was provided by the server.
    }
    return 'Request failed (${response.statusCode}).';
  }

  Future<void> requestReset(String email) async {
    final response = await _post('forgot', {'email': email.trim()});
    if (response.statusCode != 202) {
      throw PasswordRecoveryException(_errorMessage(response));
    }
  }

  Future<void> redeem(
      {required String token, required String newPassword}) async {
    final response = await _post('reset', {
      'token': token.trim(),
      'newPassword': newPassword,
    });
    if (response.statusCode != 204) {
      throw PasswordRecoveryException(_errorMessage(response));
    }
  }
}
