import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/astro.dart';
import '../services/hijri.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sub_page.dart';

class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final hm = DateFormat.Hm(locale);
    final pos = state.position;
    final times = prayerTimes(pos.latitude, pos.longitude);
    final qibla = qiblaDirection(pos.latitude, pos.longitude);
    final now = DateTime.now();

    final p = Palette.of(context);
    final rows = [
      (t.fajr, times.fajr, Icons.nights_stay_outlined),
      (t.sunrisePrayer, times.sunrise, Icons.wb_twilight),
      (t.dhuhr, times.dhuhr, Icons.wb_sunny_outlined),
      (t.asr, times.asr, Icons.light_mode_outlined),
      (t.maghrib, times.maghrib, Icons.wb_twilight),
      (t.isha, times.isha, Icons.dark_mode_outlined),
    ];
    final next = rows.where((r) => r.$2.isAfter(now)).firstOrNull;
    final ink = p.classic ? p.accent : p.accentInk;

    return SubPage(
      title: t.tabPrayer,
      body: ListView(padding: const EdgeInsets.all(14), children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CardHead(
              title: t.prayerTimes,
              trailing: StatusChip(label: DateFormat.MMMEd(locale).format(now)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: StatusChip(
                label: formatHijri(now, Localizations.localeOf(context).languageCode,
                    offsetDays: state.hijriOffset),
                icon: 'moon',
              ),
            ),
            for (final r in rows)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: r == next ? p.surface2 : null,
                  border: Border.all(
                      color: r == next ? p.accent : Colors.transparent),
                  borderRadius: BorderRadius.circular(p.radiusS),
                ),
                child: Row(children: [
                  Icon(r.$3, color: ink, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(r.$1,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                r == next ? FontWeight.w800 : FontWeight.w500)),
                  ),
                  if (r == next)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: StatusChip(label: t.upcoming, tone: ChipTone.ok),
                    ),
                  Text(hm.format(r.$2), style: p.num(22)),
                ]),
              ),
          ]),
        ),
        AppCard(
          child: Column(children: [
            CardHead(title: t.qibla),
            SizedBox(
              width: 180,
              height: 180,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: CustomPaint(
                  painter: _CompassPainter(qibla, Theme.of(context).colorScheme),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(t.qiblaDegrees(qibla.toStringAsFixed(1)), style: p.num(18, color: ink)),
          ]),
        ),
      ]),
    );
  }
}

/// Static compass rose (north up) with the qibla bearing.
class _CompassPainter extends CustomPainter {
  _CompassPainter(this.bearing, this.scheme);

  final double bearing;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = scheme.surfaceContainerHighest);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = scheme.outline
          ..style = PaintingStyle.stroke);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final (label, deg) in [('N', 0), ('E', 90), ('S', 180), ('W', 270)]) {
      tp.text = TextSpan(
          text: label,
          style: TextStyle(
              color: label == 'N' ? Colors.red : scheme.onSurfaceVariant,
              fontWeight: FontWeight.bold));
      tp.layout();
      final a = deg * pi / 180;
      final p = c + Offset(sin(a), -cos(a)) * (r - 14);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    final a = bearing * pi / 180;
    final tip = c + Offset(sin(a), -cos(a)) * (r - 28);
    canvas.drawLine(
        c,
        tip,
        Paint()
          ..color = scheme.primary
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(tip, 8, Paint()..color = scheme.primary);
    canvas.drawCircle(c, 5, Paint()..color = scheme.onSurface);
  }

  @override
  bool shouldRepaint(_CompassPainter old) => old.bearing != bearing;
}
