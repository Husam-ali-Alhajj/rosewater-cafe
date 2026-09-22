import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/utils/validators.dart';

/// Decision #10's phone rule, now shared by Create Account and Edit Profile.
/// These pin its exact behaviour so a future edit can't quietly change what
/// either screen accepts.
void main() {
  group('Validators.phone (decision #10)', () {
    test('accepts a number with a country code', () {
      expect(Validators.phone('+15551234567'), isNull);
      expect(Validators.phone('+966551234567'), isNull);
    });

    test('accepts formatting characters, which are stripped before checking', () {
      expect(Validators.phone('+1 (555) 123-4567'), isNull);
      expect(Validators.phone('  +966 55 123 4567  '), isNull);
    });

    test('requires a value', () {
      expect(Validators.phone(null), 'Phone number is required');
      expect(Validators.phone(''), 'Phone number is required');
      expect(Validators.phone('   '), 'Phone number is required');
    });

    test('rejects a number with no leading + (no country code)', () {
      const message = 'Include your country code, e.g. +1 or +966';
      expect(Validators.phone('5551234567'), message);
      expect(Validators.phone('(555) 123-4567'), message);
    });

    test('rejects non-digits after the +', () {
      expect(Validators.phone('+1555abc4567'), 'Enter a valid phone number');
      expect(Validators.phone('+'), 'Enter a valid phone number');
      expect(Validators.phone('+ - ()'), 'Enter a valid phone number');
    });

    test('enforces the E.164 digit range: 8 to 15 digits after the +', () {
      const message = 'Enter a valid phone number with country code';
      expect(Validators.phone('+1234567'), message); // 7 digits: one too few
      expect(Validators.phone('+12345678'), isNull); // 8 digits: the floor
      expect(Validators.phone('+123456789012345'), isNull); // 15 digits: the ceiling
      expect(Validators.phone('+1234567890123456'), message); // 16 digits: one too many
    });
  });

  /// Decision #10's password rule, now shared by Create Account and Change
  /// Password. Pinned here so a future edit can't quietly change what either
  /// accepts.
  group('Validators.password (decision #10)', () {
    test('accepts 8+ characters with an uppercase letter, a lowercase letter and a number', () {
      expect(Validators.password('Password1'), isNull);
      expect(Validators.password('aB3aaaaa'), isNull); // exactly 8: the floor
      expect(Validators.password('Correct-Horse-Battery-7'), isNull);
    });

    test('requires a value', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password(''), 'Password is required');
    });

    test('enforces the 8-character minimum exactly: 7 fails, 8 passes', () {
      expect(Validators.password('Passwo1'), 'Must be at least 8 characters');
      expect(Validators.password('Passwor1'), isNull);
    });

    test('each missing character class gets its own message', () {
      expect(Validators.password('password1'), 'Add at least one uppercase letter');
      expect(Validators.password('PASSWORD1'), 'Add at least one lowercase letter');
      expect(Validators.password('Passwordd'), 'Add at least one number');
    });

    test('checks length before the character classes', () {
      expect(Validators.password('abc'), 'Must be at least 8 characters');
    });

    test('is case-sensitive about what it needs (a lowercase-only number-less string fails on uppercase first)', () {
      expect(Validators.password('abcdefgh'), 'Add at least one uppercase letter');
    });
  });

  group('Validators.fullName', () {
    test('requires a non-blank name', () {
      expect(Validators.fullName(null), 'Full name is required');
      expect(Validators.fullName(''), 'Full name is required');
      expect(Validators.fullName('   '), 'Full name is required');
      expect(Validators.fullName('Layla Hassan'), isNull);
    });
  });
}
