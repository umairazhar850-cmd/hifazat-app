import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/vendor_model.dart';

/// Step 6 of the onboarding flow in the scope document — the vendor-only extra
/// step. Submitting this does NOT make you a verified vendor; it puts you in
/// the admin's approval queue with status `pending`.
class VendorRegistrationScreen extends StatefulWidget {
  const VendorRegistrationScreen({super.key});

  @override
  State<VendorRegistrationScreen> createState() =>
      _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _regNumberController = TextEditingController();

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  BusinessType _businessType = BusinessType.milk;
  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _regNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestoreService.saveVendorProfile(
        VendorModel(
          vendorId: uid,
          businessName: _businessNameController.text.trim(),
          businessType: _businessType,
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          registrationNumber: _regNumberController.text.trim(),
          // Always pending on submit. A vendor cannot self-verify — that is
          // the entire point of having an admin role.
          verificationStatus: VerificationStatus.pending,
          totalTests: 0,
          safeTests: 0,
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Business submitted for verification. An admin will review it shortly.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit: $e'),
          backgroundColor: AppColors.unsafe,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Business'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          const AppBackground(dense: true),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'One more step',
                      style: AppTextStyles.heading1,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Vendors are reviewed by an admin before their trust score '
                      'becomes public. This protects consumers from shops that '
                      'sign up just to look trustworthy.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 22),

                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'What do you sell?',
                            style: AppTextStyles.heading3,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: BusinessType.values.map((type) {
                              final selected = _businessType == type;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () =>
                                        setState(() => _businessType = type),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.primary.withValues(
                                                alpha: 0.1,
                                              )
                                            : Theme.of(
                                                context,
                                              ).scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.primary
                                              : Theme.of(context).dividerColor,
                                          width: selected ? 1.6 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        type.label,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.bodySecondary
                                            .copyWith(
                                              color: selected
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.normal,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 22),

                          const Text(
                            'Business name',
                            style: AppTextStyles.heading3,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _businessNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Enter your business name',
                            ),
                            validator: Validators.businessName,
                          ),
                          const SizedBox(height: 20),

                          const Text('Address', style: AppTextStyles.heading3),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your shop address',
                            ),
                            validator: (v) => Validators.required(
                              v,
                              message: 'Address is required',
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text('City', style: AppTextStyles.heading3),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cityController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Enter your city',
                            ),
                            validator: (v) =>
                                Validators.required(v, message: 'City is required'),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'CNIC / Business registration number',
                            style: AppTextStyles.heading3,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _regNumberController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 13101-1234567-1',
                            ),
                            validator: Validators.registrationNumber,
                          ),
                          const SizedBox(height: 8),
                          // Honest about what isn't built yet, rather than
                          // pretending a text field is document verification.
                          Text(
                            'Document photo upload is not enabled yet — it needs '
                            'firebase_storage. For now an admin verifies against '
                            'this number manually.',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),

                    CustomButton(
                      label: 'Submit for verification',
                      onPressed: _submit,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil(
                          AppRoutes.home,
                          (route) => false,
                        ),
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
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
