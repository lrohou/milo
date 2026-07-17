import 'package:flutter/material.dart';

/// Palette Milo — Néo-brutalisme + Glassmorphisme
abstract final class AppColors {
  // Backgrounds profonds & bordures
  static const Color backgroundDeep = Color(0xFF111111);
  static const Color backgroundSurface = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF111111);

  // Textes & fonds clairs
  static const Color cream = Color(0xFFFFFED5);

  // Accents néo-brutalistes
  static const Color yellowVivid = Color(0xFFFEE402);
  static const Color yellowGold = Color(0xFFF5B800);

  // Glassmorphisme
  static const Color glassFill = Color(0x33FFFED5);
  static const Color glassBorder = Color(0x55FFFED5);

  // États
  static const Color error = Color(0xFFFF4444);
  static const Color success = Color(0xFF44FF88);
}
