import 'package:flutter_test/flutter_test.dart';
import 'package:sayad/screens/big_tides_screen.dart';
import 'package:sayad/services/astro.dart';
import 'package:sayad/services/ephemeris.dart';

void main() {
  test('new and full moons match published times (2026)', () {
    final s = syzygies(DateTime.utc(2026), DateTime.utc(2026, 3));
    final published = [
      (DateTime.utc(2026, 1, 3, 10, 3), true),
      (DateTime.utc(2026, 1, 18, 19, 52), false),
      (DateTime.utc(2026, 2, 1, 22, 9), true),
      (DateTime.utc(2026, 2, 17, 12, 1), false),
    ];
    expect(s, hasLength(published.length));
    for (var i = 0; i < s.length; i++) {
      expect(s[i].full, published[i].$2);
      expect(s[i].time.difference(published[i].$1).inMinutes.abs(), lessThan(15));
    }
  });

  test('sunrise and sunset agree with the prayer-time library', () {
    final day = DateTime(2026, 10, 31);
    final (rise, set) = sunRiseSet(33.57, -7.59, day);
    final p = prayerTimes(33.57, -7.59, day);
    expect(rise!.difference(p.sunrise).inMinutes.abs(), lessThanOrEqualTo(3));
    expect(set!.difference(p.maghrib).inMinutes.abs(), lessThanOrEqualTo(5));
  });

  test('moon rise and set are found most days', () {
    var found = 0;
    for (var d = 0; d < 30; d++) {
      final (r, s) = moonRiseSetExact(33.57, -7.59, DateTime(2026, 11, 1).add(Duration(days: d)));
      if (r != null) found++;
      if (s != null) found++;
    }
    // The moon skips one rise and one set per month.
    expect(found, greaterThanOrEqualTo(56));
  });

  test('a year has 24 to 26 spring tides, coefficients in range', () {
    final tides = bigTidesOf(2026);
    expect(tides.length, inInclusiveRange(24, 26));
    for (final t in tides) {
      expect(t.coefficient, inInclusiveRange(60, 120));
    }
    // Spring tides are stronger than the neap tide between them.
    final neap = tideCoefficient(DateTime(2026, 11, 3));
    expect(neap, lessThan(tides.map((t) => t.coefficient).reduce((a, b) => a < b ? a : b)));
  });
}
