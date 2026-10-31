import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/community_stats_model.dart';
import '../../../models/vendor_model.dart';

/// The authority-facing hub. Scope document, Module 8: vendor verification
/// queue, contamination trends, exportable reports, and area alert broadcast.
///
/// Reachable ONLY by a user whose Firestore `role` is `admin`. Note that the
/// UI check here is convenience, not security — the real enforcement has to
/// live in Firestore security rules, because anyone can decompile an APK and
/// call Firestore directly. See README_CHANGES.md for the rules to paste in.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin / Authority')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Live community snapshot ----------------------
                  StreamBuilder<CommunityStatsModel>(
                    stream: firestoreService.streamCommunityStats(),
                    builder: (context, snapshot) {
                      final stats =
                          snapshot.data ?? CommunityStatsModel.empty();
                      return Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total tests',
                              value: '${stats.totalTests}',
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Unsafe',
                              value:
                                  '${stats.unsafePercent.toStringAsFixed(0)}%',
                              color: AppColors.unsafe,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Inconclusive',
                              value:
                                  '${stats.inconclusiveRate.toStringAsFixed(0)}%',
                              color: AppColors.caution,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A high inconclusive rate is a hardware signal, not a safety '
                    'one — it usually means sensors need recalibration.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 20),

                  // ---- Pending verification count -------------------
                  StreamBuilder<List<VendorModel>>(
                    stream: firestoreService.streamPendingVendors(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return _AdminTile(
                        icon: Icons.verified_user_rounded,
                        title: 'Vendor verification queue',
                        subtitle: count == 0
                            ? 'No vendors waiting for review'
                            : '$count vendor${count == 1 ? '' : 's'} waiting for review',
                        badgeCount: count,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.vendorVerification),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _AdminTile(
                    icon: Icons.campaign_rounded,
                    title: 'Broadcast area alert',
                    subtitle:
                        'Warn users about contamination in a specific area',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.broadcastAlert),
                  ),
                  const SizedBox(height: 10),

                  _AdminTile(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Manage users',
                    subtitle: 'Promote or demote Consumer, Vendor, and Admin roles',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.userManagement),
                  ),
                  const SizedBox(height: 10),

                  _AdminTile(
                    icon: Icons.insights_rounded,
                    title: 'Community insights & export',
                    subtitle: 'Aggregated anonymized data, exportable as PDF',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.insights),
                  ),
                  const SizedBox(height: 10),

                  _AdminTile(
                    icon: Icons.map_rounded,
                    title: 'Contamination map',
                    subtitle: 'Hotspots reported across all users',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.home),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.heading1.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.heading3),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.unsafe,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
