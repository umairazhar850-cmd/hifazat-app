import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../models/test_result_model.dart';

/// The badge now has an INCONCLUSIVE state.
///
/// This matters more than it looks: without it, the history list had no way to
/// represent a low-confidence test, so it fell back to showing the model's raw
/// guess as a confident SAFE/CAUTION/UNSAFE pill. The result screen suppressed
/// the verdict correctly, but the history list quietly un-suppressed it one tap
/// later. A safety rule enforced in only one of the two places it's displayed
/// is not enforced.
enum Severity { safe, caution, unsafe, inconclusive }

extension SeverityX on Severity {
  /// Single conversion point from a test result to what we may display, so no
  /// screen has to re-derive the 80% rule (and get it wrong).
  static Severity fromResult(TestResultModel result) {
    switch (result.verdict) {
      case DisplayVerdict.safe:
        return Severity.safe;
      case DisplayVerdict.caution:
        return Severity.caution;
      case DisplayVerdict.unsafe:
        return Severity.unsafe;
      case DisplayVerdict.inconclusive:
        return Severity.inconclusive;
    }
  }
}

class SeverityBadge extends StatelessWidget {
  final Severity severity;

  const SeverityBadge({super.key, required this.severity});

  Color get _color {
    switch (severity) {
      case Severity.safe:
        return AppColors.safe;
      case Severity.caution:
        return AppColors.caution;
      case Severity.unsafe:
        return AppColors.unsafe;
      case Severity.inconclusive:
        return AppColors.textSecondary;
    }
  }

  String get _label {
    switch (severity) {
      case Severity.safe:
        return 'SAFE';
      case Severity.caution:
        return 'CAUTION';
      case Severity.unsafe:
        return 'UNSAFE';
      case Severity.inconclusive:
        return 'RE-TEST';
    }
  }

  IconData get _icon {
    switch (severity) {
      case Severity.safe:
        return Icons.check_circle;
      case Severity.caution:
        return Icons.warning_rounded;
      case Severity.unsafe:
        return Icons.dangerous_rounded;
      case Severity.inconclusive:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 18),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
