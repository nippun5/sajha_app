import 'package:flutter/foundation.dart';

/// Frontend-facing account information. Never store a password here.
class SajhaAccount {
  final String id;
  final String displayName;
  final String? email;
  final String? phone;

  const SajhaAccount({
    required this.id,
    required this.displayName,
    this.email,
    this.phone,
  });
}

enum AuthStatus { guest, phoneUnverified, phoneVerified }

/// This holds UI state only. It is NOT an authentication service.
/// Do not call setTrustedAccount until the server has validated a session.
class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  SajhaAccount? _account;
  AuthStatus _status = AuthStatus.guest;

  SajhaAccount? get account => _account;
  AuthStatus get status => _status;
  bool get isSignedIn => _status != AuthStatus.guest;
  bool get isPhoneVerified => _status == AuthStatus.phoneVerified;
  bool get canPost => isSignedIn && isPhoneVerified;
  bool get canReview => canPost;

  /// Future integration point: call only after your Spring Boot API has
  /// verified credentials/token AND returned the account's phone status.
  /// This method is intentionally NOT invoked by preview forms.
  void setTrustedAccount({
    required SajhaAccount account,
    required bool phoneVerified,
  }) {
    _account = account;
    _status =
        phoneVerified ? AuthStatus.phoneVerified : AuthStatus.phoneUnverified;
    notifyListeners();
  }

  /// Clearing UI state does not revoke server tokens. Do that on the server.
  void clearLocalSession() {
    _account = null;
    _status = AuthStatus.guest;
    notifyListeners();
  }
}
