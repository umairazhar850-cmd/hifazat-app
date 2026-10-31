import 'package:flutter/material.dart';
import '../services/app_preferences_service.dart';

/// Lightweight custom locale toggle (not full flutter_localizations/ARB
/// setup — that's a bigger addition). This drives AppStrings so a real,
/// working language switch exists now for the key screens listed there;
/// expanding AppStrings' maps is how you'd extend it to more screens later.
class LocaleController extends ChangeNotifier {
  final _prefsService = AppPreferencesService();
  bool _isUrdu = false;

  bool get isUrdu => _isUrdu;

  Future<void> loadSavedPreference() async {
    _isUrdu = await _prefsService.getUrdu();
    notifyListeners();
  }

  Future<void> setUrdu(bool enabled) async {
    _isUrdu = enabled;
    notifyListeners();
    await _prefsService.setUrdu(enabled);
  }
}
