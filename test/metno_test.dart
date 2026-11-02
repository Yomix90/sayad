import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sayad/services/forecast_service.dart';

void main() {
  test('MET Norway forecast becomes hourly Open-Meteo-like series', () {
    // Real reply for Agadir, saved on 2026-11-02 (hourly, then 6-hourly).
    final json = jsonDecode(File('test/fixtures/metno_agadir.json').readAsStringSync())
        as Map<String, dynamic>;
    final w = metNoToOpenMeteo(json);
    final h = w['hourly'] as Map<String, dynamic>;
    final times = (h['time'] as List).cast<String>();

    // Hour by hour, with no gap, for more than 8 days.
    final parsed = times.map(DateTime.parse).toList();
    for (var i = 1; i < parsed.length; i++) {
      expect(parsed[i].difference(parsed[i - 1]).inHours, 1, reason: times[i]);
    }
    expect(parsed.last.difference(parsed.first).inDays, greaterThanOrEqualTo(8));
    for (final k in h.keys) {
      expect((h[k] as List).length, times.length, reason: k);
    }

    // Plausible values in Open-Meteo units.
    for (final v in (h['wind_speed_10m'] as List).cast<double>()) {
      expect(v, inInclusiveRange(0, 150));
    }
    for (final v in (h['wind_direction_10m'] as List).cast<double>()) {
      expect(v, inInclusiveRange(0, 360));
    }
    for (final v in (h['pressure_msl'] as List).cast<double>()) {
      expect(v, inInclusiveRange(950, 1060));
    }
    final c = w['current'] as Map<String, dynamic>;
    expect(c['temperature_2m'], 24.7);
    expect(c['wind_speed_10m'], closeTo(3.0 * 3.6, 1e-6));
    expect(c['weather_code'], 61); // light rain
    expect((c['wind_gusts_10m'] as double) > (c['wind_speed_10m'] as double), isTrue);
  });
}
