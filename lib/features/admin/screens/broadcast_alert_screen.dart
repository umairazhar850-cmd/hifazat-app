import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/alert_model.dart';

/// Scope document, Module 8: "Add area-based safety alert broadcast to users."
///
/// This writes an alert document to Firestore, which every user's home screen
/// reads. Turning that document into an actual push notification needs a Cloud
/// Function that listens on the `alerts` collection and calls FCM — the app
/// side is ready (firebase_messaging is already a dependency), the trigger
/// function is a backend task. Flagged rather than faked.
class BroadcastAlertScreen extends StatefulWidget {
  const BroadcastAlertScreen({super.key});

  @override
  State<BroadcastAlertScreen> createState() => _BroadcastAlertScreenState();
}

class _BroadcastAlertScreenState extends State<BroadcastAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _areaController = TextEditingController();

  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  AlertSeverityLevel _level = AlertSeverityLevel.warning;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _broadcast() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    // FLAW FIX: this used to send the instant it validated, with no
    // confirmation step — a single mistap would push a real (fake) safety
    // warning to every user immediately. Vendor promotion already asks for
    // confirmation for a much smaller-blast-radius action; broadcasting to
    // the whole user base deserves at least the same courtesy.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send this alert now?'),
        content: Text(
          'This will immediately notify every HIFAZAT user with:\n\n'
          '"${_titleController.text.trim()}"\n\n'
          'Area: ${_areaController.text.trim()}\n\n'
          'Make sure this is accurate before sending.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Send alert',
              style: TextStyle(color: AppColors.unsafe, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _firestoreService.createAlert(
        AlertModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          area: _areaController.text.trim(),
          level: _level,
          createdBy: uid,
          createdAt: DateTime.now(),
          active: true,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert broadcast to users.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not broadcast: $e'),
          backgroundColor: AppColors.unsafe,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _levelColor(AlertSeverityLevel level) {
    switch (level) {
      case AlertSeverityLevel.info:
        return AppColors.primary;
      case AlertSeverityLevel.warning:
        return AppColors.caution;
      case AlertSeverityLevel.danger:
        return AppColors.unsafe;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Alert')),
      body: Stack(
        children: [
          const AppBackground(dense: true),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Every user in the app will see this on their home screen. '
                      'Use it for real contamination events, not tests.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 18),

                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      borderRadius: BorderRadius.circular(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Severity', style: AppTextStyles.heading3),
                          const SizedBox(height: 10),
                          Row(
                            children: AlertSeverityLevel.values.map((level) {
                              final selected = _level == level;
                              final color = _levelColor(level);
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => setState(() => _level = level),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? color.withValues(alpha: 0.12)
                                            : Theme.of(
                                                context,
                                              ).scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? color
                                              : Theme.of(context).dividerColor,
                                          width: selected ? 1.6 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        level.label,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.bodySecondary
                                            .copyWith(
                                              color: selected
                                                  ? color
                                                  : AppColors.textSecondary,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.normal,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          const Text('Area', style: AppTextStyles.heading3),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _areaController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Mandian, Abbottabad',
                            ),
                            validator: (v) =>
                                Validators.required(v, message: 'Area is required'),
                          ),
                          const SizedBox(height: 20),

                          const Text('Title', style: AppTextStyles.heading3),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Do not drink tap water',
                            ),
                            validator: (v) => Validators.required(
                              v,
                              message: 'Title is required',
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text('Message', style: AppTextStyles.heading3),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _bodyController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText:
                                  'Explain what happened and what people should do.',
                            ),
                            validator: (v) => Validators.required(
                              v,
                              message: 'Message is required',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      label: 'Broadcast alert',
                      onPressed: _broadcast,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
