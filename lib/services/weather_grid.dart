import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' show LatLng;

/// Layers of the weather map.
enum WxLayer { wind, gusts, waves, rain, temp, pressure }

/// One weather variable on a regular latitude/longitude grid, for each hour.
class WeatherGrid {
  WeatherGrid({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.rows,
    required this.cols,
    required this.start,
    required this.values,
    this.directions,
  });

  final double south, west, north, east;
  final int rows, cols;

  /// First hour (UTC) of the data.
  final DateTime start;

  /// values[hour][row * cols + col], null where there is no data (land for waves).
  final List<List<double?>> values;
  final List<List<double?>>? directions;

  bool covers(double s, double w, double n, double e) =>
      s >= south && n <= north && w >= west && e <= east;

  LatLng point(int r, int c) => LatLng(
      south + (north - south) * r / (rows - 1), west + (east - west) * c / (cols - 1));

  /// Value at [p] for [hour], interpolated between the 4 nearest grid points.
  double? at(LatLng p, int hour) {
    final v = values[hour.clamp(0, values.length - 1)];
    final y = (p.latitude - south) / (north - south) * (rows - 1);
    final x = (p.longitude - west) / (east - west) * (cols - 1);
    if (y < 0 || x < 0 || y > rows - 1 || x > cols - 1) return null;
    final r0 = y.floor().clamp(0, rows - 2), c0 = x.floor().clamp(0, cols - 2);
    final fy = y - r0, fx = x - c0;
    var sum = 0.0, weight = 0.0;
    for (final (dr, dc, w) in [
      (0, 0, (1 - fy) * (1 - fx)),
      (0, 1, (1 - fy) * fx),
      (1, 0, fy * (1 - fx)),
      (1, 1, fy * fx),
    ]) {
      final val = v[(r0 + dr) * cols + c0 + dc];
      if (val != null && w > 0) {
        sum += val * w;
        weight += w;
      }
    }
    // Coast: keep sea values without spreading them far inland.
    return weight < 0.35 ? null : sum / weight;
  }
}

/// Colour scale of a layer: values and colours at the stops.
class WxScale {
  const WxScale(this.stops, this.unit);

  final List<(double, Color)> stops;
  final String unit;

  Color color(double v) {
    if (v <= stops.first.$1) return stops.first.$2;
    for (var i = 1; i < stops.length; i++) {
      if (v <= stops[i].$1) {
        final (a, ca) = stops[i - 1];
        final (b, cb) = stops[i];
        return Color.lerp(ca, cb, (v - a) / (b - a))!;
      }
    }
    return stops.last.$2;
  }
}

const wxScales = <WxLayer, WxScale>{
  WxLayer.wind: WxScale([
    (0, Color(0xFF6271B7)), (10, Color(0xFF39A0C8)), (20, Color(0xFF4ABF7A)), (30, Color(0xFFA9D24B)),
    (40, Color(0xFFF2C641)), (55, Color(0xFFF08A35)), (70, Color(0xFFD9443B)), (90, Color(0xFF9E2A6B)),
  ], 'km/h'),
  WxLayer.gusts: WxScale([
    (0, Color(0xFF6271B7)), (15, Color(0xFF39A0C8)), (30, Color(0xFF4ABF7A)), (45, Color(0xFFA9D24B)),
    (60, Color(0xFFF2C641)), (75, Color(0xFFF08A35)), (95, Color(0xFFD9443B)), (120, Color(0xFF9E2A6B)),
  ], 'km/h'),
  WxLayer.waves: WxScale([
    (0, Color(0xFF2B6CB0)), (0.5, Color(0xFF3AA0D0)), (1, Color(0xFF4CC3A7)), (1.5, Color(0xFFA6D96A)),
    (2, Color(0xFFF4D35E)), (3, Color(0xFFF28F3B)), (4, Color(0xFFD7263D)), (6, Color(0xFF7B1E7A)),
  ], 'm'),
  WxLayer.rain: WxScale([
    (0, Color(0x00000000)), (0.1, Color(0x669ED8F0)), (0.5, Color(0xFF6CC0EC)), (1, Color(0xFF3FA7E0)),
    (3, Color(0xFF2C6FD1)), (6, Color(0xFF7E3FC6)), (12, Color(0xFFD1307B)),
  ], 'mm/h'),
  WxLayer.temp: WxScale([
    (-5, Color(0xFF5B4FB3)), (5, Color(0xFF3D8FD1)), (12, Color(0xFF46C2B4)), (18, Color(0xFF9AD25A)),
    (24, Color(0xFFF3D046)), (30, Color(0xFFF28A35)), (38, Color(0xFFC8303A)),
  ], '°C'),
  WxLayer.pressure: WxScale([
    (990, Color(0xFF6A3FA0)), (1000, Color(0xFF3E7CC9)), (1010, Color(0xFF48B9A8)),
    (1018, Color(0xFFA6D16A)), (1025, Color(0xFFF1C84B)), (1035, Color(0xFFE2753A)),
  ], 'hPa'),
};

/// Downloads forecast grids from Open-Meteo (several points per request).
class WeatherGridService {
  WeatherGridService({http.Client? client})
      : _client = client ?? testClient ?? http.Client();

  @visibleForTesting
  static http.Client? testClient;

  final http.Client _client;
  static final _cache = <String, (DateTime, WeatherGrid)>{};

  static const _hourly = {
    WxLayer.wind: ('wind_speed_10m', 'wind_direction_10m'),
    WxLayer.gusts: ('wind_gusts_10m', 'wind_direction_10m'),
    WxLayer.waves: ('wave_height', 'wave_direction'),
    WxLayer.rain: ('precipitation', null),
    WxLayer.temp: ('temperature_2m', null),
    WxLayer.pressure: ('pressure_msl', null),
  };

  /// Grid of [layer] over the box, for the next 72 hours.
  Future<WeatherGrid> load(WxLayer layer, double south, double west, double north, double east,
      {int size = 9}) async {
    // Snap the box so small moves reuse the same request.
    double snap(double v, double step, bool up) => (up ? (v / step).ceil() : (v / step).floor()) * step;
    final step = math.max(0.05, ((north - south) / (size - 1) * 10).round() / 10);
    south = snap(south, step, false);
    north = snap(north, step, true);
    west = snap(west, step, false);
    east = snap(east, step, true);
    final rows = math.max(2, ((north - south) / step).round() + 1);
    final cols = math.max(2, ((east - west) / step).round() + 1);
    final key = '${layer.name}|$south|$west|$rows|$cols|$step';
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.$1) < const Duration(minutes: 45)) return hit.$2;

    final lats = <String>[], lons = <String>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        lats.add((south + step * r).toStringAsFixed(3));
        lons.add((west + step * c).toStringAsFixed(3));
      }
    }
    final (value, direction) = _hourly[layer]!;
    final marine = layer == WxLayer.waves;
    final uri = Uri.https(marine ? 'marine-api.open-meteo.com' : 'api.open-meteo.com',
        marine ? '/v1/marine' : '/v1/forecast', {
      'latitude': lats.join(','),
      'longitude': lons.join(','),
      'hourly': [value, ?direction].join(','),
      'forecast_days': '3',
      'timezone': 'GMT',
      if (!marine) 'wind_speed_unit': 'kmh',
      // Land points stay empty instead of taking the nearest sea value.
      if (marine) 'cell_selection': 'nearest',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('Open-Meteo ${res.statusCode}');
    final body = jsonDecode(res.body);
    final points = body is List ? body : [body];

    List<double?> series(Map<String, dynamic> p, String name) =>
        [for (final v in (p['hourly'] as Map<String, dynamic>)[name] as List) (v as num?)?.toDouble()];

    final perPoint = [for (final p in points) series(p as Map<String, dynamic>, value)];
    final dirPoint = direction == null
        ? null
        : [for (final p in points) series(p as Map<String, dynamic>, direction)];
    final hours = perPoint.first.length;
    final first = (points.first as Map<String, dynamic>)['hourly']['time'][0] as String;
    final grid = WeatherGrid(
      south: south,
      west: west,
      north: south + step * (rows - 1),
      east: west + step * (cols - 1),
      rows: rows,
      cols: cols,
      start: DateTime.parse('${first}Z'),
      values: [for (var h = 0; h < hours; h++) [for (final s in perPoint) s[h]]],
      directions: dirPoint == null
          ? null
          : [for (var h = 0; h < hours; h++) [for (final s in dirPoint) s[h]]],
    );
    _cache[key] = (DateTime.now(), grid);
    return grid;
  }
}
