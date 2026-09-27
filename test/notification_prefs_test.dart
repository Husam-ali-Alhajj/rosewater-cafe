import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/notification_prefs.dart';

void main() {
  group('NotificationSettings.fromRow', () {
    test('no row yet (never changed anything) shows the design defaults: SMS off, everything else on', () {
      final settings = NotificationSettings.fromRow(null);

      expect(settings.isOn(NotificationSetting.push), isTrue);
      expect(settings.isOn(NotificationSetting.email), isTrue);
      expect(settings.isOn(NotificationSetting.sms), isFalse);
      expect(settings.isOn(NotificationSetting.sound), isTrue);
      expect(settings.isOn(NotificationSetting.eventReminders), isTrue);
      expect(settings.isOn(NotificationSetting.allowanceAlerts), isTrue);
      expect(settings.isOn(NotificationSetting.promotions), isTrue);
    });

    test('reads each toggle from its own column', () {
      final settings = NotificationSettings.fromRow({
        'user_id': 'u1',
        'push': false,
        'email': true,
        'sms': true,
        'sound': false,
        'event_reminders': false,
        'allowance_alerts': true,
        'promotions': false,
      });

      expect(settings.isOn(NotificationSetting.push), isFalse);
      expect(settings.isOn(NotificationSetting.email), isTrue);
      expect(settings.isOn(NotificationSetting.sms), isTrue);
      expect(settings.isOn(NotificationSetting.sound), isFalse);
      expect(settings.isOn(NotificationSetting.eventReminders), isFalse);
      expect(settings.isOn(NotificationSetting.allowanceAlerts), isTrue);
      expect(settings.isOn(NotificationSetting.promotions), isFalse);
    });

    test('a missing or null column falls back to that toggle default', () {
      final settings = NotificationSettings.fromRow({'push': false, 'sms': null});

      expect(settings.isOn(NotificationSetting.push), isFalse);
      expect(settings.isOn(NotificationSetting.sms), isFalse);
      expect(settings.isOn(NotificationSetting.email), isTrue);
    });
  });

  test("the app's defaults match the database column defaults exactly", () {
    // A user with no row (app defaults) and a freshly inserted row (column
    // defaults) must mean the same thing -- otherwise the first toggle flip
    // would silently change the other six.
    final sql = File('supabase/migrations/20260930100000_notification_preferences.sql').readAsStringSync();
    for (final s in NotificationSetting.values) {
      final match = RegExp(r'^\s+' + s.column + r'\s+boolean not null default (true|false),', multiLine: true).firstMatch(sql);
      expect(match, isNotNull, reason: 'column ${s.column} not found in the migration');
      expect(match!.group(1), '${s.defaultValue}', reason: s.column);
    }
  });
}
