import 'package:flutter_test/flutter_test.dart';
import 'package:sayad/services/astro.dart';
import 'package:sayad/services/forecast_service.dart';

void main() {
  test('full moon on 2026-10-26 is detected', () {
    final m = moonInfo(DateTime.utc(2026, 10, 26, 12));
    expect(m.phase, MoonPhase.full);
    expect(m.illumination, greaterThan(0.95));
  });

  test('qibla from Casablanca points east', () {
    final q = qiblaDirection(33.5731, -7.5898);
    expect(q, inInclusiveRange(85, 100));
  });

  test('solunar periods fall inside the day, majors are 2 h', () {
    final day = DateTime(2026, 11, 3);
    final periods = solunarPeriods(33.57, -7.59, day);
    expect(periods, isNotEmpty);
    for (final p in periods) {
      expect(p.start.day, day.day);
      expect(p.end.difference(p.start).inMinutes, p.major ? 120 : 60);
    }
    expect(solunarDayRating(33.57, -7.59, day), inInclusiveRange(1, 4));
  });

  test('tide extremes are found in a sine series', () {
    final start = DateTime.now();
    final hourly = [
      for (var i = 0; i < 48; i++)
        HourPoint(
          time: start.add(Duration(hours: i)),
          temperature: 20, windSpeed: 10, windDirection: 0, windGusts: 15,
          humidity: 80, pressure: 1015, weatherCode: 0, isDay: true,
          seaLevel: [0.0, 0.5, 0.9, 1.0, 0.9, 0.5, 0.0, -0.5, -0.9, -1.0, -0.9, -0.5][i % 12],
        ),
    ];
    final events = tideEvents(hourly, from: start);
    expect(events.where((e) => e.isHigh).length, 4);
    expect(events.where((e) => !e.isHigh).length, 4);
  });
}
