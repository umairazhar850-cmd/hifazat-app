import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/user_role.dart';

/// The only path by which an admin account can be created after the very
/// first one. Firestore rules only let a user write `role: consumer` or
/// `role: vendor` to their own document — writing `role: admin` requires
/// `isAdmin()`, so this screen is genuinely the sole route in, not a
/// convenience wrapper around something a normal user could also do.
///
/// Because of that, every promotion here is a real trust decision, not a
/// cosmetic toggle — the confirmation dialogs are deliberate friction, not
/// decoration.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
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
    final myUid = AuthService().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
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
                      hintText: 'Search by name or email',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<UserProfileModel>>(
                    stream: _firestoreService.streamAllUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Couldn\'t load users: ${snapshot.error}',
                              style: AppTextStyles.bodySecondary,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final all = snapshot.data ?? [];
                      final users = all.where((u) {
                        if (_query.isEmpty) return true;
                        return u.name.toLowerCase().contains(_query) ||
                            u.email.toLowerCase().contains(_query);
                      }).toList();

                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            all.isEmpty ? 'No users yet.' : 'No match for "$_query".',
                            style: AppTextStyles.bodySecondary,
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _UserTile(
                            user: user,
                            isSelf: user.uid == myUid,
                            firestoreService: _firestoreService,
                          );
                        },
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

class _UserTile extends StatelessWidget {
  final UserProfileModel user;
  final bool isSelf;
  final FirestoreService firestoreService;

  const _UserTile({
    required this.user,
    required this.isSelf,
    required this.firestoreService,
  });

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFF4A3C7A);
      case UserRole.vendor:
        return const Color(0xFF8A5A20);
      case UserRole.consumer:
        return AppColors.primary;
    }
  }

  Future<void> _confirmAndSetRole(BuildContext context, UserRole newRole) async {
    final isPromotingToAdmin = newRole == UserRole.admin;
    final isDemotingSelf = isSelf && user.role == UserRole.admin && newRole != UserRole.admin;
    final isDemotingAnAdmin = user.role == UserRole.admin && newRole != UserRole.admin;

    // FLAW FIX: previously nothing stopped demoting the very last admin,
    // which would lock the whole app out of admin functions with no way back
    // in except editing Firestore by hand again — exactly the manual step
    // this screen exists to replace.
    if (isDemotingAnAdmin) {
      final adminCount = await firestoreService.countAdmins();
      if (adminCount <= 1) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cannot remove the last admin'),
            content: Text(
              '${user.name} is currently the only admin. Promote at least one '
              'other user to Admin first, then you can change this.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isPromotingToAdmin ? 'Make ${user.name} an admin?' : 'Change role?',
        ),
        content: Text(
          isPromotingToAdmin
              ? '${user.name} will get full access to vendor verification, area '
                  'alert broadcasts, and every user\'s data. Only do this for '
                  'people you genuinely trust with that.'
              : isDemotingSelf
                  ? 'You are about to remove your own admin access. If no one '
                      'else is an admin, you will need to reset this manually in '
                      'the Firebase console afterward.'
                  : 'Set ${user.name}\'s role to ${newRole.label}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Confirm',
              style: TextStyle(
                color: isPromotingToAdmin || isDemotingSelf
                    ? AppColors.unsafe
                    : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await firestoreService.setUserRole(uid: user.uid, role: newRole);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} is now ${newRole.label}.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update role: $e'),
          backgroundColor: AppColors.unsafe,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.role);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                user.role == UserRole.admin
                    ? Icons.admin_panel_settings_rounded
                    : user.role == UserRole.vendor
                        ? Icons.storefront_rounded
                        : Icons.person_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name.isEmpty ? '(no name)' : user.name,
                          style: AppTextStyles.heading3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        Text('(you)', style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<UserRole>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              onSelected: (role) => _confirmAndSetRole(context, role),
              itemBuilder: (context) => UserRole.values
                  .where((r) => r != user.role)
                  .map(
                    (r) => PopupMenuItem(
                      value: r,
                      child: Text('Make ${r.label}'),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
