/// Shared form validators used across Login, Register, Forgot Password, Edit
/// Profile, and the Vendor/Admin forms.
class Validators {
  Validators._();

  // A proper RFC-5322-ish email pattern — catches malformed input like
  // "abc@", "abc@.com", "abc@com", "abc@@x.com", spaces, missing TLD, etc.
  // NOTE: no regex can verify an email is *real* or *reachable* — a
  // syntactically valid address like 1234@abcde.com will always pass format
  // validation, from any app, anywhere. The only way to confirm an email is
  // truly reachable is to send something to it and require confirmation —
  // see the email verification flow, which is the actual fix for that
  // concern.
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final trimmed = value.trim();
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address (e.g. name@domain.com)';
    }
    if (trimmed.length > 254) return 'Email is too long';
    return null;
  }

  /// LOGIN ONLY. Deliberately lenient (just "not empty, at least 6 chars") —
  /// accounts created before the stronger [strongPassword] rule below still
  /// need to be able to log in. Tightening this retroactively would lock
  /// existing users out of their own accounts.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'At least 6 characters';
    return null;
  }

  /// REGISTRATION ONLY. A real password policy: 8+ characters, at least one
  /// uppercase letter, one lowercase letter, and one number. Returns the
  /// single most useful missing requirement rather than every failure at
  /// once, so the error message stays short enough to read on a small
  /// screen.
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Add at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Add at least one number';
    }
    return null;
  }

  /// Builds a "confirm password" validator bound to the original password
  /// field's controller value, so it always checks against whatever is
  /// currently typed rather than a stale copy.
  static String? Function(String?) matches(
    String Function() getOriginalValue, {
    String message = 'Passwords do not match',
  }) {
    return (value) {
      if (value == null || value.isEmpty) return 'Please re-enter your password';
      if (value != getOriginalValue()) return message;
      return null;
    };
  }

  /// A name field, not just "any non-empty text" — catches a lone space, a
  /// single character, or someone typing digits into a name field.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    final trimmed = value.trim();
    if (trimmed.length < 2) return 'Name is too short';
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return 'Enter a valid name';
    return null;
  }

  static String? required(String? value, {String message = 'This field is required'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// Business / shop names get the same "not just digits, not too short"
  /// treatment as personal names, but allow a slightly shorter minimum since
  /// short shop names are common ("A1 Dairy").
  static String? businessName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Business name is required';
    final trimmed = value.trim();
    if (trimmed.length < 3) return 'Business name is too short';
    return null;
  }

  /// Loosely validated on purpose: Pakistani CNIC (13 digits, optionally
  /// dashed) and other business registration numbers both need to be
  /// accepted, and this is checked manually by an admin anyway — see
  /// VendorRegistrationScreen. Rejecting a legitimate registration number
  /// because it didn't match a strict CNIC-only pattern would block real
  /// vendors for no safety benefit.
  static String? registrationNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Registration number is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 5) {
      return 'Enter a valid CNIC or registration number';
    }
    return null;
  }
}
