import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Thin wrapper around FirebaseAuth so screens never call Firebase directly.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    await credential.user?.reload();
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ---- Email verification --------------------------------------------
  // This is the real safeguard against fake/unreachable email addresses:
  // format validation alone can never confirm an inbox exists, only
  // actually sending a link and requiring confirmation can.

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Re-fetches the user from Firebase so `isEmailVerified` reflects
  /// whether they've clicked the link yet.
  Future<bool> reloadAndCheckVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak — use at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'Network error — check your internet connection.';
        // FLAW FIX: these codes previously fell through to the generic
        // message below, which either showed nothing useful or, worse, an
        // internal Firebase error string the user can't act on.
        case 'too-many-requests':
          return 'Too many attempts. Please wait a few minutes and try again.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support if you '
              'believe this is a mistake.';
        case 'requires-recent-login':
          return 'This action needs a fresh login — please sign out and back '
              'in, then try again.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled. Contact support.';
        case 'user-token-expired':
          return 'Your session has expired — please log in again.';
        default:
          debugPrint(
            'Unhandled FirebaseAuthException [${error.code}]: ${error.message}',
          );
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }

    // FLAW FIX: registration (and other flows) also hit Cloud Firestore
    // (saveUserProfile, etc.), which throws a FirebaseException — a
    // different type from FirebaseAuthException entirely. There was no
    // branch for this, so a Firestore permission-denied error (rules not
    // published, database not created yet, etc.) silently fell through to
    // the generic "Something went wrong" message below, hiding the real
    // cause from both the user and from debugging.
    if (error is FirebaseException) {
      debugPrint(
        'FirebaseException [${error.plugin}/${error.code}]: ${error.message}',
      );
      switch (error.code) {
        case 'permission-denied':
          return 'Your account was created, but saving your profile was blocked '
              'by a permissions rule. Please contact support.';
        case 'unavailable':
          return 'Could not reach the server. Check your internet connection '
              'and try again.';
        case 'not-found':
          return 'The database could not be found. Please contact support.';
        default:
          return error.message ??
              'Something went wrong while saving your data.';
      }
    }

    // Anything else (a plain Dart exception, a null-check failure, etc.) —
    // log it so it is at least visible in the debug console rather than
    // vanishing into an unhelpful generic message.
    debugPrint('Unhandled error in AuthService: $error');
    return 'Something went wrong. Please try again.';
  }
}
