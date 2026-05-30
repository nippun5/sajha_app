import 'package:flutter/material.dart';

/// Brand palette extracted directly from the Sajha handshake logo.
///
///  Navy  ·  #1E1B4B  ← logo outline & wordmark
///  Coral ·  #E05A3A  ← left hand (warm)
///  Peri  ·  #6B6FC5  ← right hand (cool)
///
/// Every colour in the app flows from this one file.
abstract final class AppColors {
  // ── Primary — deep navy ─────────────────────────────────────
  static const Color primary      = Color(0xFF1E1B4B);
  static const Color primaryLight = Color(0xFF2D2A6E);
  static const Color primaryDark  = Color(0xFF131130);
  static const Color onPrimary    = Colors.white;

  // ── Coral — logo left hand ──────────────────────────────────
  static const Color coral      = Color(0xFFE05A3A);
  static const Color coralLight = Color(0xFFF5927A);
  static const Color onCoral    = Colors.white;

  // ── Periwinkle — logo right hand ────────────────────────────
  static const Color periwinkle      = Color(0xFF6B6FC5);
  static const Color periwinkleLight = Color(0xFF9194D6);
  static const Color onPeriwinkle    = Colors.white;

  // ── Backgrounds ─────────────────────────────────────────────
  static const Color background = Color(0xFFF7F8FC); // scaffold
  static const Color surface    = Colors.white;       // cards / sheets

  // ── Text ────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF64687A);
  static const Color textHint      = Color(0xFFA0A4B4);
  static const Color onSurface     = Color(0xFF1E1B4B);

  // ── Borders ─────────────────────────────────────────────────
  static const Color border      = Color(0xFFE8EAF0);
  static const Color borderFocus = Color(0xFF1E1B4B);

  // ── Semantic ────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color error   = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

  // ── Category accents (mirrors logo palette) ─────────────────
  static const Color buySell   = coral;        // coral-red
  static const Color rentRoom  = periwinkle;   // periwinkle-blue
  static const Color jobSearch = primary;      // deep navy
  static const Color business  = Color(0xFFD97706); // amber
}
