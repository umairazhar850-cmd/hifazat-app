import 'package:flutter/material.dart';

/// Tightened type scale — the previous sizes read as oversized/templated.
/// These are noticeably smaller across the board, closer to what
/// intentionally-designed apps (not default Material scaffolding) use.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3);
  static const TextStyle heading2 = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2);
  static const TextStyle heading3 = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const TextStyle body = TextStyle(fontSize: 13, fontWeight: FontWeight.normal);

  static const Color _neutralSecondary = Color(0xFF8A97A0);
  static const TextStyle bodySecondary = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: _neutralSecondary);
  static const TextStyle caption = TextStyle(fontSize: 10.5, fontWeight: FontWeight.normal, color: _neutralSecondary);

  static const TextStyle button = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  // Big display numbers for stat tiles/bento cards — the one place we go
  // LARGER than before, for the "confident data" look from the reference.
  static const TextStyle displayNumber = TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8);
}
