import 'package:flutter_test/flutter_test.dart';
import 'package:jameel/shared/helpers/tenure_helper.dart';

void main() {
  group('yearsOfService', () {
    final today = DateTime(2026, 11, 25);

    test('returns null when the join date is unknown', () {
      expect(yearsOfService(null, now: today), isNull);
    });

    test('counts only completed years (anniversary not reached yet)', () {
      // 5 calendar years apart, but the anniversary (Dec 31) is still ahead.
      expect(yearsOfService(DateTime(2021, 12, 31), now: today), 4);
    });

    test('counts the year on the anniversary day itself', () {
      expect(yearsOfService(DateTime(2021, 11, 25), now: today), 5);
    });

    test('hides the badge for less than one year or a future date', () {
      expect(yearsOfService(DateTime(2026, 1, 1), now: today), isNull);
      expect(yearsOfService(DateTime(2027, 1, 1), now: today), isNull);
    });
  });
}
