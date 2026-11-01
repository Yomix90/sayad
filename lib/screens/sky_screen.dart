import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/astro.dart';
import '../services/ephemeris.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sub_page.dart';
import 'home_screen.dart' show moonPhaseName;

/// Where the Sun and Moon are in the sky now, and their path today.
class SkyScreen extends StatelessWidget {
  const SkyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final pos = AppScope.of(context).position;
    final lat = pos.latitude, lon = pos.longitude;
    final hm = DateFormat.Hm(Localizations.localeOf(context).toString());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<(double, double, DateTime)> path(SkyBody Function(DateTime) body) => [
          for (var m = 0; m <= 24 * 60; m += 15)
            () {
              final at = today.add(Duration(minutes: m));
              final (alt, az) = altAz(body(at), lat, lon, at);
              return (alt, az, at);
            }(),
        ];
    final sunPath = path(sunAt), moonPath = path(moonAt);
    final (sunAlt, sunAz) = altAz(sunAt(now), lat, lon, now);
    final moonNow = moonAt(now);
    final (moonAlt, moonAz) = altAz(moonNow, lat, lon, now);
    final (sunRise, sunSet) = sunRiseSet(lat, lon, today);
    final (moonRise, moonSet) = moonRiseSetExact(lat, lon, today);
    final moon = moonInfo(now);
    String time(DateTime? d) => d == null ? '—' : hm.format(d);
    String dir(double az) => '${az.round()}° ${compassPoint(az)}';

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(label, style: TextStyle(color: p.muted))),
            Text(value, style: p.num(15)),
          ]),
        );

    return SubPage(
      title: t.sky,
      body: ListView(padding: const EdgeInsets.all(14), children: [
        AppCard(
          child: Column(children: [
            CardHead(title: t.skyNow, trailing: StatusChip(label: hm.format(now), icon: 'clock')),
            AspectRatio(
              aspectRatio: 1,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: CustomPaint(
                  painter: _SkyPainter(
                    p: p,
                    sunPath: sunPath,
                    moonPath: moonPath,
                    sun: (sunAlt, sunAz),
                    moon: (moonAlt, moonAz),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(t.skyHelp, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: p.muted)),
          ]),
        ),
        AppCard(
          child: Column(children: [
            CardHead(title: t.sun),
            row(t.rise, time(sunRise)),
            row(t.set, time(sunSet)),
            row(t.skyHeight, '${sunAlt.toStringAsFixed(1)}°'),
            row(t.skyDirection, dir(sunAz)),
          ]),
        ),
        AppCard(
          child: Column(children: [
            CardHead(
              title: t.moon,
              trailing: StatusChip(label: '${moonPhaseName(t, moon.phase)} · ${(moon.illumination * 100).round()} %'),
            ),
            row(t.rise, time(moonRise)),
            row(t.set, time(moonSet)),
            row(t.skyHeight, '${moonAlt.toStringAsFixed(1)}°'),
            row(t.skyDirection, dir(moonAz)),
            row(t.skyDistance, '${(moonNow.distanceKm / 1000).round()} 000 km'),
            if (moonNow.distanceKm < 362000)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: StatusChip(label: t.perigee, tone: ChipTone.warn, icon: 'moon'),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// Polar sky chart: horizon as the outer circle, zenith in the centre,
/// north up. Paths are drawn while above the horizon.
class _SkyPainter extends CustomPainter {
  _SkyPainter({
    required this.p,
    required this.sunPath,
    required this.moonPath,
    required this.sun,
    required this.moon,
  });

  final Palette p;
  final List<(double, double, DateTime)> sunPath, moonPath;
  final (double, double) sun, moon;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 18;
    Offset at(double alt, double az) {
      final d = r * (90 - alt.clamp(0, 90)) / 90;
      return c + Offset(sin(az * pi / 180), -cos(az * pi / 180)) * d;
    }

    canvas.drawCircle(c, r, Paint()..color = p.surface2);
    final ring = Paint()
      ..color = p.border
      ..style = PaintingStyle.stroke;
    for (final a in [30.0, 60.0]) {
      canvas.drawCircle(c, r * (90 - a) / 90, ring);
    }
    canvas.drawCircle(c, r, ring..strokeWidth = 1.5);
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final (label, az) in [('N', 0.0), ('E', 90.0), ('S', 180.0), ('W', 270.0)]) {
      tp.text = TextSpan(
          text: label,
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: label == 'N' ? p.danger : p.muted,
              fontSize: 13));
      tp.layout();
      final o = c + Offset(sin(az * pi / 180), -cos(az * pi / 180)) * (r + 10);
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }

    void track(List<(double, double, DateTime)> pts, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      Path? path;
      for (final (alt, az, _) in pts) {
        if (alt < 0) {
          if (path != null) canvas.drawPath(path, paint);
          path = null;
          continue;
        }
        final o = at(alt, az);
        path == null ? path = (Path()..moveTo(o.dx, o.dy)) : path.lineTo(o.dx, o.dy);
      }
      if (path != null) canvas.drawPath(path, paint);
    }

    track(sunPath, p.warn);
    track(moonPath, p.muted);

    if (sun.$1 > 0) {
      final o = at(sun.$1, sun.$2);
      canvas.drawCircle(o, 11, Paint()..color = p.warn);
      canvas.drawCircle(o, 15, Paint()..color = p.warn.withValues(alpha: 0.25));
    }
    if (moon.$1 > 0) {
      final o = at(moon.$1, moon.$2);
      canvas.drawCircle(o, 9, Paint()..color = p.moonLit);
      canvas.drawCircle(o, 9, Paint()
        ..color = p.muted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.sun != sun || old.moon != moon || old.p != p;
}
