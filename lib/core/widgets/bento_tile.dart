import 'package:flutter/material.dart';
// import '../constants/app_text_styles.dart'; // Removed: unused import

/// Solid-color "bento" tile — deliberately bold and flat, not translucent.
/// This is the building block for the new Home dashboard, styled after
/// confident, custom-designed dashboards rather than default Material
/// cards. Each tile owns its own color so the grid reads as intentionally
/// designed, not templated.
class BentoTile extends StatelessWidget {
  final Color color;
  final Color? textColor;
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const BentoTile({
    super.key,
    required this.color,
    required this.child,
    this.textColor,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: textColor ?? Colors.white),
        child: child,
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: content,
      ),
    );
  }
}

/// Small icon badge used inside bento tiles — a translucent white circle
/// so it reads clearly against any tile color.
class BentoIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;

  const BentoIconBadge({super.key, required this.icon, this.size = 42, this.iconSize = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
