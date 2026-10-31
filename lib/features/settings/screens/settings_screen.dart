import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/app_preferences_service.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../main.dart'
    show themeController, localeController, textScaleController;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _prefsService = AppPreferencesService();
  bool _notifications = true;
  bool _loggingOut = false;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final notif = await _prefsService.getNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notifications = notif;
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _handleNotificationsToggle(bool value) async {
    setState(() => _notifications = value);
    await _prefsService.setNotificationsEnabled(value);

    if (value) {
      try {
        final settings = await FirebaseMessaging.instance.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.denied &&
            mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notifications blocked in phone settings — enable them there to receive hotspot alerts.',
              ),
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _loggingOut = true);
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  String _textSizeLabel(double value) {
    if (value <= 0.9) return 'Small';
    if (value <= 1.05) return 'Normal';
    if (value <= 1.2) return 'Large';
    return 'Extra Large';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        themeController,
        localeController,
        textScaleController,
      ]),
      builder: (context, _) {
        final isUrdu = localeController.isUrdu;
        final textScale = textScaleController.scale;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.get('settings_title', isUrdu: isUrdu),
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: 20),
              _sectionCard([
                _tile(
                  icon: Icons.person_outline_rounded,
                  title: AppStrings.get('settings_profile', isUrdu: isUrdu),
                  subtitle: 'View and edit your account',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.profile),
                ),
                _tile(
                  icon: Icons.help_outline_rounded,
                  title: AppStrings.get('settings_help', isUrdu: isUrdu),
                  subtitle: 'Sensor Flush protocol, testing guide, FAQ',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.help),
                ),
              ]),
              const SizedBox(height: 16),
              _sectionCard([
                SwitchListTile(
                  value: _notifications,
                  onChanged: _loadingPrefs ? null : _handleNotificationsToggle,
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    AppStrings.get('settings_notifications', isUrdu: isUrdu),
                    style: AppTextStyles.body,
                  ),
                  subtitle: const Text(
                    'Alert me when near an unsafe area',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
                SwitchListTile(
                  value: themeController.isDarkMode,
                  onChanged: (v) => themeController.setDarkMode(v),
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    AppStrings.get('settings_dark_mode', isUrdu: isUrdu),
                    style: AppTextStyles.body,
                  ),
                  subtitle: const Text(
                    'Switches the whole app theme',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
                SwitchListTile(
                  value: isUrdu,
                  onChanged: (v) => localeController.setUrdu(v),
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    AppStrings.get('settings_urdu', isUrdu: isUrdu),
                    style: AppTextStyles.body,
                  ),
                  subtitle: const Text(
                    'Switches Home, nav bar & settings labels',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _sectionCard([
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.get(
                              'settings_text_size',
                              isUrdu: isUrdu,
                            ),
                            style: AppTextStyles.body,
                          ),
                          Text(
                            _textSizeLabel(textScale),
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                      Slider(
                        value: textScale,
                        min: 0.85,
                        max: 1.3,
                        divisions: 3,
                        activeColor: AppColors.primary,
                        label: _textSizeLabel(textScale),
                        // This now actually changes text size app-wide —
                        // wired to the global TextScaleController, which
                        // main.dart applies via a MediaQuery override, and
                        // persists across restarts via SharedPreferences.
                        onChanged: (v) => textScaleController.setScale(v),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _sectionCard([
                _tile(
                  icon: Icons.logout_rounded,
                  title: _loggingOut
                      ? 'Logging out...'
                      : AppStrings.get('settings_logout', isUrdu: isUrdu),
                  subtitle: null,
                  danger: true,
                  onTap: _loggingOut ? () {} : _handleLogout,
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: danger ? AppColors.unsafe : AppColors.primary),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          color: danger
              ? AppColors.unsafe
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTextStyles.bodySecondary)
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
