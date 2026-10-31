import 'package:flutter/material.dart';

/// HIFAZAT app color palette — natural/eco green theme.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1B7A43); // deep natural green
  static const Color primaryDark = Color(0xFF0F5C30);
  static const Color primaryLight = Color(0xFF4CAF6D);
  static const Color accent = Color(0xFFA6E3B8); // soft mint green

  // Backgrounds
  static const Color background = Color(0xFFF6FBF7); // near-white with green tint
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A1B7A43);

  // Text
  static const Color textPrimary = Color(0xFF1A2E22);
  static const Color textSecondary = Color(0xFF8A97A0); // neutral grey - reads fine on light and dark backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Severity levels (used across testing/history/analytics)
  static const Color safe = Color(0xFF2E9E5B);
  static const Color caution = Color(0xFFE3A712);
  static const Color unsafe = Color(0xFFD64545);

  // Utility
  static const Color divider = Color(0xFFE0EAE3);
  static const Color disabled = Color(0xFFB7C4BB);
}
