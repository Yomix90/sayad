import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sayad/services/forecast_service.dart';
import 'package:sayad/services/hijri.dart';
import 'package:sayad/services/tide_service.dart';

void main() {
  test('wind average uses the vector mean for direction', () {
    final json = {
      'hourly': {
        'time': ['2026-10-31T12:00'],
        'wind_speed_10m_icon_seamless': [10],
        'wind_direction_10m_icon_seamless': [350],
        'wind_gusts_10m_icon_seamless': [20],
        'wind_speed_10m_ecmwf_ifs': [10],
        'wind_direction_10m_ecmwf_ifs': [10],
        'wind_gusts_10m_ecmwf_ifs': [null],
        'wind_speed_10m_meteofrance_seamless': [16],
        'wind_direction_10m_meteofrance_seamless': [0],
        'wind_gusts_10m_meteofrance_seamless': [30],
        'wind_speed_10m_gfs_seamless': [null],
        'wind_direction_10m_gfs_seamless': [null],
        'wind_gusts_10m_gfs_seamless': [null],
      },
    };
    final (speed, dir, gust) = averageWind(json)['2026-10-31T12:00']!;
    expect(speed, closeTo(12, 1e-9));
    expect(dir < 1 || dir > 359, isTrue, reason: 'got $dir');
    expect(gust, closeTo(25, 1e-9));
  });

  test('WorldTides reply is parsed into heights and extremes', () {
    final data = TideService.parseWorldTides({
      'status': 200,
      'station': 'Casablanca',
      'heights': [
        {'dt': 1793430000, 'date': '', 'height': 1.3},
        {'dt': 1793431800, 'date': '', 'height': 1.6},
      ],
      'extremes': [
        {'dt': 1793452980, 'date': '', 'height': 3.31, 'type': 'High'},
        {'dt': 1793476320, 'date': '', 'height': 1.23, 'type': 'Low'},
      ],
    });
    expect(data.source, TideSource.worldTides);
    expect(data.station, 'Casablanca');
    expect(data.heights, hasLength(2));
    expect(data.extremes.first.isHigh, isTrue);
    expect(data.extremes.last.height, 1.23);
  });

  test('WorldTides errors are reported', () {
    expect(() => TideService.parseWorldTides({'status': 400, 'error': 'No credits'}),
        throwsException);
  });

  test('Stormglass extremes give a smooth curve through each tide', () {
    final data = TideService.parseStormglass({
      'data': [
        {'height': 0.55, 'time': '2026-10-31 11:34:00+00:00', 'type': 'low'},
        {'height': 2.44, 'time': '2026-10-31 17:58:00+00:00', 'type': 'high'},
        {'height': 0.77, 'time': '2026-10-31 23:51:00+00:00', 'type': 'low'},
      ],
      'meta': {
        'station': {'name': 'casablanca', 'distance': 2},
      },
    });
    expect(data.source, TideSource.stormglass);
    expect(data.station, 'casablanca');
    expect(data.extremes[1].isHigh, isTrue);
    expect(data.extremes[1].time, DateTime.utc(2026, 10, 31, 17, 58).toLocal());
    // Starts at the low, peaks at the high, never overshoots.
    expect(data.heights.first.$2, closeTo(0.55, 1e-9));
    final top = data.heights.map((h) => h.$2).reduce(max);
    expect(top, closeTo(2.44, 1e-9));
    expect(data.heights.every((h) => h.$2 >= 0.55 - 1e-9), isTrue);
  });

  test('Casablanca correction matches the port tide table (Tifnit, 31 Oct)', () {
    // Stormglass extremes for 31 Oct 2026 (UTC) near Casablanca.
    final data = TideService.parseStormglass({
      'data': [
        {'height': 2.76, 'time': '2026-10-31T05:18:00+00:00', 'type': 'high'},
        {'height': 0.55, 'time': '2026-10-31T11:34:00+00:00', 'type': 'low'},
        {'height': 2.44, 'time': '2026-10-31T17:58:00+00:00', 'type': 'high'},
      ],
      'meta': {
        'station': {'name': 'casablanca'},
      },
    }, lat: 33.5731, lon: -7.5898);
    expect(data.correctedFor, 'Casablanca');
    // Tide table (GMT): high 06:23 3.31 m, low 12:52 1.23 m, high 19:07 2.97 m.
    final table = [
      (DateTime.utc(2026, 10, 31, 6, 23), 3.31),
      (DateTime.utc(2026, 10, 31, 12, 52), 1.23),
      (DateTime.utc(2026, 10, 31, 19, 7), 2.97),
    ];
    for (var i = 0; i < 3; i++) {
      final e = data.extremes[i];
      expect(e.time.difference(table[i].$1.toLocal()).inMinutes.abs(), lessThan(10));
      expect((e.height - table[i].$2).abs(), lessThan(0.05));
    }
  });

  test('no correction far from calibrated ports', () {
    final data = TideService.parseStormglass({
      'data': [
        {'height': 2.0, 'time': '2026-10-31T05:00:00+00:00', 'type': 'high'},
        {'height': 0.5, 'time': '2026-10-31T11:00:00+00:00', 'type': 'low'},
      ],
    }, lat: 30.42, lon: -9.6);
    expect(data.correctedFor, isNull);
    expect(data.extremes.first.height, 2.0);
  });

  test('Hijri date of 31 Oct 2026 is in Jumada al-Ula 1448', () {
    final (d, m, y) = hijriDate(DateTime(2026, 10, 31));
    expect(m, 5);
    expect(y, 1448);
    expect(d, inInclusiveRange(18, 22));
    final (d2, _, _) = hijriDate(DateTime(2026, 10, 31), offsetDays: -1);
    expect(d2, d - 1);
    expect(formatHijri(DateTime(2026, 10, 31), 'ar'), contains('جمادى الأولى'));
  });
}
