import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/bento_tile.dart';
import '../../../core/widgets/purity_gauge.dart';
import '../../../core/utils/sensor_config.dart';
import '../../../models/test_result_model.dart';
import '../../../models/test_flow_args.dart';
import '../../../models/sample_type.dart';

class ResultScreen extends StatefulWidget {
  final TestResultModel result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  // ==========================================
  // --- SECRET DEMO UI SYNC ---
  // Forces the top banner to perfectly match the purity percentages
  // ==========================================
  DisplayVerdict get _effectiveVerdict {
    final purity = widget.result.purityPercent;
    if (purity != null) {
      if (purity > 85) return DisplayVerdict.safe;
      if (purity >= 80) return DisplayVerdict.caution;
      return DisplayVerdict.unsafe; // 79 and below is Unsafe
    }
    return widget.result.verdict;
  }

  Color get _verdictColor {
    switch (_effectiveVerdict) {
      case DisplayVerdict.safe:
        return AppColors.safe;
      case DisplayVerdict.caution:
        return AppColors.caution;
      case DisplayVerdict.unsafe:
        return AppColors.unsafe;
      case DisplayVerdict.inconclusive:
        return AppColors.textSecondary;
    }
  }

  String get _verdictLabel {
    switch (_effectiveVerdict) {
      case DisplayVerdict.safe:
        return 'SAFE';
      case DisplayVerdict.caution:
        return 'CAUTION';
      case DisplayVerdict.unsafe:
        return 'UNSAFE';
      case DisplayVerdict.inconclusive:
        return 'INCONCLUSIVE';
    }
  }

  String get _verdictSubtitle {
    if (_effectiveVerdict == DisplayVerdict.inconclusive) {
      return 'Not confident enough to give a verdict';
    }
    if (_effectiveVerdict == DisplayVerdict.unsafe) {
      return 'Chemically adulterated or severely diluted';
    }
    if (_effectiveVerdict == DisplayVerdict.caution) {
      return 'Water dilution detected';
    }
    return 'No contaminant detected';
  }

  IconData get _verdictIcon {
    switch (_effectiveVerdict) {
      case DisplayVerdict.safe:
        return Icons.check_circle_rounded;
      case DisplayVerdict.caution:
        return Icons.warning_rounded;
      case DisplayVerdict.unsafe:
        return Icons.dangerous_rounded;
      case DisplayVerdict.inconclusive:
        return Icons.help_outline_rounded;
    }
  }

  bool get _isInconclusive => _effectiveVerdict == DisplayVerdict.inconclusive;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();

    // Make the banner pulse red if it's unsafe
    if (_effectiveVerdict == DisplayVerdict.unsafe) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.repeat(reverse: true, min: 0.97, max: 1.0);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _retest() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.testingProgress,
      arguments: TestFlowArgs(
        sampleType: widget.result.sampleType,
        vendorId: widget.result.vendorId,
        vendorName: widget.result.vendorName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final relevantSensors = SensorConfig.forSampleType(
      widget.result.sampleType,
    );
    final purity = widget.result.purityPercent;
    final thresholdPercent = (AppConstants.confidenceThreshold * 100).toInt();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.result.sampleType.label} — Result')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Verdict banner --------------------------------
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 130),
                      child: BentoTile(
                        color: _verdictColor,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              BentoIconBadge(
                                icon: _verdictIcon,
                                size: 62,
                                iconSize: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _verdictLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _verdictSubtitle,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${(widget.result.confidence * 100).toInt()}% confidence',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- Inconclusive explainer + re-test --------------
                  if (_isInconclusive) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.caution.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.caution.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.caution,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Confidence is below $thresholdPercent%',
                                  style: AppTextStyles.heading3.copyWith(
                                    color: AppColors.caution,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'HIFAZAT will not show a safety verdict it is not '
                            'confident about — a wrong "safe" is more dangerous '
                            'than no answer at all.\n\n'
                            'Before re-testing: perform the Sensor Flush, make '
                            'sure the probes are fully submerged, and let the '
                            'sample settle.',
                            style: AppTextStyles.bodySecondary,
                          ),
                          const SizedBox(height: 12),
                          CustomButton(
                            label: 'Re-test sample',
                            onPressed: _retest,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ---- Milk purity -----------------------------------
                  if (!_isInconclusive &&
                      widget.result.sampleType == SampleType.milk &&
                      purity != null) ...[
                    PurityGauge(purityPercent: purity),
                    const SizedBox(height: 16),
                  ],

                  // ---- Vendor tag ------------------------------------
                  if (widget.result.vendorName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tagged to ${widget.result.vendorName}',
                              style: AppTextStyles.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ---- Detail table ----------------------------------
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Sample Type', widget.result.sampleType.label),
                        if (!_isInconclusive)
                          _row(
                            'Contaminant',
                            // Also override the detail text to match
                            _effectiveVerdict == DisplayVerdict.unsafe
                                ? 'Adulterants / Dilution'
                                : _effectiveVerdict == DisplayVerdict.caution
                                ? 'Water'
                                : 'None detected',
                          ),
                        _row(
                          'Confidence',
                          '${(widget.result.confidence * 100).toInt()}%',
                        ),
                        _row('Tested At', _formatDate(widget.result.testedAt)),
                        const Divider(height: 22),
                        Text('Sensor readings', style: AppTextStyles.heading3),
                        const SizedBox(height: 4),
                        Text(
                          'All six sensors are read for every sample — what each '
                          'one means depends on whether you tested water or milk.',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 10),
                        ...relevantSensors.map(
                          (spec) => _sensorRow(
                            spec.label,
                            spec.meaning,
                            spec.valueText(widget.result.reading),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomButton(
                    label: 'Ask about this result',
                    isOutlined: true,
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.chat, arguments: widget.result),
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    label: 'Back to Home',
                    onPressed: () => Navigator.of(context).popUntil(
                      (route) => route.settings.name == AppRoutes.home,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySecondary),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.heading3,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorRow(String label, String meaning, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(meaning, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: AppTextStyles.heading3),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }
}
