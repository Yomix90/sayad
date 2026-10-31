import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/astro.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sub_page.dart';

/// Live compass rose (rotates with the phone) with the qibla bearing.
class CompassScreen extends StatelessWidget {
  const CompassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pos = AppScope.of(context).position;
    final qibla = qiblaDirection(pos.latitude, pos.longitude);
    final scheme = Theme.of(context).colorScheme;

    final p = Palette.of(context);
    return SubPage(
      title: t.compass,
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snap) {
          final heading = snap.data?.heading;
          final noSensor = FlutterCompass.events == null ||
              (snap.connectionState == ConnectionState.active && heading == null);
          final h = heading ?? 0;
          final toQibla = ((qibla - h) % 360 + 360) % 360;
          final aligned = heading != null && (toQibla < 5 || toQibla > 355);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Text('${h.round()}° ${_cardinal(h)}',
                    style: p.num(40)),
              ),
              const SizedBox(height: 24),
              AspectRatio(
                aspectRatio: 1,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Stack(alignment: Alignment.center, children: [
                    Transform.rotate(
                      angle: -h * pi / 180,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _RosePainter(qibla, scheme),
                      ),
                    ),
                    // Fixed marker at the top: where the phone points.
                    Align(
                      alignment: Alignment.topCenter,
                      child: Icon(Icons.arrow_drop_down,
                          size: 48, color: scheme.error),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              AppCard(
                padding: EdgeInsets.zero,
                color: aligned ? p.okSoft : null,
                borderColor: aligned ? p.ok : null,
                child: ListTile(
                  leading: Icon(Icons.mosque,
                      color: aligned ? scheme.primary : null),
                  title: Text(t.qibla),
                  subtitle: Text(t.qiblaDegrees(qibla.toStringAsFixed(1))),
                  trailing: aligned
                      ? Icon(Icons.check_circle, color: scheme.primary)
                      : null,
                ),
              ),
              if (noSensor)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t.noCompassSensor, textAlign: TextAlign.center),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(t.compassHelp,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _cardinal(double deg) {
    const names = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return names[((deg % 360) / 45).round() % 8];
  }
}

class _RosePainter extends CustomPainter {
  _RosePainter(this.qibla, this.scheme);

  final double qibla;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 8;
    canvas.drawCircle(c, r, Paint()..color = scheme.surfaceContainerHigh);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = scheme.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    final tick = Paint()..color = scheme.onSurfaceVariant;
    for (var d = 0; d < 360; d += 5) {
      final a = d * pi / 180;
      final len = d % 30 == 0 ? 14.0 : 6.0;
      tick.strokeWidth = d % 30 == 0 ? 2 : 1;
      final dir = Offset(sin(a), -cos(a));
      canvas.drawLine(c + dir * r, c + dir * (r - len), tick);
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final (label, deg) in [('N', 0), ('E', 90), ('S', 180), ('W', 270)]) {
      tp.text = TextSpan(
          text: label,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: label == 'N' ? scheme.error : scheme.onSurface));
      tp.layout();
      final a = deg * pi / 180;
      final p = c + Offset(sin(a), -cos(a)) * (r - 36);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    // Qibla needle.
    final a = qibla * pi / 180;
    final dir = Offset(sin(a), -cos(a));
    canvas.drawLine(
        c,
        c + dir * (r - 60),
        Paint()
          ..color = scheme.primary
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
    final kaaba = c + dir * (r - 60);
    canvas.drawRect(Rect.fromCenter(center: kaaba, width: 18, height: 18),
        Paint()..color = scheme.onSurface);
    canvas.drawCircle(c, 7, Paint()..color = scheme.onSurface);
  }

  @override
  bool shouldRepaint(_RosePainter old) => old.qibla != qibla;
}
