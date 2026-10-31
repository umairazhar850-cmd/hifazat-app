import 'package:flutter/material.dart';
import '../services/app_preferences_service.dart';

/// Global theme state. Loaded once at app start (see main.dart), and
/// updated live whenever the user toggles Dark Mode in Settings — every
/// screen listening to this rebuilds automatically via ListenableBuilder.
class ThemeController extends ChangeNotifier {
  final _prefsService = AppPreferencesService();
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadSavedPreference() async {
    final isDark = await _prefsService.getDarkMode();
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _prefsService.setDarkMode(enabled);
  }
}
