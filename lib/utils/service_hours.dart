/// Rosewater Café's fixed service hours -- full service 9:00 AM-11:00 PM,
/// self-service the rest of the day (11:00 PM-9:00 AM, wrapping past
/// midnight). Same every day for every member; this never touches the
/// database (see docs/decisions.md #30) -- the only real logic on this
/// card is which window the current time falls into.
class ServiceHours {
  ServiceHours._();

  static const fullServiceStartHour = 9; // 9:00 AM
  static const fullServiceEndHour = 23; // 11:00 PM

  /// True if [time]'s local hour falls inside the full-service window
  /// (9:00 AM up to, but not including, 11:00 PM). A pure function of
  /// [time] rather than reading `DateTime.now()` itself, so both branches
  /// -- including the exact boundary hours -- are unit-testable without
  /// touching the system clock; see test/service_hours_test.dart.
  static bool isFullServiceAt(DateTime time) {
    return time.hour >= fullServiceStartHour && time.hour < fullServiceEndHour;
  }
}
