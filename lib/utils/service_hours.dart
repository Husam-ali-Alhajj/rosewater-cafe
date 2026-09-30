/// The cafe's fixed hours: full service 9:00 AM - 11:00 PM, self-service the rest of the time.
class ServiceHours {
  ServiceHours._();

  static const fullServiceStartHour = 9; // 9:00 AM
  static const fullServiceEndHour = 23; // 11:00 PM

  /// True if [time] is within full-service hours (9:00 AM up to 11:00 PM).
  static bool isFullServiceAt(DateTime time) {
    return time.hour >= fullServiceStartHour && time.hour < fullServiceEndHour;
  }
}
