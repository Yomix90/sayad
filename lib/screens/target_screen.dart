import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sub_page.dart';
import 'home_screen.dart' show formatCoords;

/// Guides to a spot with only GPS and the compass: no map, no internet.
class TargetScreen extends StatefulWidget {
  const TargetScreen({super.key, required this.name, required this.target});

  final String name;
  final LatLng target;

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  StreamSubscription<Position>? _gps;
  Position? _pos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      if (mounted) setState(() => _error = 'denied');
      return;
    }
    _gps = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best, distanceFilter: 3),
    ).listen((p) => setState(() => _pos = p),
        onError: (_) => setState(() => _error = 'gps'));
  }

  @override
  void dispose() {
    _gps?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final pos = _pos;
    final distance = pos == null
        ? null
        : Geolocator.distanceBetween(
            pos.latitude, pos.longitude, widget.target.latitude, widget.target.longitude);
    final bearing = pos == null
        ? null
        : (Geolocator.bearingBetween(pos.latitude, pos.longitude,
                    widget.target.latitude, widget.target.longitude) +
                360) %
            360;
    final arrived = distance != null && distance < 25;

    return SubPage(
      title: widget.name,
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snap) {
          final heading = snap.data?.heading;
          // Without a compass, point relative to north (phone held north-up).
          final rel = bearing == null ? null : bearing - (heading ?? 0);
          return ListView(padding: const EdgeInsets.all(20), children: [
            AppCard(
              child: Column(children: [
                Text(t.targetDistance, style: TextStyle(color: p.muted)),
                const SizedBox(height: 4),
                Text(
                  distance == null
                      ? '…'
                      : distance >= 1000
                          ? '${(distance / 1000).toStringAsFixed(distance < 10000 ? 2 : 1)} km'
                          : '${distance.round()} m',
                  style: p.num(46, color: arrived ? p.ok : p.text),
                ),
                if (bearing != null)
                  Text('${t.targetBearing} ${bearing.round()}° ${compassPoint(bearing)}',
                      style: TextStyle(color: p.muted)),
              ]),
            ),
            AspectRatio(
              aspectRatio: 1,
              child: Center(
                child: rel == null
                    ? Text(_error == 'denied' ? t.locationDenied : t.waitingGps,
                        textAlign: TextAlign.center, style: TextStyle(color: p.muted))
                    : Directionality(
                        textDirection: TextDirection.ltr,
                        child: AnimatedRotation(
                          turns: rel / 360,
                          duration: const Duration(milliseconds: 250),
                          child: CustomPaint(
                            size: const Size.square(240),
                            painter: _ArrowPainter(arrived ? p.ok : p.accent, p.surface2),
                          ),
                        ),
                      ),
              ),
            ),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.targetSpot, style: TextStyle(color: p.muted, fontSize: 13)),
                Text(formatCoords(widget.target.latitude, widget.target.longitude),
                    style: p.num(15)),
                if (pos != null) ...[
                  const SizedBox(height: 8),
                  Text(t.myPosition, style: TextStyle(color: p.muted, fontSize: 13)),
                  Text(
                      '${formatCoords(pos.latitude, pos.longitude)} · ±${pos.accuracy.round()} m',
                      style: p.num(15)),
                ],
                const SizedBox(height: 10),
                Text(heading == null ? t.targetNoCompass : t.targetHelp,
                    style: TextStyle(fontSize: 13, color: p.muted, height: 1.4)),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color, this.disc);
  final Color color, disc;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = disc);
    final arrow = Path()
      ..moveTo(c.dx, c.dy - r * 0.8)
      ..lineTo(c.dx + r * 0.38, c.dy + r * 0.5)
      ..lineTo(c.dx, c.dy + r * 0.25)
      ..lineTo(c.dx - r * 0.38, c.dy + r * 0.5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = color);
    canvas.drawCircle(Offset(c.dx, c.dy - r * 0.92), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color || old.disc != disc;
}
