import 'package:flutter/material.dart';
import '../localization/app_strings.dart';
import '../../main.dart' show localeController;

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final isUrdu = localeController.isUrdu;
        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: AppStrings.get('nav_home', isUrdu: isUrdu),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_rounded),
              label: AppStrings.get('nav_history', isUrdu: isUrdu),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.show_chart_rounded),
              label: AppStrings.get('nav_trends', isUrdu: isUrdu),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_rounded),
              label: AppStrings.get('nav_map', isUrdu: isUrdu),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: AppStrings.get('nav_settings', isUrdu: isUrdu),
            ),
          ],
        );
      },
    );
  }
}
