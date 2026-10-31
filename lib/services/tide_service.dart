import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/tide_corrections.dart';
import 'forecast_service.dart';

enum TideSource {
  /// Harmonic predictions from WorldTides (FES atlas + tide stations).
  worldTides,

  /// Predictions from Stormglass, based on the nearest tide station.
  stormglass,

  /// Sea level from the Open-Meteo ocean model: can be ~1–2 h off.
  model,
}

class TideData {
  TideData({
    required this.heights,
    required this.extremes,
    required this.source,
    this.station,
    this.correctedFor,
  });

  /// (time, height in m). WorldTides heights are above chart datum (LAT),
  /// like printed tide tables; model heights are around mean sea level.
  final List<(DateTime, double)> heights;
  final List<TideEvent> extremes;
  final TideSource source;
  final String? station;

  /// Port whose tide table was used to correct the predictions, if any.
  final String? correctedFor;
}

/// Tide predictions. Uses WorldTides or Stormglass when the app is built
/// with `--dart-define=WORLDTIDES_KEY=...` or `--dart-define=STORMGLASS_KEY=...`
/// (WorldTides first if both), otherwise the Open-Meteo model.
class TideService {
  static const apiKey = String.fromEnvironment('WORLDTIDES_KEY');
  static const stormglassKey = String.fromEnvironment('STORMGLASS_KEY');
  static const _cacheHours = 24;

  static bool get hasKey => apiKey.isNotEmpty || stormglassKey.isNotEmpty;

  /// Tides for 7 days from today's midnight at [lat], [lon].
  /// [forecast] provides the model fallback.
  Future<TideData> load(double lat, double lon, Forecast forecast) async {
    // On a network or quota problem, try the next source, then the model.
    if (apiKey.isNotEmpty) {
      try {
        return await _worldTides(lat, lon);
      } catch (_) {}
    }
    if (stormglassKey.isNotEmpty) {
      try {
        return await _stormglass(lat, lon);
      } catch (_) {}
    }
    return fromModel(forecast);
  }

  static TideData fromModel(Forecast f) {
    final heights = [
      for (final h in f.hourly)
        if (h.seaLevel != null) (h.time, h.seaLevel!),
    ];
    final now = DateTime.now();
    return TideData(
      heights: heights,
      extremes: tideEvents(f.hourly, from: DateTime(now.year, now.month, now.day)),
      source: TideSource.model,
    );
  }

  /// Calls are paid or capped per day: reuse an answer for the same spot
  /// for [_cacheHours]. Returns the cached JSON body, or null.
  static Future<Map<String, dynamic>?> _cached(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached == null) return null;
    final saved = jsonDecode(cached) as Map<String, dynamic>;
    final at = DateTime.parse(saved['savedAt'] as String);
    if (DateTime.now().difference(at).inHours >= _cacheHours) return null;
    return saved['body'] as Map<String, dynamic>;
  }

  static Future<void> _store(String key, Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key,
        jsonEncode({'savedAt': DateTime.now().toIso8601String(), 'body': body}));
  }

  static String _cacheKey(String source, double lat, double lon, DateTime day) =>
      'tides:$source:${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}:'
      '${day.toIso8601String().substring(0, 10)}';

  Future<TideData> _worldTides(double lat, double lon) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final cacheKey = _cacheKey('worldtides', lat, lon, start);
    final cached = await _cached(cacheKey);
    if (cached != null) return parseWorldTides(cached);

    final uri = Uri.parse('https://www.worldtides.info/api/v3').replace(
      queryParameters: {
        'heights': '',
        'extremes': '',
        'lat': '$lat',
        'lon': '$lon',
        'start': '${start.millisecondsSinceEpoch ~/ 1000}',
        'length': '${ForecastService.days * 86400}',
        'step': '1800',
        'datum': 'LAT',
        'key': apiKey,
      },
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = parseWorldTides(body);
    await _store(cacheKey, body);
    return data;
  }

  /// One call per spot and per week: the free plan allows 10 calls a day.
  /// Only the high/low tides are fetched (10 days max per call); the curve
  /// between them is rebuilt with the usual cosine shape of a tide.
  Future<TideData> _stormglass(double lat, double lon) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // ~11 km cells: nearby points share the same nearest tide station.
    final cacheKey = 'tides:stormglass:${lat.toStringAsFixed(1)},${lon.toStringAsFixed(1)}';
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    if (raw != null) {
      final body = jsonDecode(raw) as Map<String, dynamic>;
      final data = parseStormglass(body, lat: lat, lon: lon);
      // Reuse while it still covers the next 4 days.
      if (data.extremes.isNotEmpty &&
          data.extremes.first.time.isBefore(today) &&
          data.extremes.last.time.isAfter(today.add(const Duration(days: 4)))) {
        return data;
      }
    }

    // From yesterday, so today's curve starts from a known high or low.
    final start = today.subtract(const Duration(days: 1));
    final end = start.add(const Duration(days: 10));
    final uri = Uri.parse('https://api.stormglass.io/v2/tide/extremes/point').replace(
      queryParameters: {
        'lat': '$lat',
        'lng': '$lon',
        'start': '${start.millisecondsSinceEpoch ~/ 1000}',
        'end': '${end.millisecondsSinceEpoch ~/ 1000}',
        'datum': 'LAT',
      },
    );
    final res = await http
        .get(uri, headers: {'Authorization': stormglassKey})
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Stormglass ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = parseStormglass(body, lat: lat, lon: lon);
    await prefs.setString(cacheKey, res.body);
    return data;
  }

  /// Parses a Stormglass reply. Near a calibrated port ([lat], [lon]),
  /// times and heights are corrected towards that port's tide table.
  @visibleForTesting
  static TideData parseStormglass(Map<String, dynamic> body,
      {double? lat, double? lon}) {
    final c = lat == null || lon == null ? null : correctionNear(lat, lon);
    final shift = Duration(minutes: c?.minutes ?? 0);
    final extremes = [
      for (final e in (body['data'] as List).cast<Map>())
        TideEvent(
            DateTime.parse(e['time'] as String).toLocal().add(shift),
            c == null
                ? (e['height'] as num).toDouble()
                : c.scale * (e['height'] as num).toDouble() + c.offset,
            e['type'] == 'high'),
    ];
    if (extremes.length < 2) throw Exception('Stormglass: no data');
    final station =
        ((body['meta'] as Map?)?['station'] as Map?)?['name'] as String?;
    return TideData(
      heights: curveFromExtremes(extremes),
      extremes: extremes,
      source: TideSource.stormglass,
      station: station,
      correctedFor: c?.port,
    );
  }

  /// Water level every 30 min between successive high and low tides,
  /// following half a cosine from one to the next.
  static List<(DateTime, double)> curveFromExtremes(List<TideEvent> extremes) {
    final out = <(DateTime, double)>[];
    for (var i = 0; i < extremes.length - 1; i++) {
      final a = extremes[i], b = extremes[i + 1];
      final span = b.time.difference(a.time).inMinutes;
      for (var m = 0; m < span; m += 30) {
        final f = m / span;
        final h = a.height + (b.height - a.height) * (1 - cos(pi * f)) / 2;
        out.add((a.time.add(Duration(minutes: m)), h));
      }
    }
    out.add((extremes.last.time, extremes.last.height));
    return out;
  }

  @visibleForTesting
  static TideData parseWorldTides(Map<String, dynamic> body) {
    if (body['status'] != 200) {
      throw Exception('WorldTides: ${body['error'] ?? body['status']}');
    }
    DateTime time(Map e) =>
        DateTime.fromMillisecondsSinceEpoch((e['dt'] as num).toInt() * 1000);
    final heights = [
      for (final e in (body['heights'] as List? ?? const []).cast<Map>())
        (time(e), (e['height'] as num).toDouble()),
    ];
    final extremes = [
      for (final e in (body['extremes'] as List? ?? const []).cast<Map>())
        TideEvent(time(e), (e['height'] as num).toDouble(), e['type'] == 'High'),
    ];
    return TideData(
      heights: heights,
      extremes: extremes,
      source: TideSource.worldTides,
      station: body['station'] as String?,
    );
  }
}
