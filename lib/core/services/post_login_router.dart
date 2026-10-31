import '../routes/app_routes.dart';
import 'firestore_service.dart';
import '../../models/user_role.dart';

/// Where does a freshly-authenticated user actually belong?
///
/// This exists because "logged in" is no longer a single destination. A vendor
/// who has signed up but never filled in their business details is in a broken
/// half-state: they have a vendor role but no vendor document, so their
/// dashboard would be empty and they'd never discover why. Send them to
/// registration instead of dumping them on a home screen that can't help them.
///
/// Called from both the splash screen (returning user) and the email
/// verification screen (new user), so the two paths can't drift apart.
class PostLoginRouter {
  PostLoginRouter._();

  static Future<String> resolveLandingRoute() async {
    final firestoreService = FirestoreService();

    try {
      final profile = await firestoreService.getUserProfile();
      final role = profile?.role ?? UserRole.consumer;

      if (role == UserRole.vendor) {
        final vendor = await firestoreService.getMyVendorProfile();
        if (vendor == null) return AppRoutes.vendorRegistration;
      }

      // Admins still land on Home — the admin dashboard is reachable from
      // there. Forcing them straight into the dashboard would strand them
      // away from the testing flow, which they also need for demos.
      return AppRoutes.home;
    } catch (_) {
      // Never block login on a Firestore hiccup. Worst case the user lands on
      // Home and can navigate manually.
      return AppRoutes.home;
    }
  }
}
