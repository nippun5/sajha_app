import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 'show' on every import prevents any name collision across files.
// This is what caused: "'MainShell' is defined in two libraries"
import '../../features/splash/splash_screen.dart'             show SplashScreen;
import '../../features/auth/login_screen.dart'                show LoginScreen;
import '../../features/auth/complete_profile_screen.dart'     show CompleteProfileScreen;
import '../../features/shell/main_shell.dart'                 show MainShell;
// import '../../features/post_listing/post_listing_screen.dart';
import '../../features/post_listing/post_listing_screen.dart'
    show PostListingScreen;
import '../constants/app_constants.dart';

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
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
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
        pageBuilder: (context, state) => NoTransitionPage(
          // No 'const' — MainShell() contains a non-const IndexedStack
          child: MainShell(),
        ),
      ),

      // ── Post Listing (modal) ─────────────────────────────────
      GoRoute(
        path: AppConstants.postListingRoute,
        pageBuilder: (context, state) => CustomTransitionPage(
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