import 'package:flutter/material.dart';
import '../services/app_preferences_service.dart';

/// Global text-scale state. This is what makes the Settings "Text Size"
/// slider actually do something — previously it only updated its own
/// local widget state with no effect anywhere else in the app. Now it's
/// applied app-wide via a MediaQuery override in main.dart, and persists
/// across restarts.
class TextScaleController extends ChangeNotifier {
  final _prefsService = AppPreferencesService();
  double _scale = 1.0;

  double get scale => _scale;

  Future<void> loadSavedPreference() async {
    _scale = await _prefsService.getTextScale();
    notifyListeners();
  }

  Future<void> setScale(double value) async {
    _scale = value;
    notifyListeners();
    await _prefsService.setTextScale(value);
  }
}
