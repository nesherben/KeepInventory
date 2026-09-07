import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF009688);
  static const primaryDark = Color(0xFF00695C);
  static const primarySoft = Color(0xFFE0F2F1);

  static const background = Color(0xFFF6F8F7);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF1F5F3);

  static const text = Color(0xFF18312D);
  static const textMuted = Color(0xFF52615D);
  static const textSubtle = Color(0xFF6B7773);
  static const outline = Color(0xFFD6DEDB);
  static const outlineSoft = Color(0xFFE7ECEA);

  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFD32F2F);
  static const info = Color(0xFF1976D2);
  static const accent = Color(0xFFFFB300);

  static const onPrimary = Colors.white;
  static const onSurface = text;
}
