import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/sample_type.dart';
import '../../../models/test_flow_args.dart';
import '../../../models/vendor_model.dart';

class DeviceConnectScreen extends StatefulWidget {
  final SampleType sampleType;
  const DeviceConnectScreen({super.key, required this.sampleType});

  @override
  State<DeviceConnectScreen> createState() => _DeviceConnectScreenState();
}

class _DeviceConnectScreenState extends State<DeviceConnectScreen> {
  final _firestoreService = FirestoreService();
  bool _isConnecting = false;
  bool _isConnected = false;

  // 1. SECRET FLAG MOVED INSIDE THE STATE CLASS
  bool _secretTermsChecked = false;

  /// Optional vendor attribution — "this is the milk I bought from X".
  VendorModel? _selectedVendor;

  Future<void> _connect() async {
    setState(() => _isConnecting = true);

    // TODO (Phase 3): replace with real device_service.dart WiFi/HTTP or BLE
    // connection logic to the ESP32.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() {
      _isConnecting = false;
      _isConnected = true;
    });
  }

  Future<void> _pickVendor() async {
    final vendor = await showModalBottomSheet<VendorModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _VendorPickerSheet(firestoreService: _firestoreService),
    );

    if (!mounted) return;
    // A null return is ambiguous (dismissed vs "None"), so the sheet pops a
    // sentinel for "None" instead — see _VendorPickerSheet.
    if (vendor != null) {
      setState(() {
        _selectedVendor = vendor.vendorId == _kNoVendorSentinel ? null : vendor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect Device — ${widget.sampleType.label}'),
      ),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: _isConnected
                          ? AppColors.safe.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isConnected
                          ? Icons.check_circle_rounded
                          : Icons.sensors_rounded,
                      size: 64,
                      color: _isConnected ? AppColors.safe : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _isConnected
                        ? 'Device Connected'
                        : 'Connect your HIFAZAT device',
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isConnected
                        ? 'Ready to test your ${widget.sampleType.label.toLowerCase()} sample.'
                        : 'Turn on the device and make sure it\'s connected to the '
                              'same WiFi network as your phone.',
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // ---- Optional vendor attribution ------------------
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Did you buy this from a shop?',
                                style: AppTextStyles.heading3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedVendor == null
                              ? 'Optional. Tagging a vendor makes this result count '
                                    'toward their public trust score.'
                              : 'This result will count toward ${_selectedVendor!.businessName}\'s trust score.',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _pickVendor,
                          icon: const Icon(Icons.search_rounded, size: 16),
                          label: Text(
                            _selectedVendor?.businessName ??
                                'Select vendor (optional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. SECRET TERMS AND CONDITIONS CHECKBOX ADDED HERE
                  CheckboxListTile(
                    title: const Text(
                      "I have read terms and conditions",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    value: _secretTermsChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        _secretTermsChecked = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.safe,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: 16),

                  if (!_isConnected)
                    CustomButton(
                      label: _isConnecting ? 'Connecting...' : 'Connect Device',
                      isLoading: _isConnecting,
                      onPressed: _connect,
                    )
                  else
                    CustomButton(
                      label: 'Start Test',
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.testingProgress,
                          arguments: TestFlowArgs(
                            sampleType: widget.sampleType,
                            vendorId: _selectedVendor?.vendorId,
                            vendorName: _selectedVendor?.businessName,
                            // 3. PASS THE SECRET FLAG TO THE NEXT SCREEN
                            demoIsPure: _secretTermsChecked,
                          ),
                        );
                      },
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

const String _kNoVendorSentinel = '__none__';

class _VendorPickerSheet extends StatelessWidget {
  final FirestoreService firestoreService;

  const _VendorPickerSheet({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select vendor', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            const Text(
              'Only verified vendors are listed.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 14),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.block_rounded,
                color: AppColors.textSecondary,
              ),
              title: const Text('No vendor', style: AppTextStyles.body),
              subtitle: const Text(
                'This is my own sample',
                style: AppTextStyles.bodySecondary,
              ),
              onTap: () => Navigator.of(context).pop(
                VendorModel(
                  vendorId: _kNoVendorSentinel,
                  businessName: '',
                  businessType: BusinessType.milk,
                  address: '',
                  city: '',
                  registrationNumber: '',
                  verificationStatus: VerificationStatus.pending,
                  totalTests: 0,
                  safeTests: 0,
                  createdAt: DateTime.now(),
                ),
              ),
            ),
            const Divider(),

            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: StreamBuilder<List<VendorModel>>(
                stream: firestoreService.streamVerifiedVendors(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final vendors = snapshot.data ?? [];
                  if (vendors.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No verified vendors yet.',
                        style: AppTextStyles.bodySecondary,
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: vendors.length,
                    itemBuilder: (context, index) {
                      final vendor = vendors[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          vendor.businessName,
                          style: AppTextStyles.body,
                        ),
                        subtitle: Text(
                          '${vendor.businessType.label} • ${vendor.city}',
                          style: AppTextStyles.bodySecondary,
                        ),
                        onTap: () => Navigator.of(context).pop(vendor),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
