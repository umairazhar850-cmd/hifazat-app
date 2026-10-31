class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String home = '/home';

  // Testing sub-flow
  static const String deviceConnect = '/testing/connect';
  static const String testingProgress = '/testing/progress';
  static const String result = '/testing/result';

  // Other feature screens
  static const String historyDetail = '/history/detail';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String insights = '/insights';
  static const String help = '/help';

  // Vendor
  static const String vendorRegistration = '/vendor/register';
  static const String vendorDashboard = '/vendor/dashboard';
  static const String vendorLookup = '/vendor/lookup';

  // Admin / Authority
  static const String adminDashboard = '/admin';
  static const String vendorVerification = '/admin/verification';
  static const String broadcastAlert = '/admin/broadcast';
  static const String userManagement = '/admin/users';
}
