import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/user_role.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  late final TextEditingController _nameController;
  UserRole _role = UserRole.consumer;
  bool _isSaving = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _authService.currentUser?.displayName ?? '');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _firestoreService.getUserProfile();
      if (mounted && profile != null) {
        setState(() => _role = profile.role);
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Update Firebase Auth display name.
      await user.updateDisplayName(_nameController.text.trim());
      await user.reload();

      // Keep the Firestore profile doc in sync too (name + role).
      await _firestoreService.saveUserProfile(
        UserProfileModel(
          uid: user.uid,
          name: _nameController.text.trim(),
          email: user.email ?? '',
          role: _role,
          createdAt: user.metadata.creationTime ?? DateTime.now(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t save: $e'), backgroundColor: AppColors.unsafe),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Stack(
        children: [
          const AppBackground(),
          _isLoadingProfile
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Full name', style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(hintText: 'Enter your full name'),
                        validator: Validators.name,
                      ),
                      const SizedBox(height: 20),

                      const Text('Email', style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(email, style: AppTextStyles.body),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Email changes require re-verification and aren\'t supported here yet.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 20),

                      const Text('I am a...', style: AppTextStyles.heading3),
                      const SizedBox(height: 10),
                      if (_role == UserRole.admin)
                        // Admins don't switch roles from here. Firestore
                        // rules only let a user self-write role: consumer or
                        // vendor, so an admin trying to "save" any change on
                        // this screen would silently fail to change their
                        // role anyway — better to show that plainly than
                        // offer buttons that don't do what they look like
                        // they do. Demoting an admin is a deliberate action
                        // handled in Admin Dashboard -> Manage Users instead.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.admin_panel_settings_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Admin — role changes happen in Admin Dashboard > '
                                  'Manage Users, not here.',
                                  style: AppTextStyles.bodySecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // ADMIN IS DELIBERATELY NOT AN OPTION HERE, for the
                        // same reason it was removed from the register
                        // screen: letting any signed-in user tap a chip and
                        // save role: admin would be a real privilege
                        // escalation path, not a cosmetic one.
                        Row(
                          children: [
                            Expanded(
                              child: _RoleChip(
                                label: 'Consumer',
                                selected: _role == UserRole.consumer,
                                onTap: () => setState(() => _role = UserRole.consumer),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _RoleChip(
                                label: 'Vendor / Shop',
                                selected: _role == UserRole.vendor,
                                onTap: () => setState(() => _role = UserRole.vendor),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),

                      CustomButton(label: 'Save Changes', onPressed: _handleSave, isLoading: _isSaving),
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

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : Theme.of(context).dividerColor, width: selected ? 1.6 : 1),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySecondary.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
