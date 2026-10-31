import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  int? _testCount;

  @override
  void initState() {
    super.initState();
    _loadTestCount();
  }

  Future<void> _loadTestCount() async {
    try {
      final count = await _firestoreService.getTestCount();
      if (mounted) setState(() => _testCount = count);
    } catch (_) {
      if (mounted) setState(() => _testCount = 0);
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).pushNamed(AppRoutes.editProfile);
    // Refresh displayed name/email after returning from Edit Profile.
    if (updated == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final name = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : 'HIFAZAT User';
    final email = user?.email ?? 'unknown@example.com';
    final memberSince = user?.metadata.creationTime;
    final memberSinceLabel = memberSince != null ? '${_monthName(memberSince.month)} ${memberSince.year}' : '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person_rounded, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: AppTextStyles.heading2),
                  const SizedBox(height: 4),
                  Text(email, style: AppTextStyles.bodySecondary),
                  const SizedBox(height: 28),
                  _infoRow('Total Tests', _testCount?.toString() ?? '…'),
                  _infoRow('Member Since', memberSinceLabel),
                  const Spacer(),
                  CustomButton(label: 'Edit Profile', isOutlined: true, onPressed: _openEditProfile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: BorderRadius.circular(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodySecondary),
            Text(value, style: AppTextStyles.heading3),
          ],
        ),
      ),
    );
  }
}
