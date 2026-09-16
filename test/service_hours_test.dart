import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/utils/service_hours.dart';

void main() {
  group('isFullServiceAt', () {
    test('is full service at opening (9:00 AM exactly)', () {
      expect(ServiceHours.isFullServiceAt(DateTime(2026, 1, 1, 9, 0)), isTrue);
    });

    test('is full service mid-afternoon', () {
      expect(ServiceHours.isFullServiceAt(DateTime(2026, 1, 1, 14, 30)), isTrue);
    });

    test('is full service right before closing (10:59 PM)', () {
      expect(ServiceHours.isFullServiceAt(DateTime(2026, 1, 1, 22, 59)), isTrue);
    });

    test('is self-service at the exact closing hour (11:00 PM)', () {
      expect(ServiceHours.isFullServiceAt(DateTime(2026, 1, 1, 23, 0)), isFalse);
    });

    test('is self-service late at night', () {
      expect(ServiceHours.isFullServiceAt(DateTime(2026, 1, 1, 23, 30)), isFalse);
    });

    test('is self-service just after midnight', () {
      expect(ServiceHours.isFullServiceAt(DateTime(2026, 1, 2, 0, 15)), isFalse);
    });

    test('is self-service right before opening (8:59 AM)', () {
      expect(ServiceHours.isFullServiceAt(DateTime(2026, 1, 2, 8, 59)), isFalse);
    });

    test('is full service again right at the next day\'s opening', () {
      expect(ServiceHours.isFullServiceAt(DateTime(2026, 1, 2, 9, 0)), isTrue);
    });
  });
}
