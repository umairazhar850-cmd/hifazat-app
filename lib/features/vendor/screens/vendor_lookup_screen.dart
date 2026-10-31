import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/vendor_model.dart';

/// The consumer side of the vendor feature: find shops that have been verified
/// and see what real test results say about them.
///
/// Only VERIFIED vendors are listed — see FirestoreService.streamVerifiedVendors.
class VendorLookupScreen extends StatefulWidget {
  const VendorLookupScreen({super.key});

  @override
  State<VendorLookupScreen> createState() => _VendorLookupScreenState();
}

class _VendorLookupScreenState extends State<VendorLookupScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verified Vendors')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search by shop name or city',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<VendorModel>>(
                    stream: _firestoreService.streamVerifiedVendors(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final all = snapshot.data ?? [];
                      final vendors = all.where((v) {
                        if (_query.isEmpty) return true;
                        return v.businessName.toLowerCase().contains(_query) ||
                            v.city.toLowerCase().contains(_query);
                      }).toList();

                      // Best-scoring shops first; shops without enough data sink
                      // to the bottom rather than being ranked on noise.
                      vendors.sort((a, b) {
                        final aScore = a.trustScore ?? -1;
                        final bScore = b.trustScore ?? -1;
                        return bScore.compareTo(aScore);
                      });

                      if (vendors.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.storefront_outlined,
                                  size: 52,
                                  color: AppColors.disabled,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  all.isEmpty
                                      ? 'No verified vendors yet.'
                                      : 'No vendors match "$_query".',
                                  style: AppTextStyles.heading3,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                if (all.isEmpty)
                                  const Text(
                                    'Vendors appear here once an admin has verified them.',
                                    style: AppTextStyles.bodySecondary,
                                    textAlign: TextAlign.center,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                        itemCount: vendors.length,
                        itemBuilder: (context, index) =>
                            _VendorCard(vendor: vendors[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final VendorModel vendor;
  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final score = vendor.trustScore;
    final scoreColor = score == null
        ? AppColors.textSecondary
        : score >= 80
        ? AppColors.safe
        : score >= 60
        ? AppColors.caution
        : AppColors.unsafe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          vendor.businessName,
                          style: AppTextStyles.heading3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: AppColors.safe,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vendor.businessType.label} • ${vendor.city}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vendor.trustScoreLabel,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (score != null) ...[
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.toStringAsFixed(0)}%',
                    style: AppTextStyles.heading2.copyWith(color: scoreColor),
                  ),
                  Text('trust', style: AppTextStyles.caption),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
