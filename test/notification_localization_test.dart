import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/models/app_notification.dart';
import 'package:rosewater_cafe/utils/notification_localization.dart';

AppNotification _notification(String type, Map<String, dynamic> data) => AppNotification.fromMap({
  'id': 'n1',
  'type': type,
  'title': 'Stored English title',
  'body': 'Stored English body',
  'is_read': false,
  'related_id': 'r1',
  'data': data,
  'created_at': '2026-09-27T10:00:00Z',
});

final _en = lookupAppLocalizations(const Locale('en'));
final _ar = lookupAppLocalizations(const Locale('ar'));

Map<String, dynamic> _event({int guests = 12, String type = 'Birthday'}) => {
  'event_type': type,
  'event_date': '2026-10-04',
  'start_time': '19:30',
  'guest_count': guests,
};

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  group('subscription_activated', () {
    final n = _notification('subscription_activated', {
      'plan_name': 'Premium',
      'valid_until': '2026-10-27T12:00:00+00:00',
    });

    test('English', () {
      final t = localizeNotification(n, _en);
      expect(t.title, 'Membership Activated');
      expect(t.body, 'Your Premium membership is now active until Oct 27, 2026.');
    });

    test('Arabic: Arabic text, plan name kept as-is', () {
      final t = localizeNotification(n, _ar);
      expect(t.title, 'تم تفعيل العضوية');
      expect(t.body, startsWith('عضويتك Premium مفعّلة الآن حتى'));
      expect(t.body, isNot(contains('Oct')));
    });
  });

  group('event_reservation_confirmed', () {
    test('English', () {
      final t = localizeNotification(_notification('event_reservation_confirmed', _event()), _en);
      expect(t.title, 'Event Reservation Confirmed');
      expect(t.body, 'Your Birthday reservation on Oct 4, 2026 at 7:30 PM for 12 guests is confirmed.');
    });

    test('Arabic: translated event type and title', () {
      final t = localizeNotification(_notification('event_reservation_confirmed', _event()), _ar);
      expect(t.title, 'تم تأكيد حجز الفعالية');
      expect(t.body, contains('(عيد ميلاد)'));
      expect(t.body, isNot(contains('Birthday')));
    });

    test('Arabic plural forms follow the guest count', () {
      String body(int n) =>
          localizeNotification(_notification('event_reservation_confirmed', _event(guests: n)), _ar).body;
      expect(body(5), contains('5 ضيوف')); // 3-10: few
      expect(body(12), contains('12 ضيفًا')); // 11-99: many
      expect(body(100), contains('100 ضيف')); // other
    });
  });

  group('falls back to the stored English text', () {
    test('unknown type', () {
      final t = localizeNotification(_notification('something_new', const {}), _ar);
      expect(t.title, 'Stored English title');
      expect(t.body, 'Stored English body');
    });

    test('missing/malformed data (e.g. a row written before the data column)', () {
      final t = localizeNotification(_notification('event_reservation_confirmed', const {}), _ar);
      expect(t.title, 'Stored English title');
      expect(t.body, 'Stored English body');
    });
  });

  group('event_reminder', () {
    test('English', () {
      final t = localizeNotification(_notification('event_reminder', _event()), _en);
      expect(t.title, 'Event Reminder');
      expect(t.body, 'Your Birthday reservation is coming up on Oct 4, 2026 at 7:30 PM for 12 guests.');
    });

    test('Arabic', () {
      final t = localizeNotification(_notification('event_reminder', _event(guests: 5)), _ar);
      expect(t.title, 'تذكير بالفعالية');
      expect(t.body, contains('(عيد ميلاد)'));
      expect(t.body, contains('5 ضيوف'));
    });
  });

  group('allowance_low', () {
    AppNotification low(String kind, int remaining) =>
        _notification('allowance_low', {'kind': kind, 'remaining': remaining, 'limit': 20});

    test('English, matching the design wording', () {
      expect(localizeNotification(low('hookah', 3), _en).title, 'Low Allowance Alert');
      expect(localizeNotification(low('hookah', 3), _en).body, 'You have only 3 hookah sessions remaining this month.');
      expect(localizeNotification(low('hookah', 1), _en).body, 'You have only 1 hookah session remaining this month.');
      expect(localizeNotification(low('drinks', 0), _en).body, 'You have used all your drinks this month.');
    });

    test('Arabic, with plural forms', () {
      expect(localizeNotification(low('hookah', 3), _ar).title, 'تنبيه انخفاض الرصيد');
      expect(localizeNotification(low('hookah', 3), _ar).body, 'تبقّت لك 3 جلسات شيشة فقط هذا الشهر.');
      expect(localizeNotification(low('drinks', 2), _ar).body, 'تبقّى لك مشروبان فقط هذا الشهر.');
      expect(localizeNotification(low('drinks', 0), _ar).body, 'لقد استخدمت جميع مشروباتك لهذا الشهر.');
    });

    test('an unknown kind falls back to the stored English text', () {
      final t = localizeNotification(low('snacks', 2), _ar);
      expect(t.title, 'Stored English title');
    });
  });

  group('subscription_upgraded', () {
    final n = _notification('subscription_upgraded', {
      'previous_plan_name': 'Basic',
      'plan_name': 'VIP',
      'valid_until': '2026-10-28T12:00:00+00:00',
    });

    test('English', () {
      final t = localizeNotification(n, _en);
      expect(t.title, 'Membership Upgraded');
      expect(t.body, "You've upgraded from Basic to VIP. Your new membership is active until Oct 28, 2026.");
    });

    test('Arabic', () {
      final t = localizeNotification(n, _ar);
      expect(t.title, 'تمت ترقية العضوية');
      expect(t.body, startsWith('تمت ترقيتك من Basic إلى VIP.'));
    });
  });
}
