import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../../models/test_result_model.dart';
import '../../models/user_profile_model.dart';
import '../../models/user_role.dart';
import '../../models/vendor_model.dart';
import '../../models/alert_model.dart';
import '../../models/community_stats_model.dart';

/// All Firestore reads/writes go through here — screens never call
/// FirebaseFirestore directly.
///
/// Data shape:
///   users/{uid}                  -> UserProfileModel (name, email, role)
///   users/{uid}/tests/{testId}   -> one TestResultModel per document
///   vendors/{uid}                -> VendorModel (business, verification, trust)
///   alerts/{alertId}             -> AlertModel (admin area broadcasts)
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String? get _uid => _authService.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _testsCollection {
    final uid = _uid;
    if (uid == null) {
      throw Exception('No logged-in user — cannot access tests collection.');
    }
    return _db.collection('users').doc(uid).collection('tests');
  }

  CollectionReference<Map<String, dynamic>> get _vendorsCollection =>
      _db.collection('vendors');

  CollectionReference<Map<String, dynamic>> get _alertsCollection =>
      _db.collection('alerts');

  // ---- Test results ----------------------------------------------------

  /// Saves the test, and — if the consumer tagged it to a vendor — atomically
  /// updates that vendor's aggregate counters in the same batch.
  ///
  /// The 80% confidence rule is enforced here too, not just in the UI: an
  /// INCONCLUSIVE result must never move a vendor's trust score. Letting a
  /// coin-flip reading nudge a real business's public rating would be worse
  /// than having no rating at all.
  Future<void> saveTestResult(TestResultModel result) async {
    final batch = _db.batch();

    batch.set(_testsCollection.doc(result.id), result.toMap());

    final vendorId = result.vendorId;
    if (vendorId != null && result.countsTowardStats) {
      // set(merge) rather than update(): if the vendor document were missing
      // for any reason, update() throws and the ENTIRE batch rolls back — the
      // user's test result would silently vanish because of a bookkeeping
      // problem on someone else's document. Merging can't fail that way.
      batch.set(_vendorsCollection.doc(vendorId), {
        'totalTests': FieldValue.increment(1),
        if (result.severity == ResultSeverity.safe)
          'safeTests': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Stream<List<TestResultModel>> streamTestHistory() {
    return _testsCollection
        .orderBy('testedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TestResultModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<int> getTestCount() async {
    final snapshot = await _testsCollection.count().get();
    return snapshot.count ?? 0;
  }

  /// Every test tagged to a given vendor, across ALL users. This is what the
  /// vendor sees on their own dashboard.
  ///
  /// Requires a collectionGroup index on `tests` for the `vendorId` field —
  /// Firestore prints a one-click link to create it the first time this runs.
  Stream<List<TestResultModel>> streamTestsForVendor(String vendorId) {
    return _db
        .collectionGroup('tests')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
          final tests = snapshot.docs
              .map((doc) => TestResultModel.fromMap(doc.id, doc.data()))
              .toList();
          // Sorted client-side to avoid needing a second composite index just
          // for ordering — the per-vendor result set is small.
          tests.sort((a, b) => b.testedAt.compareTo(a.testedAt));
          return tests;
        });
  }

  // ---- User profile ----------------------------------------------------

  Future<void> saveUserProfile(UserProfileModel profile) async {
    await _db
        .collection('users')
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfileModel?> getUserProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfileModel.fromMap(uid, doc.data()!);
  }

  Future<UserRole> getCurrentUserRole() async {
    final profile = await getUserProfile();
    return profile?.role ?? UserRole.consumer;
  }

  /// Checks our own `users` collection for a matching email, rather than
  /// relying on Firebase Auth's password-reset call to reveal this — modern
  /// Firebase projects have "email enumeration protection" on by default,
  /// which makes sendPasswordResetEmail succeed silently even for emails that
  /// don't exist. Checking Firestore directly gives an honest answer.
  Future<bool> checkEmailExists(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // ---- Vendors ---------------------------------------------------------

  Future<void> saveVendorProfile(VendorModel vendor) async {
    await _vendorsCollection
        .doc(vendor.vendorId)
        .set(vendor.toMap(), SetOptions(merge: true));
  }

  Future<VendorModel?> getVendor(String vendorId) async {
    final doc = await _vendorsCollection.doc(vendorId).get();
    if (!doc.exists) return null;
    return VendorModel.fromMap(doc.id, doc.data()!);
  }

  /// The signed-in vendor's own business record. Null if they haven't filled
  /// in the vendor registration form yet.
  Future<VendorModel?> getMyVendorProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    return getVendor(uid);
  }

  Stream<VendorModel?> streamMyVendorProfile() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _vendorsCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return VendorModel.fromMap(doc.id, doc.data()!);
    });
  }

  /// Admin: the verification queue.
  Stream<List<VendorModel>> streamPendingVendors() {
    return _vendorsCollection
        .where('verificationStatus', isEqualTo: VerificationStatus.pending.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VendorModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Consumer-facing vendor lookup. Only VERIFIED vendors are ever listed —
  /// an unverified business must not be able to present itself as trusted
  /// simply by signing up.
  Stream<List<VendorModel>> streamVerifiedVendors() {
    return _vendorsCollection
        .where(
          'verificationStatus',
          isEqualTo: VerificationStatus.verified.name,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VendorModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> setVendorVerification({
    required String vendorId,
    required VerificationStatus status,
    String? rejectionReason,
  }) async {
    await _vendorsCollection.doc(vendorId).update({
      'verificationStatus': status.name,
      'rejectionReason': rejectionReason,
      'verifiedAt': Timestamp.fromDate(DateTime.now()),
      'verifiedBy': _uid,
    });
  }

  // ---- Alerts (admin broadcast) ---------------------------------------

  Future<void> createAlert(AlertModel alert) async {
    await _alertsCollection.doc(alert.id).set(alert.toMap());
  }

  Stream<List<AlertModel>> streamActiveAlerts() {
    return _alertsCollection.where('active', isEqualTo: true).snapshots().map((
      snapshot,
    ) {
      final alerts = snapshot.docs
          .map((doc) => AlertModel.fromMap(doc.id, doc.data()))
          .toList();
      alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return alerts;
    });
  }

  Future<void> deactivateAlert(String alertId) async {
    await _alertsCollection.doc(alertId).update({'active': false});
  }

  // ---- Community-wide aggregate stats (Insights + admin export) ---------

  /// Reads the `tests` subcollection across EVERY user via a collectionGroup
  /// query — this is what makes Insights genuinely community-wide rather than
  /// just "my own history", and it's the data source behind the
  /// regulatory/health/NGO stakeholder story.
  ///
  /// Inconclusive tests are EXCLUDED from every count. A reading the model
  /// wasn't confident about is missing information, not a data point — folding
  /// it into public health statistics would quietly corrupt them.
  Stream<CommunityStatsModel> streamCommunityStats() {
    return _db.collectionGroup('tests').snapshots().map((snapshot) {
      int safe = 0, caution = 0, unsafe = 0, inconclusive = 0;
      final contaminantFreq = <String, int>{};
      final sampleTypeFreq = <String, int>{};
      double puritySum = 0;
      int purityCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final isInconclusive = data['isInconclusive'] as bool? ?? false;
        if (isInconclusive) {
          inconclusive++;
          continue; // excluded from all other aggregates, deliberately
        }

        final severity = data['severity'] as String?;
        switch (severity) {
          case 'safe':
            safe++;
            break;
          case 'caution':
            caution++;
            break;
          case 'unsafe':
            unsafe++;
            break;
        }

        final contaminant = data['contaminant'] as String?;
        if (contaminant != null &&
            contaminant.isNotEmpty &&
            contaminant.toLowerCase() != 'none detected') {
          contaminantFreq[contaminant] = (contaminantFreq[contaminant] ?? 0) + 1;
        }

        final sampleTypeRaw = data['sampleType'] as String?;
        final sampleTypeLabel = switch (sampleTypeRaw) {
          'water' => 'Water',
          'milk' => 'Milk',
          _ => null,
        };
        if (sampleTypeLabel != null) {
          sampleTypeFreq[sampleTypeLabel] =
              (sampleTypeFreq[sampleTypeLabel] ?? 0) + 1;
        }

        final purity = (data['purityPercent'] as num?)?.toDouble();
        if (purity != null) {
          puritySum += purity;
          purityCount++;
        }
      }

      return CommunityStatsModel(
        totalTests: safe + caution + unsafe,
        safeCount: safe,
        cautionCount: caution,
        unsafeCount: unsafe,
        inconclusiveCount: inconclusive,
        averageMilkPurity: purityCount == 0 ? null : puritySum / purityCount,
        contaminantFrequency: contaminantFreq,
        sampleTypeFrequency: sampleTypeFreq,
      );
    });
  }

  // ---- User management (admin promotes/demotes users) ------------------
  //
  // No user can ever set their own role to admin — see the Firestore rule on
  // `users/{uid}`, which only allows `create`/self-`update` when role is
  // 'consumer' or 'vendor'. This is the ONLY path that can produce an admin
  // account after the very first one, and it requires an EXISTING admin to
  // do it, which is what makes it safe to expose in the UI at all.

  Stream<List<UserProfileModel>> streamAllUsers() {
    return _db.collection('users').orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => UserProfileModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> setUserRole({required String uid, required UserRole role}) async {
    await _db.collection('users').doc(uid).update({'role': role.name});
  }

  /// How many admins currently exist. Used to block demoting the LAST admin
  /// — doing that would lock everyone out of the admin dashboard with no way
  /// back in except a manual Firebase console edit, which defeats the whole
  /// point of building the in-app promotion flow.
  Future<int> countAdmins() async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: UserRole.admin.name)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
