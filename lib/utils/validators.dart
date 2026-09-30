/// Form validators shared by several screens, so each rule lives in one place.
class Validators {
  Validators._();

  // Standard email format check.
  static final _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
    r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  /// Password rule, shared by sign-up and Change Password: at least 8 characters with an uppercase
  /// letter, a lowercase letter and a number. Supabase enforces its own rule on the server too.
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

  /// Phone rule, shared by sign-up and Edit Profile: must start with + and a country code. Spaces,
  /// dashes and brackets are allowed.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove spaces, dashes and brackets, but require the + so the number has a country code.
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (!cleaned.startsWith('+')) {
      return 'Include your country code, e.g. +1 or +966';
    }
    final digits = cleaned.substring(1);
    if (digits.isEmpty || !RegExp(r'^\d+$').hasMatch(digits)) {
      return 'Enter a valid phone number';
    }
    // International numbers have at most 15 digits; 8 is a sensible minimum.
    if (digits.length < 8 || digits.length > 15) {
      return 'Enter a valid phone number with country code';
    }
    return null;
  }
}
