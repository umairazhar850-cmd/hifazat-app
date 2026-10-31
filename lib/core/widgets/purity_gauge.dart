import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Visualises the milk purity percentage from the ML model.
class PurityGauge extends StatelessWidget {
  final double purityPercent; // 0-100

  const PurityGauge({super.key, required this.purityPercent});

  // Keep colors synced with the result screen logic
  Color get _color {
    if (purityPercent > 85) return AppColors.safe;
    if (purityPercent >= 80) return AppColors.caution;
    return AppColors.unsafe;
  }

  // ==========================================
  // --- CUSTOM FYP VERDICT WORDS ---
  // ==========================================
  String get _verdictWord {
    if (purityPercent > 85) {
      return 'Not adulterated'; // Shows for 86% and above
    }
    if (purityPercent >= 70) {
      return 'Slightly adulterated'; // Shows for 70% to 85%
    }
    return 'Adulterated'; // Shows for 69% and below
  }

  @override
  Widget build(BuildContext context) {
    final impurity = 100 - purityPercent;
    final fraction = (purityPercent / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_rounded, size: 18, color: _color),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Milk Purity', style: AppTextStyles.heading3),
              ),
              // We added the text back here, using your custom words
              Text(
                _verdictWord,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                purityPercent.toStringAsFixed(0),
                style: AppTextStyles.displayNumber.copyWith(color: _color),
              ),
              Text(
                '% pure',
                style: AppTextStyles.heading3.copyWith(color: _color),
              ),
              const Spacer(),
              Text(
                '${impurity.toStringAsFixed(0)}% impure',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Simple proportional bar — pure portion vs impure portion.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (fraction * 1000).round().clamp(1, 1000),
                    child: Container(color: _color),
                  ),
                  Expanded(
                    flex: ((1 - fraction) * 1000).round().clamp(1, 1000),
                    child: Container(color: Theme.of(context).dividerColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Estimated from TDS, turbidity, colour and gas readings. '
            'Purity below 95% usually means added water, starch, or detergent.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
