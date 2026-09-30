import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/models/app_notification.dart';
import 'package:rosewater_cafe/screens/events/reservation_details_screen.dart';
import 'package:rosewater_cafe/screens/notifications/notifications_screen.dart';
import 'package:rosewater_cafe/services/notification_service.dart';
import 'package:rosewater_cafe/utils/relative_time.dart';

final _now = DateTime(2026, 9, 27, 12);

AppNotification _payment({String id = 'pay', bool read = false, Duration age = const Duration(hours: 2)}) =>
    AppNotification(
      id: id,
      type: 'subscription_activated',
      title: 'Membership Activated',
      body: 'Your Premium membership is now active until Oct 27, 2026.',
      isRead: read,
      relatedId: 'sub-1',
      data: const {'plan_name': 'Premium', 'valid_until': '2026-10-27T12:00:00+00:00'},
      createdAt: _now.subtract(age),
    );

AppNotification _event({String id = 'ev', bool read = true, Duration age = const Duration(days: 1)}) => AppNotification(
  id: id,
  type: 'event_reservation_confirmed',
  title: 'Event Reservation Confirmed',
  body: 'Your Birthday reservation ...',
  isRead: read,
  relatedId: 'res-1',
  data: const {'event_type': 'Birthday', 'event_date': '2026-10-04', 'start_time': '19:30', 'guest_count': 12},
  createdAt: _now.subtract(age),
);

/// Stands in for the database; records what the screen asked it to do.
class _FakeService extends NotificationService {
  final List<AppNotification> rows;
  final bool failLoad;
  final bool failWrites;
  final List<String> calls = [];

  _FakeService(this.rows, {this.failLoad = false, this.failWrites = false});

  @override
  Future<List<AppNotification>> fetchAll() async {
    if (failLoad) throw StateError('offline');
    return rows;
  }

  @override
  Future<void> markRead(String id) async {
    calls.add('read:$id');
    if (failWrites) throw StateError('offline');
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete:$id');
    if (failWrites) throw StateError('offline');
  }
}

Future<List<String>> _pump(WidgetTester tester, _FakeService service, {String locale = 'en'}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final nav = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    NotificationsScreen(service: service, now: _now, onViewMembership: () => nav.add('membership')),
              ),
            ),
            child: const Text('home'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('home'));
  await tester.pumpAndSettle();
  return nav;
}

Finder _card(String id) => find.byKey(ValueKey('notification-$id'));
Finder _inCard(String id, Finder f) => find.descendant(of: _card(id), matching: f);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  testWidgets('lists real notifications newest first, in the user language, with the unread count', (tester) async {
    await _pump(tester, _FakeService([_payment(), _event()]));

    expect(find.text('1 unread notification'), findsOneWidget);
    expect(find.text('Membership Activated'), findsOneWidget);
    expect(find.text('Your Premium membership is now active until Oct 27, 2026.'), findsOneWidget);
    expect(find.text('Event Reservation Confirmed'), findsOneWidget);
    expect(find.text('2h ago'), findsOneWidget);
    expect(find.text('1d ago'), findsOneWidget);
    expect(tester.getTopLeft(_card('pay')).dy, lessThan(tester.getTopLeft(_card('ev')).dy));
  });

  testWidgets('only unread cards have the dot and Mark as Read', (tester) async {
    await _pump(tester, _FakeService([_payment(read: false), _event(read: true)]));

    expect(_inCard('pay', find.byKey(const ValueKey('unread-dot'))), findsOneWidget);
    expect(_inCard('pay', find.text('Mark as Read')), findsOneWidget);
    expect(_inCard('ev', find.byKey(const ValueKey('unread-dot'))), findsNothing);
    expect(_inCard('ev', find.text('Mark as Read')), findsNothing);
  });

  testWidgets('Mark as Read saves and updates the card and the count', (tester) async {
    final service = _FakeService([_payment()]);
    await _pump(tester, service);

    await tester.tap(_inCard('pay', find.text('Mark as Read')));
    await tester.pumpAndSettle();

    expect(service.calls, ['read:pay']);
    expect(find.text('No unread notifications'), findsOneWidget);
    expect(_inCard('pay', find.text('Mark as Read')), findsNothing);
  });

  testWidgets('delete removes the card and saves', (tester) async {
    final service = _FakeService([_payment(), _event()]);
    await _pump(tester, service);

    await tester.tap(_inCard('ev', find.byTooltip('Delete')));
    await tester.pumpAndSettle();

    expect(service.calls, ['delete:ev']);
    expect(_card('ev'), findsNothing);
    expect(_card('pay'), findsOneWidget);
  });

  testWidgets('a failed save puts the card back and says so', (tester) async {
    final service = _FakeService([_payment()], failWrites: true);
    await _pump(tester, service);

    await tester.tap(_inCard('pay', find.text('Mark as Read')));
    await tester.pumpAndSettle();
    expect(_inCard('pay', find.text('Mark as Read')), findsOneWidget); // still unread
    expect(find.text("Couldn't update that notification. Please try again."), findsOneWidget);

    await tester.tap(_inCard('pay', find.byTooltip('Delete')));
    await tester.pumpAndSettle();
    expect(_card('pay'), findsOneWidget); // came back
  });

  testWidgets('View Details on an event opens that reservation on top of the feed, and marks it read', (tester) async {
    final service = _FakeService([_payment(), _event(read: false)]);
    final nav = await _pump(tester, service);

    await tester.tap(_inCard('ev', find.text('View Details')));
    await tester.pumpAndSettle();

    expect(service.calls, ['read:ev']);
    final details = tester.widget<ReservationDetailsScreen>(find.byType(ReservationDetailsScreen));
    expect(details.reservationId, 'res-1'); // the notification's related_id
    expect(nav, isEmpty); // no tab switch

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Event Reservation Confirmed'), findsOneWidget); // back on the feed
  });

  testWidgets('View Details on a membership payment closes the feed and goes to Profile', (tester) async {
    final service = _FakeService([_payment()]);
    final nav = await _pump(tester, service);

    await tester.tap(_inCard('pay', find.text('View Details')));
    await tester.pumpAndSettle();

    expect(nav, ['membership']);
    expect(service.calls, ['read:pay']);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('empty state', (tester) async {
    await _pump(tester, _FakeService([]));
    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.text('No unread notifications'), findsOneWidget);
  });

  testWidgets('a failed load says so and can retry', (tester) async {
    await _pump(tester, _FakeService([], failLoad: true));
    expect(find.text("Couldn't load your notifications."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Arabic: translated cards, count and times', (tester) async {
    await _pump(tester, _FakeService([_payment(), _event(read: false)]), locale: 'ar');

    expect(find.text('إشعاران غير مقروءين'), findsOneWidget);
    expect(find.text('تم تفعيل العضوية'), findsOneWidget);
    expect(find.text('منذ ساعتين'), findsOneWidget);
    expect(find.text('منذ يوم'), findsOneWidget);
    expect(find.text('تعليم كمقروء'), findsNWidgets(2));
  });

  group('relativeTime', () {
    final en = lookupAppLocalizations(const Locale('en'));
    String rt(Duration age) => relativeTime(_now.subtract(age), _now, en);

    test('thresholds', () {
      expect(rt(const Duration(seconds: 20)), 'Just now');
      expect(rt(const Duration(minutes: 5)), '5m ago');
      expect(rt(const Duration(hours: 2, minutes: 59)), '2h ago');
      expect(rt(const Duration(days: 6)), '6d ago');
      expect(rt(const Duration(days: 8)), '9/19/2026'); // a week or more: the date
    });

    test('a slightly-ahead server clock reads as just now, not negative', () {
      expect(relativeTime(_now.add(const Duration(seconds: 30)), _now, en), 'Just now');
    });
  });
}
