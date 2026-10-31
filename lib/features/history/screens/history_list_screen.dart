import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/severity_badge.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/sample_type.dart';
import '../../../models/test_result_model.dart';

class HistoryListScreen extends StatelessWidget {
  HistoryListScreen({super.key});

  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Test History', style: AppTextStyles.heading1),
          const SizedBox(height: 4),
          const Text('All your past water and milk tests', style: AppTextStyles.bodySecondary),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<TestResultModel>>(
              stream: _firestoreService.streamTestHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Couldn\'t load history: ${snapshot.error}', style: AppTextStyles.bodySecondary),
                  );
                }
                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return const Center(child: Text('No tests yet.', style: AppTextStyles.bodySecondary));
                }
                return ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return _HistoryTile(
                      result: item,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.historyDetail, arguments: item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TestResultModel result;
  final VoidCallback onTap;
  const _HistoryTile({required this.result, required this.onTap});

  IconData get _icon {
    switch (result.sampleType) {
      case SampleType.water:
        return Icons.water_drop_rounded;
      case SampleType.milk:
        return Icons.local_drink_rounded;
    }
  }

  // Goes through result.verdict (not result.severity) so a low-confidence
  // test shows RE-TEST here too, exactly as it does on the result screen.
  Severity get _severity => SeverityX.fromResult(result);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(_icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.sampleType.label, style: AppTextStyles.heading3),
                const SizedBox(height: 2),
                Text(
                  result.isInconclusive
                      ? 'Low confidence — re-test recommended'
                      : result.purityPercent != null
                      ? '${result.purityPercent!.toStringAsFixed(0)}% pure • ${result.contaminant ?? 'No contaminant detected'}'
                      : (result.contaminant ?? 'No contaminant detected'),
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
          SeverityBadge(severity: _severity),
        ],
      ),
    );
  }
}
