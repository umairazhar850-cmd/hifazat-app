import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/post_login_router.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = AuthService();
  bool _isChecking = false;
  bool _isResending = false;
  bool _justSent = false;

  Future<void> _handleCheckVerified() async {
    setState(() => _isChecking = true);
    final verified = await _authService.reloadAndCheckVerified();
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (verified) {
      // Vendors who haven't filled in their business details go straight to
      // vendor registration rather than a home screen that can't help them.
      final route = await PostLoginRouter.resolveLandingRoute();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not verified yet — click the link in your email first.')),
      );
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    try {
      await _authService.sendEmailVerification();
      if (!mounted) return;
      setState(() => _justSent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authService.friendlyError(e)), backgroundColor: AppColors.unsafe),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? 'your email';

    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(dense: true),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.mark_email_unread_rounded, color: AppColors.primary, size: 48),
                      ),
                      const SizedBox(height: 24),
                      const Text('Verify your email', style: AppTextStyles.heading1, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      Text(
                        'We sent a verification link to $email. This confirms the address is real and reachable before you can use HIFAZAT — click the link, then come back here.',
                        style: AppTextStyles.bodySecondary,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      CustomButton(label: 'I\'ve verified — Continue', onPressed: _handleCheckVerified, isLoading: _isChecking),
                      const SizedBox(height: 12),
                      CustomButton(
                        label: _justSent ? 'Email resent ✓' : 'Resend verification email',
                        isOutlined: true,
                        onPressed: _handleResend,
                        isLoading: _isResending,
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _handleLogout,
                        child: const Text('Use a different account', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
