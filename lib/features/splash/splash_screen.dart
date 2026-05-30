import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // 1. Import the package
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _dotCtrl;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    // 2. DISMISS THE NATIVE SPLASH
    // This tells the native layer to disappear because our animated Flutter widget is ready!
    FlutterNativeSplash.remove();
    
    _scheduleNavigation();
  }

  void _setupAnimations() {
    // Logo: fade + scale in
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );

    // Dot loader: infinite bounce
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _logoCtrl.forward();
  }

  void _scheduleNavigation() {
    Future.delayed(AppConstants.splashDuration, () {
      if (mounted) context.go(AppConstants.loginRoute);
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // ── Logo ────────────────────────────────────────
            AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, child) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(scale: _logoScale.value, child: child),
              ),
              child: Image.asset(
                AppConstants.logoPath,
                width: 190,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 14),

            // ── Tagline ─────────────────────────────────────
            AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, child) =>
                  Opacity(opacity: _taglineOpacity.value, child: child),
              child: const Text(
                AppConstants.appTagline,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            const Spacer(flex: 3),

            // ── Dot loader ───────────────────────────────────
            _DotLoader(controller: _dotCtrl),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// (Keep your existing _DotLoader implementation exactly as it was below)
class _DotLoader extends StatelessWidget {
  final AnimationController controller;
  const _DotLoader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final t = ((controller.value + i * 0.22) % 1.0) * 2 * 3.14159;
            final yOffset = -6.0 * ((1 + -1 * (t < 3.14159 ? 1 : -1) * (t % 3.14159 / 3.14159 * 2 - 1)).abs()) + 6.0;
            final opacity = 0.35 + 0.65 * (yOffset / 6);
            return Transform.translate(
              offset: Offset(0, -yOffset.clamp(0.0, 6.0)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(opacity.clamp(0.3, 1.0)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}