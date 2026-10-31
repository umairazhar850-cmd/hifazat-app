import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/sample_type.dart';
import '../../../models/test_result_model.dart';
import '../../../models/vendor_model.dart';

/// What a vendor sees about their own shop: are they verified, what is their
/// public trust score, and which consumer tests are driving it.
class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('My Business')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: StreamBuilder<VendorModel?>(
              stream: firestoreService.streamMyVendorProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final vendor = snapshot.data;
                if (vendor == null) {
                  return _NotRegisteredYet();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _VerificationBanner(vendor: vendor),
                      const SizedBox(height: 16),
                      _TrustScoreCard(vendor: vendor),
                      const SizedBox(height: 16),
                      _BusinessDetailsCard(vendor: vendor),
                      const SizedBox(height: 18),

                      const Text(
                        'Tests tagged to your shop',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Results consumers recorded after buying from you. You can '
                        'see them, but you cannot edit or delete them — that is '
                        'what makes the score worth something.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 12),

                      StreamBuilder<List<TestResultModel>>(
                        stream: firestoreService.streamTestsForVendor(
                          vendor.vendorId,
                        ),
                        builder: (context, testSnapshot) {
                          if (testSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final tests = testSnapshot.data ?? [];
                          if (tests.isEmpty) {
                            return GlassCard(
                              padding: const EdgeInsets.all(20),
                              borderRadius: BorderRadius.circular(16),
                              child: const Text(
                                'No consumer has tagged a test to your shop yet.',
                                style: AppTextStyles.bodySecondary,
                              ),
                            );
                          }

                          return Column(
                            children: tests
                                .map((t) => _VendorTestTile(result: t))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotRegisteredYet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 56,
              color: AppColors.disabled,
            ),
            const SizedBox(height: 14),
            const Text(
              'You haven\'t registered your business',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Register to get verified and start building a public trust score.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Register business',
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.vendorRegistration),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  final VendorModel vendor;
  const _VerificationBanner({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final (color, icon, message) = switch (vendor.verificationStatus) {
      VerificationStatus.verified => (
        AppColors.safe,
        Icons.verified_rounded,
        'Your business is verified. Consumers can find you in vendor search.',
      ),
      VerificationStatus.pending => (
        AppColors.caution,
        Icons.hourglass_top_rounded,
        'Waiting for an admin to review your registration. You won\'t appear in '
            'vendor search until then.',
      ),
      VerificationStatus.rejected => (
        AppColors.unsafe,
        Icons.cancel_rounded,
        vendor.rejectionReason ??
            'Your registration was rejected. Contact the admin for details.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.verificationStatus.label,
                  style: AppTextStyles.heading3.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustScoreCard extends StatelessWidget {
  final VendorModel vendor;
  const _TrustScoreCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final score = vendor.trustScore;

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
          const Text('Public trust score', style: AppTextStyles.heading3),
          const SizedBox(height: 12),

          if (score == null) ...[
            Text(
              'Not enough data yet',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${vendor.totalTests} of ${AppConstants.minTestsForTrustScore} tests needed. '
              'A score built on one or two tests would mislead people, so we don\'t '
              'show one.',
              style: AppTextStyles.caption,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  score.toStringAsFixed(0),
                  style: AppTextStyles.displayNumber.copyWith(
                    color: score >= 80
                        ? AppColors.safe
                        : score >= 60
                        ? AppColors.caution
                        : AppColors.unsafe,
                  ),
                ),
                const Text('%', style: AppTextStyles.heading2),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${vendor.safeTests} of ${vendor.totalTests} tagged tests came back safe.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Inconclusive tests (below ${(AppConstants.confidenceThreshold * 100).toInt()}% '
              'model confidence) are excluded and never affect this score.',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _BusinessDetailsCard extends StatelessWidget {
  final VendorModel vendor;
  const _BusinessDetailsCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vendor.businessName, style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          _row(Icons.category_rounded, vendor.businessType.label),
          _row(Icons.location_on_rounded, '${vendor.address}, ${vendor.city}'),
          _row(Icons.badge_rounded, vendor.registrationNumber),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySecondary)),
        ],
      ),
    );
  }
}

class _VendorTestTile extends StatelessWidget {
  final TestResultModel result;
  const _VendorTestTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (result.verdict) {
      DisplayVerdict.safe => (AppColors.safe, 'SAFE'),
      DisplayVerdict.caution => (AppColors.caution, 'CAUTION'),
      DisplayVerdict.unsafe => (AppColors.unsafe, 'UNSAFE'),
      DisplayVerdict.inconclusive => (
        AppColors.textSecondary,
        'INCONCLUSIVE',
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.sampleType.label, style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(
                  result.purityPercent != null
                      ? '${result.purityPercent!.toStringAsFixed(0)}% pure • ${_date(result.testedAt)}'
                      : _date(result.testedAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
