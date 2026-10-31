import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_role.dart';
import '../../../models/user_profile_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.consumer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final credential = await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      await _firestoreService.saveUserProfile(
        UserProfileModel(
          uid: credential.user!.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _selectedRole,
          createdAt: DateTime.now(),
        ),
      );

      // Send a real verification link — this is what actually confirms
      // the email is reachable, not just correctly formatted.
      await _authService.sendEmailVerification();

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.verifyEmail);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authService.friendlyError(e)), backgroundColor: AppColors.unsafe),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AppBackground(dense: true),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text('Join HIFAZAT', style: AppTextStyles.heading1),
                    const SizedBox(height: 6),
                    const Text(
                      'Start testing your water and milk for contamination.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 24),

                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('I am a...', style: AppTextStyles.heading3),
                          const SizedBox(height: 10),
                          // ADMIN IS DELIBERATELY NOT AN OPTION HERE.
                          //
                          // The previous build let anyone tick "Admin" during
                          // signup and immediately gain access to the vendor
                          // verification queue, user data, and the alert
                          // broadcast tool. That is a serious hole, not a
                          // cosmetic one: a self-declared admin could approve
                          // their own shop and push fake safety alerts to every
                          // user.
                          //
                          // Admin accounts are now created manually in the
                          // Firebase console (set role: 'admin' on the user doc)
                          // — see README_CHANGES.md. The scope document says the
                          // same: Admin is "manually seeded / invite only, never
                          // self-registered".
                          Row(
                            children: [
                              Expanded(
                                child: _RoleChip(
                                  label: 'Consumer',
                                  icon: Icons.person_rounded,
                                  selected: _selectedRole == UserRole.consumer,
                                  onTap: () => setState(
                                    () => _selectedRole = UserRole.consumer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _RoleChip(
                                  label: 'Vendor / Shop',
                                  icon: Icons.storefront_rounded,
                                  selected: _selectedRole == UserRole.vendor,
                                  onTap: () => setState(
                                    () => _selectedRole = UserRole.vendor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_selectedRole == UserRole.vendor)
                            Text(
                              'You\'ll be asked for your business details next. An '
                              'admin reviews every vendor before their trust score '
                              'goes public.',
                              style: AppTextStyles.caption,
                            ),
                          const SizedBox(height: 16),

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
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(hintText: 'Enter your email address'),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 20),

                          const Text('Password', style: AppTextStyles.heading3),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Create a strong password',
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            // Register uses the strict policy — 8+ chars, mixed
                            // case, a number. Login deliberately does NOT use
                            // this, so accounts created before this rule can
                            // still sign in.
                            validator: Validators.strongPassword,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'At least 8 characters, with an uppercase letter, a '
                            'lowercase letter, and a number.',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 20),

                          const Text('Confirm password', style: AppTextStyles.heading3),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              hintText: 'Re-enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                            validator: Validators.matches(() => _passwordController.text),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    CustomButton(label: 'Register', onPressed: _handleRegister, isLoading: _isLoading),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account?', style: AppTextStyles.bodySecondary),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Login', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
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
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : Theme.of(context).dividerColor, width: selected ? 1.6 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
