import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

/// Weather + marine forecast for one point, from the Open-Meteo APIs.
class Forecast {
  Forecast({
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.windGusts,
    required this.pressure,
    required this.humidity,
    required this.weatherCode,
    required this.hourly,
    this.waveHeight,
    this.wavePeriod,
    this.waveDirection,
    this.seaTemperature,
  });

  final double temperature;
  final double windSpeed;
  final double windDirection;
  final double windGusts;
  final double pressure;
  final double humidity;
  final int weatherCode;
  final double? waveHeight;
  final double? wavePeriod;
  final double? waveDirection;
  final double? seaTemperature;
  final List<HourPoint> hourly;

  bool get hasMarine => waveHeight != null;

  /// Pressure change over the last 3 hours, in hPa (negative = falling).
  double get pressureTrend {
    final now = DateTime.now();
    final past = hourly.where((h) => h.time.isBefore(now)).toList();
    if (past.length < 4) return 0;
    return past.last.pressure - past[past.length - 4].pressure;
  }
}

class HourPoint {
  HourPoint({
    required this.time,
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.windGusts,
    required this.humidity,
    required this.pressure,
    required this.weatherCode,
    required this.isDay,
    this.waveHeight,
    this.waveDirection,
    this.wavePeriod,
    this.currentSpeed,
    this.currentDirection,
    this.seaLevel,
  });

  final DateTime time;
  final double temperature;
  final double windSpeed;
  final double windDirection;
  final double windGusts;
  final double humidity;
  final double pressure;
  final int weatherCode;
  final bool isDay;
  final double? waveHeight;
  final double? waveDirection;
  final double? wavePeriod;

  /// Ocean current, km/h.
  final double? currentSpeed;
  final double? currentDirection;

  /// Sea level relative to mean sea level (includes the tide), in metres.
  final double? seaLevel;
}

class TideEvent {
  TideEvent(this.time, this.height, this.isHigh);
  final DateTime time;
  final double height;
  final bool isHigh;
}

class ForecastService {
  static const _weatherUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _marineUrl = 'https://marine-api.open-meteo.com/v1/marine';
  static const days = 7;

  /// Wind is the average of these models: over 3 days of hourly reports at
  /// 9 Moroccan coastal airports it beat every single model (mean error
  /// 3.5 km/h vs 3.7–4.5 km/h, and less under-estimation).
  static const windModels = [
    'icon_seamless',
    'ecmwf_ifs',
    'meteofrance_seamless',
    'gfs_seamless',
  ];

  // Several screens show the same point: keep results for 30 minutes.
  static final _cache = <String, (DateTime, Future<Forecast>)>{};

  /// Puts a ready forecast in the cache (tests and previews).
  @visibleForTesting
  static void seed(double lat, double lon, Forecast f) {
    final key = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    _cache[key] = (DateTime.now(), Future.value(f));
  }

  Future<Forecast> fetch(double lat, double lon, {bool refresh = false}) {
    final key = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    final hit = _cache[key];
    if (!refresh &&
        hit != null &&
        DateTime.now().difference(hit.$1) < const Duration(minutes: 30)) {
      return hit.$2;
    }
    final future = _fetch(lat, lon);
    _cache[key] = (DateTime.now(), future);
    future.then((_) {}, onError: (Object _) {
      _cache.remove(key);
    });
    return future;
  }

  Future<Forecast> _fetch(double lat, double lon) async {
    final weatherUri = Uri.parse(_weatherUrl).replace(queryParameters: {
      'latitude': '$lat',
      'longitude': '$lon',
      'current':
          'temperature_2m,relative_humidity_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,pressure_msl,weather_code',
      'hourly':
          'temperature_2m,relative_humidity_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,pressure_msl,weather_code,is_day',
      'past_days': '1',
      'forecast_days': '$days',
      'timezone': 'auto',
    });
    final windUri = Uri.parse(_weatherUrl).replace(queryParameters: {
      'latitude': '$lat',
      'longitude': '$lon',
      'hourly': 'wind_speed_10m,wind_direction_10m,wind_gusts_10m',
      'models': windModels.join(','),
      'past_days': '1',
      'forecast_days': '$days',
      'timezone': 'auto',
    });
    final marineUri = Uri.parse(_marineUrl).replace(queryParameters: {
      'latitude': '$lat',
      'longitude': '$lon',
      'current':
          'wave_height,wave_direction,wave_period,sea_surface_temperature',
      'hourly':
          'wave_height,wave_direction,wave_period,ocean_current_velocity,ocean_current_direction,sea_level_height_msl',
      'past_days': '1',
      'forecast_days': '$days',
      'timezone': 'auto',
      // Use the nearest sea cell, so a town on the coast still gets waves.
      'cell_selection': 'sea',
    });

    final results = await Future.wait([
      http.get(weatherUri),
      // Inland points have no marine data: treat a failure as "no sea".
      http.get(marineUri).catchError((_) => http.Response('{}', 400)),
      // The averaged wind is a bonus: fall back to the default model.
      http.get(windUri).catchError((_) => http.Response('{}', 400)),
    ]);
    if (results[0].statusCode != 200) {
      throw Exception('Weather API error ${results[0].statusCode}');
    }
    final w = jsonDecode(results[0].body) as Map<String, dynamic>;
    final m = results[1].statusCode == 200
        ? jsonDecode(results[1].body) as Map<String, dynamic>
        : <String, dynamic>{};

    final wc = w['current'] as Map<String, dynamic>;
    final wh = w['hourly'] as Map<String, dynamic>;
    final mc = m['current'] as Map<String, dynamic>?;
    final mh = m['hourly'] as Map<String, dynamic>?;
    final ensemble = results[2].statusCode == 200
        ? averageWind(jsonDecode(results[2].body) as Map<String, dynamic>)
        : const <String, (double, double, double?)>{};

    // Marine hourly series is aligned by timestamp, not by index.
    final marineByTime = <String, int>{};
    final marineTimes = (mh?['time'] as List?) ?? const [];
    for (var i = 0; i < marineTimes.length; i++) {
      marineByTime[marineTimes[i] as String] = i;
    }
    double? marine(String field, int? i) =>
        i == null ? null : _d((mh![field] as List?)?[i]);

    final times = (wh['time'] as List).cast<String>();
    final hourly = <HourPoint>[];
    for (var i = 0; i < times.length; i++) {
      final mi = marineByTime[times[i]];
      final ens = ensemble[times[i]];
      hourly.add(HourPoint(
        time: DateTime.parse(times[i]),
        temperature: _d(wh['temperature_2m'][i]) ?? 0,
        humidity: _d(wh['relative_humidity_2m'][i]) ?? 0,
        windSpeed: ens?.$1 ?? _d(wh['wind_speed_10m'][i]) ?? 0,
        windDirection: ens?.$2 ?? _d(wh['wind_direction_10m'][i]) ?? 0,
        windGusts: ens?.$3 ?? _d(wh['wind_gusts_10m'][i]) ?? 0,
        pressure: _d(wh['pressure_msl'][i]) ?? 1013,
        weatherCode: (wh['weather_code'][i] as num?)?.toInt() ?? 0,
        isDay: (wh['is_day'][i] as num?) != 0,
        waveHeight: marine('wave_height', mi),
        waveDirection: marine('wave_direction', mi),
        wavePeriod: marine('wave_period', mi),
        currentSpeed: marine('ocean_current_velocity', mi),
        currentDirection: marine('ocean_current_direction', mi),
        seaLevel: marine('sea_level_height_msl', mi),
      ));
    }

    final nowWind = ensemble.isEmpty ? null : _windAt(hourly, DateTime.now());
    return Forecast(
      temperature: _d(wc['temperature_2m']) ?? 0,
      humidity: _d(wc['relative_humidity_2m']) ?? 0,
      windSpeed: nowWind?.$1 ?? _d(wc['wind_speed_10m']) ?? 0,
      windDirection: nowWind?.$2 ?? _d(wc['wind_direction_10m']) ?? 0,
      windGusts: nowWind?.$3 ?? _d(wc['wind_gusts_10m']) ?? 0,
      pressure: _d(wc['pressure_msl']) ?? 1013,
      weatherCode: (wc['weather_code'] as num?)?.toInt() ?? 0,
      waveHeight: _d(mc?['wave_height']),
      wavePeriod: _d(mc?['wave_period']),
      waveDirection: _d(mc?['wave_direction']),
      seaTemperature: _d(mc?['sea_surface_temperature']),
      hourly: hourly,
    );
  }

  static double? _d(Object? v) => (v as num?)?.toDouble();

  /// Wind (speed, direction, gusts) at [t], interpolated between hours.
  static (double, double, double)? _windAt(List<HourPoint> hourly, DateTime t) {
    for (var i = 0; i < hourly.length - 1; i++) {
      final a = hourly[i], b = hourly[i + 1];
      if (!t.isBefore(a.time) && t.isBefore(b.time)) {
        final f = t.difference(a.time).inSeconds / 3600;
        final dir = f < 0.5 ? a.windDirection : b.windDirection;
        return (
          a.windSpeed + (b.windSpeed - a.windSpeed) * f,
          dir,
          a.windGusts + (b.windGusts - a.windGusts) * f,
        );
      }
    }
    return null;
  }
}

/// Averages the per-model hourly wind of an Open-Meteo multi-model reply.
/// Returns time → (speed, direction, gusts or null). Direction is the
/// vector mean, so 350° and 10° average to 0°, not 180°.
Map<String, (double, double, double?)> averageWind(Map<String, dynamic> json) {
  final h = json['hourly'] as Map<String, dynamic>?;
  if (h == null) return const {};
  final times = (h['time'] as List).cast<String>();
  final out = <String, (double, double, double?)>{};
  for (var i = 0; i < times.length; i++) {
    final speeds = <double>[], gusts = <double>[];
    var u = 0.0, v = 0.0;
    for (final m in ForecastService.windModels) {
      final sp = ((h['wind_speed_10m_$m'] as List?)?[i] as num?)?.toDouble();
      final dir = ((h['wind_direction_10m_$m'] as List?)?[i] as num?)?.toDouble();
      final g = ((h['wind_gusts_10m_$m'] as List?)?[i] as num?)?.toDouble();
      if (sp != null) speeds.add(sp);
      if (g != null) gusts.add(g);
      if (sp != null && dir != null) {
        u += sp * sin(dir * pi / 180);
        v += sp * cos(dir * pi / 180);
      }
    }
    if (speeds.isEmpty) continue;
    final dir = (atan2(u, v) * 180 / pi + 360) % 360;
    out[times[i]] = (
      speeds.reduce((a, b) => a + b) / speeds.length,
      dir,
      gusts.isEmpty ? null : gusts.reduce((a, b) => a + b) / gusts.length,
    );
  }
  return out;
}

/// High and low tides found as local extremes of the modelled sea level.
List<TideEvent> tideEvents(List<HourPoint> hourly, {DateTime? from}) {
  final start = from ?? DateTime.now();
  final pts = hourly.where((h) => h.seaLevel != null).toList();
  final events = <TideEvent>[];
  for (var i = 1; i < pts.length - 1; i++) {
    final prev = pts[i - 1].seaLevel!, cur = pts[i].seaLevel!, next = pts[i + 1].seaLevel!;
    if (pts[i].time.isBefore(start)) continue;
    if (cur > prev && cur >= next) events.add(TideEvent(pts[i].time, cur, true));
    if (cur < prev && cur <= next) events.add(TideEvent(pts[i].time, cur, false));
  }
  return events;
}
