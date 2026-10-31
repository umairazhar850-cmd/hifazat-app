import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/bento_tile.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/localization/app_strings.dart';
import '../../../main.dart' show localeController;
import '../../../models/alert_model.dart';
import '../../../models/sample_type.dart';
import '../../../models/user_role.dart';
import '../../history/screens/history_list_screen.dart';
import '../../analytics/screens/trend_graph_screen.dart';
import '../../map/screens/hotspot_map_screen.dart';
import '../../settings/screens/settings_screen.dart';

const _waterColor = Color(0xFF1B5FA8);
const _milkColor = Color(0xFF7A4FA0);
const _insightsColor = Color(0xFF16241C);
const _vendorColor = Color(0xFF8A5A20);
const _adminColor = Color(0xFF4A3C7A);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const _DashboardTab(),
    HistoryListScreen(),
    const TrendGraphScreen(),
    const HotspotMapScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(child: IndexedStack(index: _currentIndex, children: _tabs)),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.chat),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
            )
          : null,
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _firestoreService = FirestoreService();
  UserRole _role = UserRole.consumer;
  int? _testCount;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadCount();
  }

  Future<void> _loadRole() async {
    try {
      final profile = await _firestoreService.getUserProfile();
      if (mounted && profile != null) setState(() => _role = profile.role);
    } catch (_) {}
  }

  Future<void> _loadCount() async {
    try {
      final count = await _firestoreService.getTestCount();
      if (mounted) setState(() => _testCount = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final displayName = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : 'there';
    final screenWidth = MediaQuery.of(context).size.width;
    final gridRowHeight = (screenWidth * 0.40).clamp(140.0, 220.0);

    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final isUrdu = localeController.isUrdu;
        final greetingSubtitle = switch (_role) {
          UserRole.vendor => AppStrings.get('home_greeting_vendor', isUrdu: isUrdu),
          UserRole.admin => AppStrings.get('home_greeting_admin', isUrdu: isUrdu),
          UserRole.consumer => AppStrings.get(
            'home_greeting_consumer',
            isUrdu: isUrdu,
          ),
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, $displayName 👋', style: AppTextStyles.heading1),
                        const SizedBox(height: 2),
                        Text(greetingSubtitle, style: AppTextStyles.bodySecondary),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'How to use HIFAZAT',
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.help),
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---- Active area alerts from an admin ------------------
              const _AlertsBanner(),

              // ---- Water / Milk test tiles ---------------------------
              SizedBox(
                height: gridRowHeight,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _SampleTile(
                          color: _waterColor,
                          icon: Icons.water_drop_rounded,
                          title: AppStrings.get('home_water', isUrdu: isUrdu),
                          // All six sensors run for both samples now — the
                          // subtitle no longer implies water uses only four.
                          subtitle: 'All 6 sensors • SAFE / UNSAFE',
                          sampleType: SampleType.water,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SampleTile(
                          color: _milkColor,
                          icon: Icons.local_drink_rounded,
                          title: AppStrings.get('home_milk', isUrdu: isUrdu),
                          subtitle: 'All 6 sensors • + purity %',
                          sampleType: SampleType.milk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ---- Role-specific tile --------------------------------
              if (_role == UserRole.vendor)
                _WideTile(
                  color: _vendorColor,
                  icon: Icons.storefront_rounded,
                  title: 'My Business',
                  subtitle: 'Verification status • Trust score',
                  route: AppRoutes.vendorDashboard,
                )
              else if (_role == UserRole.admin)
                _WideTile(
                  color: _adminColor,
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Admin Dashboard',
                  subtitle: 'Verify vendors • Broadcast alerts',
                  route: AppRoutes.adminDashboard,
                )
              else
                _WideTile(
                  color: _vendorColor,
                  icon: Icons.verified_rounded,
                  title: 'Verified Vendors',
                  subtitle: 'Find shops with a public trust score',
                  route: AppRoutes.vendorLookup,
                ),
              const SizedBox(height: 10),

              _WideTile(
                color: _insightsColor,
                icon: Icons.insights_rounded,
                title: AppStrings.get('home_insights', isUrdu: isUrdu),
                subtitle: 'Community stats • Export PDF',
                route: AppRoutes.insights,
              ),
              const SizedBox(height: 18),

              Text(
                AppStrings.get('home_recent_activity', isUrdu: isUrdu),
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.checklist_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testCount == null
                            ? 'Loading your test history...'
                            : _testCount == 0
                            ? 'No tests yet — tap a tile above to run your first test.'
                            : 'You\'ve run $_testCount test${_testCount == 1 ? '' : 's'} so far. See them in the History tab.',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shows any active admin-broadcast alerts. Rendered above the test tiles
/// because a "do not drink the tap water in your area" warning is more urgent
/// than anything else on this screen.
class _AlertsBanner extends StatelessWidget {
  const _AlertsBanner();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AlertModel>>(
      stream: FirestoreService().streamActiveAlerts(),
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) return const SizedBox.shrink();

        final alert = alerts.first; // most recent
        final color = switch (alert.level) {
          AlertSeverityLevel.info => AppColors.primary,
          AlertSeverityLevel.warning => AppColors.caution,
          AlertSeverityLevel.danger => AppColors.unsafe,
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.campaign_rounded, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: AppTextStyles.heading3.copyWith(color: color),
                      ),
                      const SizedBox(height: 2),
                      Text(alert.body, style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 4),
                      Text(alert.area, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SampleTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final SampleType sampleType;

  const _SampleTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.sampleType,
  });

  @override
  Widget build(BuildContext context) {
    return BentoTile(
      color: color,
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.deviceConnect, arguments: sampleType),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BentoIconBadge(icon: icon, size: 44, iconSize: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WideTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _WideTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return BentoTile(
      color: color,
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            BentoIconBadge(icon: icon, size: 46, iconSize: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.heading3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
