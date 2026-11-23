import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/signup_screen.dart' show SignupScreen;

import '../../features/auth/forgot_password_screen.dart'
    show ForgotPasswordScreen;

import '../../features/auth/phone_verification_screen.dart'
    show PhoneVerificationScreen;

// 'show' on every import prevents any name collision across files.
// This is what caused: "'MainShell' is defined in two libraries"
import '../../features/splash/splash_screen.dart' show SplashScreen;
import '../../features/auth/login_screen.dart' show LoginScreen;
import '../../features/auth/complete_profile_screen.dart'
    show CompleteProfileScreen;
import '../../features/shell/main_shell.dart' show MainShell;
// import '../../features/post_listing/post_listing_screen.dart';
import '../../features/post_listing/post_listing_screen.dart'
    show PostListingScreen;
import '../constants/app_constants.dart';

import 'package:flutter/foundation.dart';
import '../auth/auth_session.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.splashRoute,
    debugLogDiagnostics: false,
    routes: [
      // ── Splash ──────────────────────────────────────────────
      GoRoute(
        path: AppConstants.splashRoute,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),

      // ── Login ────────────────────────────────────────────────
      GoRoute(
        path: AppConstants.loginRoute,
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // Signup Screen
      GoRoute(
        path: AppConstants.signupRoute,
        builder: (context, state) => const SignupScreen(),
      ),

      // Forgot Password Screen
      GoRoute(
        path: AppConstants.forgotPasswordRoute,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: AppConstants.phoneVerificationRoute,
        builder: (context, state) => const PhoneVerificationScreen(),
      ),

      // ── Complete Profile (after social login) ────────────────
      GoRoute(
        path: AppConstants.completeProfileRoute,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: CompleteProfileScreen(
            userData: state.extra as Map<String, dynamic>? ?? {},
          ),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // ── Main Shell ───────────────────────────────────────────
      // NOTE: HomeScreen & BusinessDirectoryScreen are imported
      // inside main_shell.dart — they do NOT belong in this file.
      GoRoute(
        path: AppConstants.shellRoute,
        pageBuilder: (context, state) => const NoTransitionPage(
          // No 'const' — MainShell() contains a non-const IndexedStack
          child: MainShell(),
        ),
      ),

      // ── Post Listing (modal) ─────────────────────────────────
      GoRoute(
        path: AppConstants.postListingRoute,
        redirect: (context, state) {
          final isDebugPreview =
              kDebugMode && state.uri.queryParameters['preview'] == '1';

          if (isDebugPreview || AuthSession.instance.canPost) {
            return null;
          }

          return AppConstants.loginRoute;
        },
        pageBuilder: (context, state) => const CustomTransitionPage(
          // No 'const' — PostListingScreen() uses non-const children
          child: PostListingScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
    ],
  );

  // ── Transition helpers ───────────────────────────────────────
  static Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      FadeTransition(opacity: animation, child: child);

  static Widget _slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
}
