import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/localization/locale_controller.dart';
import 'core/services/text_scale_controller.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_generator.dart';

final themeController = ThemeController();
final localeController = LocaleController();
final textScaleController = TextScaleController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await themeController.loadSavedPreference();
  await localeController.loadSavedPreference();
  await textScaleController.loadSavedPreference();
  runApp(const HifazatApp());
}

class HifazatApp extends StatelessWidget {
  const HifazatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeController, textScaleController]),
      builder: (context, _) {
        return MaterialApp(
          title: 'HIFAZAT',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: RouteGenerator.generateRoute,
          // This is what actually makes the Settings "Text Size" slider
          // work — it scales EVERY Text widget app-wide, not just one
          // screen, by overriding the ambient MediaQuery text scaler.
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScaleController.scale),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
