import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for small local settings that
/// don't need Firestore (theme, language, notification toggle, text
/// scale). These are per-device, not per-user account.
class AppPreferencesService {
  static const _keyDarkMode = 'dark_mode_enabled';
  static const _keyUrdu = 'urdu_enabled';
  static const _keyNotifications = 'notifications_enabled';
  static const _keyTextScale = 'text_scale_factor';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<bool> getUrdu() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUrdu) ?? false;
  }

  Future<void> setUrdu(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUrdu, value);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  Future<double> getTextScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTextScale) ?? 1.0;
  }

  Future<void> setTextScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextScale, value);
  }
}
