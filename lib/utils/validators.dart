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
}
