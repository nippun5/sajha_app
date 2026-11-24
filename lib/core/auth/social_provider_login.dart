import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'backend_auth.dart';

class SocialCredential {
  const SocialCredential(this.provider, this.credential, {this.nonce});
  final String provider;
  final String credential;
  final String? nonce;
}

/// Native provider credential collection only. Verification always happens in Spring Boot.
class SocialProviderLogin {
  static bool _googleInitialized = false;
  static Future<SocialCredential> obtain(String provider) async {
    switch (provider) {
      case 'google':
        const webClientId =
            String.fromEnvironment('SAJHA_GOOGLE_WEB_CLIENT_ID');
        if (webClientId.isEmpty) {
          throw const BackendAuthException('Google sign-in is not configured.');
        }
        if (!_googleInitialized) {
          await GoogleSignIn.instance.initialize(serverClientId: webClientId);
          _googleInitialized = true;
        }
        if (!GoogleSignIn.instance.supportsAuthenticate()) {
          throw const BackendAuthException(
              'Google sign-in is unavailable on this device.');
        }
        final account = await GoogleSignIn.instance.authenticate();
        final token = account.authentication.idToken;
        if (token == null || token.isEmpty) {
          throw const BackendAuthException(
              'Google did not return a valid identity token.');
        }
        return SocialCredential('google', token);
      case 'apple':
        if (!Platform.isIOS && !Platform.isMacOS) {
          throw const BackendAuthException(
              'Apple sign-in is not configured for Android yet.');
        }
        final nonce = await BackendAuth.instance.issueAppleNonce();
        final response = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName
          ],
          nonce: nonce,
        );
        final token = response.identityToken;
        if (token == null || token.isEmpty) {
          throw const BackendAuthException(
              'Apple did not return an identity token.');
        }
        return SocialCredential('apple', token, nonce: nonce);
      case 'facebook':
        // Meta's iOS Limited Login uses an OIDC authentication token, NOT a Graph
        // access token. It must never be sent to the Graph debug_token flow.
        if (!Platform.isAndroid) {
          throw const BackendAuthException(
              'Facebook iOS login requires Limited Login verification configuration.');
        }
        const appId = String.fromEnvironment('SAJHA_FACEBOOK_APP_ID');
        if (appId.isEmpty) {
          throw const BackendAuthException(
              'Facebook sign-in is not configured.');
        }
        final result = await FacebookAuth.instance
            .login(permissions: ['public_profile', 'email']);
        if (result.status != LoginStatus.success ||
            result.accessToken == null) {
          throw const BackendAuthException(
              'Facebook sign-in was cancelled or unsuccessful.');
        }
        return SocialCredential('facebook', result.accessToken!.tokenString);
      default:
        throw const BackendAuthException('Unsupported sign-in provider.');
    }
  }
}
