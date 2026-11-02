import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:latlong2/latlong.dart' show LatLng;

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/weather_grid.dart';
import '../theme.dart';
import '../widgets/base_map.dart';
import '../widgets/common.dart';
import '../widgets/sub_page.dart';

/// Weather map drawn by the app: colours for the chosen layer, arrows for
/// wind and swell direction, and a slider over the next 72 hours.
class WeatherMapScreen extends StatefulWidget {
  const WeatherMapScreen({super.key});

  @override
  State<WeatherMapScreen> createState() => _WeatherMapScreenState();
}

class _WeatherMapScreenState extends State<WeatherMapScreen> {
  final _controller = MapController();
  final _service = WeatherGridService();
  WxLayer _layer = WxLayer.wind;
  WeatherGrid? _grid;
  bool _loading = false;
  bool _error = false;
  int _hour = 0;
  LatLng? _probe;
  double _loadedZoom = 0;
  int _request = 0;

  /// Hour index of "now" in the grid.
  int get _nowIndex {
    final g = _grid;
    if (g == null) return 0;
    return DateTime.now().toUtc().difference(g.start).inHours.clamp(0, g.values.length - 1);
  }

  Future<void> _load({bool force = false}) async {
    final cam = _controller.camera;
    final b = cam.visibleBounds;
    final g = _grid;
    if (!force &&
        g != null &&
        g.covers(b.south, b.west, b.north, b.east) &&
        (cam.zoom - _loadedZoom).abs() < 1.5) {
      return;
    }
    // A margin around the view, so short pans need no new request.
    final dLat = (b.north - b.south) * 0.25, dLon = (b.east - b.west) * 0.25;
    final id = ++_request;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final grid = await _service.load(_layer, math.max(-85, b.south - dLat), b.west - dLon,
          math.min(85, b.north + dLat), b.east + dLon);
      if (!mounted || id != _request) return;
      final keepOffset = _grid == null ? null : _hour - _nowIndex;
      setState(() {
        _grid = grid;
        _loadedZoom = cam.zoom;
        _hour = (_nowIndex + (keepOffset ?? 0)).clamp(0, grid.values.length - 1);
      });
    } catch (_) {
      if (mounted && id == _request) setState(() => _error = true);
    } finally {
      if (mounted && id == _request) setState(() => _loading = false);
    }
  }

  void _setLayer(WxLayer l) {
    setState(() {
      _layer = l;
      _grid = null;
    });
    _load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final state = AppScope.of(context);
    final labels = {
      WxLayer.wind: t.wind,
      WxLayer.gusts: t.gusts,
      WxLayer.waves: t.waves,
      WxLayer.rain: t.wxRain,
      WxLayer.temp: t.temperature,
      WxLayer.pressure: t.pressure,
    };
    final grid = _grid;
    final scale = wxScales[_layer]!;
    final probeValue = grid == null || _probe == null ? null : grid.at(_probe!, _hour);
    return SubPage(
      title: t.weatherMap,
      body: Column(children: [
        SizedBox(
          height: 58,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            children: [
              for (final l in WxLayer.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: StatusChip(
                    label: labels[l]!,
                    tone: l == _layer ? ChipTone.solid : ChipTone.neutral,
                    onTap: () => _setLayer(l),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(p.radius),
              border: Border.all(color: p.border),
            ),
            child: Stack(children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: state.position,
                    initialZoom: 6,
                    minZoom: 3,
                    maxZoom: 12,
                    onMapReady: () => _load(force: true),
                    onTap: (_, point) => setState(() => _probe = point),
                    onMapEvent: (e) {
                      if (e is MapEventMoveEnd ||
                          e is MapEventFlingAnimationEnd ||
                          e is MapEventDoubleTapZoomEnd ||
                          e is MapEventScrollWheelZoom) {
                        _load();
                      }
                    },
                  ),
                  children: [
                    baseLayer('night'),
                    if (grid != null) _WxLayerWidget(grid: grid, hour: _hour, scale: scale, layer: _layer),
                    ?labelsLayer('night'),
                    if (_probe != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _probe!,
                          width: 18,
                          height: 18,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.black54, width: 2),
                            ),
                          ),
                        ),
                      ]),
                    RichAttributionWidget(
                      showFlutterMapAttribution: false,
                      attributions: baseAttributions('night'),
                    ),
                  ],
                ),
              ),
              if (_probe != null)
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: _Bubble(
                    text: probeValue == null
                        ? '—'
                        : '${_format(probeValue)} ${scale.unit}',
                    color: probeValue == null ? Colors.black54 : scale.color(probeValue),
                    onClose: () => setState(() => _probe = null),
                  ),
                ),
              if (_loading)
                const PositionedDirectional(
                  top: 12,
                  end: 12,
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                ),
              if (_error && grid == null)
                Center(
                  child: _Bubble(text: t.wxMapError, color: Colors.black87, onClose: () => _load(force: true)),
                ),
              // The map stays left-to-right: keep the info button free on the right.
              Positioned(left: 10, right: 48, bottom: 10, child: _Legend(scale: scale)),
            ]),
          ),
        ),
        if (grid != null) _timeBar(t, p, grid),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(t.wxDataNote, style: TextStyle(fontSize: 11.5, color: p.muted)),
        ),
      ]),
    );
  }

  String _format(double v) => switch (_layer) {
        WxLayer.waves || WxLayer.rain => v.toStringAsFixed(1),
        _ => v.round().toString(),
      };

  Widget _timeBar(AppLocalizations t, Palette p, WeatherGrid grid) {
    final lang = Localizations.localeOf(context).languageCode;
    final time = grid.start.add(Duration(hours: _hour)).toLocal();
    final label = _hour == _nowIndex
        ? t.wxNow
        : '${DateFormat.E(lang).format(time)} ${DateFormat.Hm(lang).format(time)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Row(children: [
        SizedBox(
          width: 92,
          child: Text(label, style: p.num(14.5)),
        ),
        Expanded(
          child: Slider(
            value: _hour.toDouble(),
            min: 0,
            max: (grid.values.length - 1).toDouble(),
            divisions: grid.values.length - 1,
            onChanged: (v) => setState(() => _hour = v.round()),
          ),
        ),
      ]),
    );
  }
}

/// Colours and arrows of one hour of a weather grid, over the map.
class _WxLayerWidget extends StatelessWidget {
  const _WxLayerWidget(
      {required this.grid, required this.hour, required this.scale, required this.layer});

  final WeatherGrid grid;
  final int hour;
  final WxScale scale;
  final WxLayer layer;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: IgnorePointer(
        child: CustomPaint(
          size: Size.infinite,
          painter: _WxPainter(camera, grid, hour, scale, layer),
        ),
      ),
    );
  }
}

class _WxPainter extends CustomPainter {
  _WxPainter(this.camera, this.grid, this.hour, this.scale, this.layer);

  final MapCamera camera;
  final WeatherGrid grid;
  final int hour;
  final WxScale scale;
  final WxLayer layer;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 10.0;
    final paint = Paint()..isAntiAlias = false;
    final w = camera.size.width, h = camera.size.height;
    for (var y = 0.0; y < h; y += cell) {
      for (var x = 0.0; x < w; x += cell) {
        final v = grid.at(camera.screenOffsetToLatLng(Offset(x + cell / 2, y + cell / 2)), hour);
        if (v == null) continue;
        final c = scale.color(v);
        paint.color = c.withValues(alpha: c.a * 0.62);
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), paint);
      }
    }
    final dirs = grid.directions;
    if (dirs == null) return;
    final d = dirs[hour.clamp(0, dirs.length - 1)];
    final values = grid.values[hour.clamp(0, grid.values.length - 1)];
    final arrow = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Thin the arrows out when the grid points are close on screen.
    final a = camera.latLngToScreenOffset(grid.point(0, 0));
    final b = camera.latLngToScreenOffset(grid.point(0, 1));
    final every = math.max(1, (34 / math.max(1, (b - a).distance)).ceil());
    for (var r = 0; r < grid.rows; r += every) {
      for (var c = 0; c < grid.cols; c += every) {
        final i = r * grid.cols + c;
        final dir = d[i], v = values[i];
        if (dir == null || v == null) continue;
        final o = camera.latLngToScreenOffset(grid.point(r, c));
        if (o.dx < -20 || o.dy < -20 || o.dx > w + 20 || o.dy > h + 20) continue;
        // Directions are where it comes from: the arrow points downwind.
        final rad = (dir + 180) * math.pi / 180;
        final len = 9.0 + math.min(9.0, v / (layer == WxLayer.waves ? 0.4 : 6));
        final tip = o + Offset(math.sin(rad), -math.cos(rad)) * len;
        final tail = o - Offset(math.sin(rad), -math.cos(rad)) * len;
        canvas.drawLine(tail, tip, arrow);
        for (final side in [-1, 1]) {
          final back = rad + math.pi + side * 0.5;
          canvas.drawLine(tip, tip + Offset(math.sin(back), -math.cos(back)) * 5.5, arrow);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_WxPainter old) =>
      old.camera != camera || old.grid != grid || old.hour != hour || old.layer != layer;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.scale});

  final WxScale scale;

  @override
  Widget build(BuildContext context) {
    final stops = scale.stops;
    final first = stops.first.$1, last = stops.last.$1;
    String f(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [for (final s in stops) s.$2.withAlpha(255)],
                stops: [for (final s in stops) (s.$1 - first) / (last - first)],
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final s in [stops.first, stops[stops.length ~/ 2], stops.last])
              Text(f(s.$1),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            Text(scale.unit, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.color, required this.onClose});

  final String text;
  final Color color;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onClose,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color.withAlpha(255), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}
