import 'package:flutter/material.dart';
import 'package:hifazat_app/models/sensor_reading_model.dart';
import 'app_routes.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/testing/screens/device_connect_screen.dart';
import '../../features/testing/screens/testing_progress_screen.dart';
import '../../features/testing/screens/result_screen.dart';
import '../../features/history/screens/history_detail_screen.dart';
import '../../features/assistant/screens/chat_screen.dart';
import '../../features/settings/screens/profile_screen.dart';
import '../../features/settings/screens/edit_profile_screen.dart';
import '../../features/insights/screens/insights_screen.dart';
import '../../features/help/screens/help_screen.dart';
import '../../features/vendor/screens/vendor_registration_screen.dart';
import '../../features/vendor/screens/vendor_dashboard_screen.dart';
import '../../features/vendor/screens/vendor_lookup_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/vendor_verification_screen.dart';
import '../../features/admin/screens/broadcast_alert_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../models/sample_type.dart';
import '../../models/test_flow_args.dart';
import '../../models/test_result_model.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case AppRoutes.verifyEmail:
        return MaterialPageRoute(builder: (_) => const VerifyEmailScreen());
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case AppRoutes.deviceConnect:
        final sampleType =
            settings.arguments as SampleType? ?? SampleType.water;
        return MaterialPageRoute(
          builder: (_) => DeviceConnectScreen(sampleType: sampleType),
        );

      case AppRoutes.testingProgress:
        final raw = settings.arguments;
        final args = raw is TestFlowArgs
            ? raw
            : TestFlowArgs(
                sampleType: raw is SampleType ? raw : SampleType.water,
              );
        return MaterialPageRoute(
          builder: (_) => TestingProgressScreen(args: args),
        );

      // ---- Results (Handles TestResultModel objects AND raw Maps safely) ----
      // ---- Results (Handles TestResultModel objects AND raw Maps safely) ----
      // ---- Results (Handles TestResultModel objects AND raw Maps safely) ----
      case AppRoutes.result:
      case '/results':
      case '/result':
        final rawArgs = settings.arguments;

        if (rawArgs is TestResultModel) {
          return MaterialPageRoute(
            builder: (_) => ResultScreen(result: rawArgs),
          );
        } else if (rawArgs is Map<String, dynamic>) {
          // 1. Map string severity from ML to Enum
          final severityString = rawArgs['severity']?.toString().toLowerCase();
          ResultSeverity mappedSeverity;
          if (severityString == 'unsafe') {
            mappedSeverity = ResultSeverity.unsafe;
          } else if (severityString == 'caution') {
            mappedSeverity = ResultSeverity.caution;
          } else {
            mappedSeverity = ResultSeverity.safe;
          }

          // 2. Fix 5900% Confidence Scale (converts 59.0 -> 0.59)
          final rawConf = (rawArgs['confidence'] is num)
              ? (rawArgs['confidence'] as num).toDouble()
              : 90.0;
          final conf = rawConf > 1.0 ? rawConf / 100.0 : rawConf;

          // 3. Extract Purity Percentage
          final purity = (rawArgs['purity_percent'] is num)
              ? (rawArgs['purity_percent'] as num).toDouble()
              : ((rawArgs['purity'] is num)
                    ? (rawArgs['purity'] as num).toDouble()
                    : 100.0);

          // 4. Safely parse live sensor data using fromJson
          final rawSensorMap = rawArgs['sensorData'] is Map
              ? Map<String, dynamic>.from(rawArgs['sensorData'])
              : <String, dynamic>{};

          SensorReadingModel liveReading;
          try {
            liveReading = SensorReadingModel.fromJson(rawSensorMap);
          } catch (_) {
            liveReading = SensorReadingModel.dummy();
          }

          final testResult = TestResultModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sampleType: SampleType.milk,
            severity: mappedSeverity,
            contaminant: mappedSeverity == ResultSeverity.safe
                ? null
                : 'Detected impurities based on ML',
            confidence: conf,
            reading: liveReading,
            testedAt: DateTime.now(),
            purityPercent: purity,
          );

          return MaterialPageRoute(
            builder: (_) => ResultScreen(result: testResult),
          );
        }

        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('No test result data available to display.'),
            ),
          ),
        );

      case AppRoutes.historyDetail:
        final result = settings.arguments as TestResultModel?;
        if (result != null) {
          return MaterialPageRoute(
            builder: (_) => HistoryDetailScreen(result: result),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('History detail data missing.')),
          ),
        );

      case AppRoutes.chat:
        final result = settings.arguments as TestResultModel?;
        return MaterialPageRoute(builder: (_) => ChatScreen(context_: result));

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case AppRoutes.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case AppRoutes.insights:
        return MaterialPageRoute(builder: (_) => const InsightsScreen());

      case AppRoutes.help:
        return MaterialPageRoute(builder: (_) => const HelpScreen());

      // ---- Vendor ----
      case AppRoutes.vendorRegistration:
        return MaterialPageRoute(
          builder: (_) => const VendorRegistrationScreen(),
        );

      case AppRoutes.vendorDashboard:
        return MaterialPageRoute(builder: (_) => const VendorDashboardScreen());

      case AppRoutes.vendorLookup:
        return MaterialPageRoute(builder: (_) => const VendorLookupScreen());

      // ---- Admin ----
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case AppRoutes.vendorVerification:
        return MaterialPageRoute(
          builder: (_) => const VendorVerificationScreen(),
        );

      case AppRoutes.broadcastAlert:
        return MaterialPageRoute(builder: (_) => const BroadcastAlertScreen());

      case AppRoutes.userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
