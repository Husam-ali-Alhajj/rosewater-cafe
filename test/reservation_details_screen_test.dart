import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/models/reservation_details.dart';
import 'package:rosewater_cafe/screens/events/reservation_details_screen.dart';
import 'package:rosewater_cafe/services/event_reservation_service.dart';

ReservationDetails _reservation({String status = 'confirmed', double hours = 3}) => ReservationDetails.fromMap({
  'id': 'res-1',
  'event_type': 'Birthday',
  'event_date': '2026-10-04',
  'start_time': '19:30:00',
  'duration_hours': hours,
  'guest_count': 12,
  'status': status,
  'total_price': hours * 150,
});

class _FakeService extends EventReservationService {
  final Object? result; // ReservationDetails, null (not found), or an error to throw
  final List<String> asked = [];

  _FakeService(this.result);

  @override
  Future<ReservationDetails?> fetchReservation(String id) async {
    asked.add(id);
    final r = result;
    if (r is ReservationDetails?) return r;
    throw r;
  }
}

Future<void> _pump(WidgetTester tester, _FakeService service, {String locale = 'en'}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReservationDetailsScreen(reservationId: 'res-1', service: service),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  testWidgets('shows the real reservation, read-only', (tester) async {
    final service = _FakeService(_reservation());
    await _pump(tester, service);

    expect(service.asked, ['res-1']);
    expect(find.text('Reservation Details'), findsOneWidget);
    expect(find.text('Birthday'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Sun, Oct 4, 2026'), findsOneWidget);
    expect(find.text('7:30 PM'), findsOneWidget);
    expect(find.text('3 hours'), findsOneWidget);
    expect(find.text('12 people'), findsOneWidget);
    expect(find.text(r'$450.00'), findsOneWidget);
    // Nothing to press but Back.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('a cancelled reservation says so', (tester) async {
    await _pump(tester, _FakeService(_reservation(status: 'cancelled')));
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('a half-hour duration keeps its decimal', (tester) async {
    await _pump(tester, _FakeService(_reservation(hours: 2.5)));
    expect(find.text('2.5 hours'), findsOneWidget);
  });

  testWidgets('not found (or not yours) shows a message, not a blank page', (tester) async {
    await _pump(tester, _FakeService(null));
    expect(find.text('This reservation is no longer available.'), findsOneWidget);
  });

  testWidgets('a failed load can be retried', (tester) async {
    await _pump(tester, _FakeService(StateError('offline')));
    expect(find.text("Couldn't load this reservation."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Arabic', (tester) async {
    await _pump(tester, _FakeService(_reservation()), locale: 'ar');
    expect(find.text('تفاصيل الحجز'), findsOneWidget);
    expect(find.text('عيد ميلاد'), findsOneWidget);
    expect(find.text('مؤكد'), findsOneWidget);
  });
}
