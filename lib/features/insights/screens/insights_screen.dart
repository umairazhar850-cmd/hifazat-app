import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/community_stats_model.dart';

/// The screen behind the "regulatory body / health department / NGO"
/// stakeholder story — see the stakeholder value-chain diagram. Nobody
/// outside the app needs their own login; they receive this exported
/// report instead. Real data, computed live via Firestore collectionGroup.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _firestoreService = FirestoreService();
  bool _exporting = false;

  Future<void> _exportReport(CommunityStatsModel stats) async {
    setState(() => _exporting = true);
    try {
      final doc = pw.Document();
      final now = DateTime.now();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(28),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('HIFAZAT Community Safety Report',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Generated: ${now.day}/${now.month}/${now.year}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.SizedBox(height: 20),

                  pw.Text('Overview', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  _pdfRow('Total tests recorded', '${stats.totalTests}'),
                  _pdfRow('Safe results', '${stats.safeCount} (${stats.safePercent.toStringAsFixed(1)}%)'),
                  _pdfRow('Caution results', '${stats.cautionCount} (${stats.cautionPercent.toStringAsFixed(1)}%)'),
                  _pdfRow('Unsafe results', '${stats.unsafeCount} (${stats.unsafePercent.toStringAsFixed(1)}%)'),
                  _pdfRow('Most tested sample type', stats.mostTestedSampleType),
                  _pdfRow('Inconclusive readings excluded',
                      '${stats.inconclusiveCount} (${stats.inconclusiveRate.toStringAsFixed(1)}% of all readings)'),
                  if (stats.averageMilkPurity != null)
                    _pdfRow('Average milk purity',
                        '${stats.averageMilkPurity!.toStringAsFixed(1)}%'),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Note: readings below 80% model confidence are excluded from the '
                    'percentages above. They are reported separately as a data-quality '
                    'signal rather than folded into safe/unsafe counts.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 20),

                  pw.Text('Top reported contaminants', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  if (stats.topContaminants().isEmpty)
                    pw.Text('No contaminants reported yet.', style: const pw.TextStyle(fontSize: 11))
                  else
                    ...stats.topContaminants(limit: 5).map(
                      (entry) => _pdfRow(entry.key, '${entry.value} reports'),
                    ),
                  pw.SizedBox(height: 24),

                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'This report aggregates anonymized test data from the HIFAZAT app. '
                    'Intended for review by regulatory bodies (e.g. PFA/PSQCA), public health '
                    'departments, and NGO/research partners to help prioritize inspections and '
                    'awareness campaigns.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.sharePdf(bytes: await doc.save(), filename: 'hifazat_community_report.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t export report: $e'), backgroundColor: AppColors.unsafe),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Insights')),
      body: StreamBuilder<CommunityStatsModel>(
        stream: _firestoreService.streamCommunityStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Couldn\'t load insights: ${snapshot.error}', style: AppTextStyles.bodySecondary));
          }

          final stats = snapshot.data ?? CommunityStatsModel.empty();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aggregated, anonymized data across all HIFAZAT users — the same data that would be shared with regulatory bodies, health departments, and NGOs.',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Total tests', value: '${stats.totalTests}', color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Unsafe rate', value: '${stats.unsafePercent.toStringAsFixed(0)}%', color: AppColors.unsafe)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Caution rate', value: '${stats.cautionPercent.toStringAsFixed(0)}%', color: AppColors.caution)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Most tested', value: stats.mostTestedSampleType, color: AppColors.safe, small: true)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Avg milk purity',
                        value: stats.averageMilkPurity == null
                            ? '—'
                            : '${stats.averageMilkPurity!.toStringAsFixed(0)}%',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Inconclusive',
                        value: '${stats.inconclusiveRate.toStringAsFixed(0)}%',
                        color: AppColors.textSecondary,
                        small: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('Top reported contaminants', style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                if (stats.topContaminants().isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(14),
                    child: const Text('No contaminants reported yet.', style: AppTextStyles.bodySecondary),
                  )
                else
                  ...stats.topContaminants(limit: 5).map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        borderRadius: BorderRadius.circular(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: AppTextStyles.body),
                            Text('${entry.value} reports', style: AppTextStyles.bodySecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _exporting ? null : () => _exportReport(stats),
                    icon: _exporting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                    label: Text(_exporting ? 'Preparing report...' : 'Export Community Report (PDF)'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool small;

  const _StatCard({required this.label, required this.value, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: (small ? AppTextStyles.heading3 : AppTextStyles.heading2).copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }
}
