import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A soft, layered background of blurred green blobs and a faint water-drop
/// pattern. THIS WAS THE BUG: it previously always painted a hardcoded
/// light fill regardless of theme, which visually covered the whole
/// screen and hid the dark scaffold background underneath — that's why
/// only the bottom nav bar (a separate widget, driven directly by
/// ThemeData) appeared to go dark. Now it reads the actual theme
/// brightness and adapts.
class AppBackground extends StatelessWidget {
  final bool dense;
  const AppBackground({super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = Theme.of(context).scaffoldBackgroundColor;
    final blobPrimary = isDark ? AppColors.primaryLight.withValues(alpha: 0.10) : AppColors.primaryLight.withValues(alpha: 0.16);
    final blobAccent = isDark ? AppColors.accent.withValues(alpha: 0.08) : AppColors.accent.withValues(alpha: 0.22);
    final blobDense = isDark ? AppColors.primary.withValues(alpha: 0.10) : AppColors.primary.withValues(alpha: 0.06);
    final dropColor = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.primary.withValues(alpha: 0.045);

    return IgnorePointer(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Container(color: baseColor),
            Positioned(
              top: -size.width * 0.35,
              right: -size.width * 0.3,
              child: _blob(size.width * 0.9, blobPrimary),
            ),
            Positioned(
              bottom: -size.width * 0.4,
              left: -size.width * 0.35,
              child: _blob(size.width * 1.0, blobAccent),
            ),
            if (dense)
              Positioned(
                top: size.height * 0.32,
                left: -size.width * 0.2,
                child: _blob(size.width * 0.6, blobDense),
              ),
            Positioned.fill(child: CustomPaint(painter: _DropPatternPainter(color: dropColor))),
          ],
        ),
      ),
    );
  }

  Widget _blob(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _DropPatternPainter extends CustomPainter {
  final Color color;
  _DropPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final positions = [
      Offset(size.width * 0.12, size.height * 0.10),
      Offset(size.width * 0.85, size.height * 0.22),
      Offset(size.width * 0.25, size.height * 0.55),
      Offset(size.width * 0.75, size.height * 0.68),
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.9, size.height * 0.92),
    ];

    for (final pos in positions) {
      _drawDrop(canvas, pos, 14, paint);
    }
  }

  void _drawDrop(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - r);
    path.quadraticBezierTo(center.dx + r, center.dy - r * 0.2, center.dx, center.dy + r);
    path.quadraticBezierTo(center.dx - r, center.dy - r * 0.2, center.dx, center.dy - r);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DropPatternPainter oldDelegate) => oldDelegate.color != color;
}
