import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();

      // Check our own Firestore users collection first — Firebase Auth's
      // sendPasswordResetEmail won't reliably tell us if the email exists
      // (email enumeration protection makes it succeed silently either
      // way), so we check the real source of truth ourselves.
      final exists = await _firestoreService.checkEmailExists(email);
      if (!exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No HIFAZAT account found with this email.'),
            backgroundColor: AppColors.unsafe,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() => _emailSent = true);
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
      appBar: AppBar(title: const Text('Reset Password'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AppBackground(dense: true),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: SingleChildScrollView(
                  child: _emailSent ? _buildSuccessState() : _buildFormState(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 24),
          const Text('Forgot your password?', style: AppTextStyles.heading1),
          const SizedBox(height: 8),
          const Text(
            'Enter the email you registered with — we\'ll check it exists, then send a reset link.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 28),
          GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Email', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Enter your registered email'),
                  validator: Validators.email,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(label: 'Check & Send Reset Link', onPressed: _handleSend, isLoading: _isLoading),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.safe.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_rounded, color: AppColors.safe, size: 48),
        ),
        const SizedBox(height: 24),
        const Text('Check your email', style: AppTextStyles.heading2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'We confirmed this account exists and sent a password reset link to ${_emailController.text.trim()}. Follow the link, then come back and log in.',
          style: AppTextStyles.bodySecondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        CustomButton(label: 'Back to Login', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
