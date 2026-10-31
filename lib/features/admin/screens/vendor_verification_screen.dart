import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/vendor_model.dart';

/// The admin's approval queue. Approving a vendor is what makes them visible
/// to consumers in vendor search and lets them accumulate a public trust
/// score, so this is a meaningful gate rather than a formality.
class VendorVerificationScreen extends StatelessWidget {
  const VendorVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Queue')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: StreamBuilder<List<VendorModel>>(
              stream: firestoreService.streamPendingVendors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final vendors = snapshot.data ?? [];
                if (vendors.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 52,
                            color: AppColors.disabled,
                          ),
                          SizedBox(height: 12),
                          Text('Queue is empty', style: AppTextStyles.heading3),
                          SizedBox(height: 6),
                          Text(
                            'No vendors are waiting for review.',
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: vendors.length,
                  itemBuilder: (context, index) => _PendingVendorCard(
                    vendor: vendors[index],
                    firestoreService: firestoreService,
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

class _PendingVendorCard extends StatelessWidget {
  final VendorModel vendor;
  final FirestoreService firestoreService;

  const _PendingVendorCard({
    required this.vendor,
    required this.firestoreService,
  });

  Future<void> _approve(BuildContext context) async {
    await firestoreService.setVendorVerification(
      vendorId: vendor.vendorId,
      status: VerificationStatus.verified,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${vendor.businessName} verified.')),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject vendor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The vendor will see this reason, so make it actionable.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g. Registration number does not match records',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text(
              'Reject',
              style: TextStyle(color: AppColors.unsafe),
            ),
          ),
        ],
      ),
    );

    if (reason == null) return; // cancelled

    await firestoreService.setVendorVerification(
      vendorId: vendor.vendorId,
      status: VerificationStatus.rejected,
      rejectionReason: reason.isEmpty ? null : reason,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${vendor.businessName} rejected.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.caution.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.caution,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.businessName,
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vendor.businessType.label,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _detail('Address', '${vendor.address}, ${vendor.city}'),
            _detail('Registration no.', vendor.registrationNumber),
            _detail('Applied', _date(vendor.createdAt)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Reject',
                    isOutlined: true,
                    onPressed: () => _reject(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    label: 'Approve',
                    onPressed: () => _approve(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.bodySecondary),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
