/// Shared form validators used across auth screens, so the rules (and any
/// future fix to them) live in exactly one place.
class Validators {
  Validators._();

  // Standard HTML5-spec email pattern — stricter than a bare "has an @"
  // check: validates the local part, requires a properly-formed domain
  // with at least one dot, and rejects malformed domains a looser regex
  // would let through.
  static final _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
    r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  /// Decision #10's password rule, shared by Create Account and Change
  /// Password so the two can never disagree about what a strong-enough
  /// password is (moved here unchanged from Create Account): 8+ characters
  /// with at least one uppercase letter, one lowercase letter and one number,
  /// each missing requirement getting its own message.
  ///
  /// Client-side only -- the real enforcement is Supabase's own Auth password
  /// policy (see decision #10).
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Add at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add at least one number';
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    return null;
  }

  /// Decision #10's phone rule, shared by Create Account and Edit Profile so
  /// the two can never disagree about what a valid number is (moved here
  /// unchanged from Create Account).
  ///
  /// Requires a leading `+` and country code, and E.164's digit range.
  /// Formatting characters (spaces, dashes, parentheses) are allowed and
  /// stripped before checking.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Strip formatting characters a real number might legitimately contain
    // (spaces, dashes, parentheses) but keep the leading "+" meaningful —
    // a phone number with no country code is ambiguous (is "5551234" a
    // local number, or missing "+1"?) and won't work with any downstream
    // SMS/calling integration, so we require it explicitly.
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (!cleaned.startsWith('+')) {
      return 'Include your country code, e.g. +1 or +966';
    }
    final digits = cleaned.substring(1);
    if (digits.isEmpty || !RegExp(r'^\d+$').hasMatch(digits)) {
      return 'Enter a valid phone number';
    }
    // E.164 (the international phone number standard) allows at most 15
    // digits total; 8 is a reasonable floor for country code + a real
    // subscriber number.
    if (digits.length < 8 || digits.length > 15) {
      return 'Enter a valid phone number with country code';
    }
    return null;
  }
}
