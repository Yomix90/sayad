import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/forecast_service.dart';
import '../services/tide_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/line_icons.dart';
import 'city_picker.dart';

/// Tides for the next 7 days: day selector, chart and list.
class TidesScreen extends StatefulWidget {
  const TidesScreen({super.key});

  @override
  State<TidesScreen> createState() => _TidesScreenState();
}

class _TidesScreenState extends State<TidesScreen> {
  int _day = 0;
  Future<(Forecast, TideData)>? _future;
  Object? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pos = AppScope.of(context).position;
    if (pos != _position) {
      _position = pos;
      _future = _load(pos.latitude, pos.longitude);
    }
  }

  static Future<(Forecast, TideData)> _load(double lat, double lon) async {
    final f = await ForecastService().fetch(lat, lon);
    return (f, await TideService().load(lat, lon, f));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    return FutureBuilder<(Forecast, TideData)>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final state = AppScope.of(context);
        final head = ScreenHead(
          title: t.tides,
          trailing: StatusChip(
            label: state.usingGps ? t.myPosition : state.region.name.of(context),
            icon: 'pin',
            onTap: () => showCityPicker(context),
          ),
        );
        if (snap.hasError || snap.data!.$2.heights.isEmpty) {
          return ListView(padding: const EdgeInsets.all(14), children: [
            head,
            AppCard(
              child: Text(snap.hasError ? t.errorLoad : t.noMarineData,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted)),
            ),
          ]);
        }
        return _content(context, snap.data!.$2, head);
      },
    );
  }

  Widget _content(BuildContext context, TideData tide, Widget head) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final hm = DateFormat.Hm(locale);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = today.add(Duration(days: _day));
    final next = day.add(const Duration(days: 1));
    bool inDay(DateTime x) => !x.isBefore(day) && x.isBefore(next);

    final allEvents = tide.extremes;
    final events = allEvents.where((e) => inDay(e.time)).toList();
    final series = [
      for (final (time, level) in tide.heights)
        if (!time.isBefore(day) && !time.isAfter(next))
          (time.difference(day).inMinutes / 60, level),
    ];
    final weekLevels = tide.heights.map((h) => h.$2);
    final lo = weekLevels.reduce(min), hi = weekLevels.reduce(max);
    final precise = tide.source != TideSource.model;
    // Spring / neap: today's range against the other days we have.
    final perDay = <DateTime, (double, double)>{};
    for (final (time, level) in tide.heights) {
      final d = DateTime(time.year, time.month, time.day);
      final r = perDay[d];
      perDay[d] = r == null ? (level, level) : (min(r.$1, level), max(r.$2, level));
    }
    final ranges = perDay.values.map((r) => r.$2 - r.$1).toList();
    final maxRange = ranges.reduce(max), minRange = ranges.reduce(min);
    final range = series.isEmpty
        ? 0.0
        : series.map((s) => s.$2).reduce(max) - series.map((s) => s.$2).reduce(min);
    final upcoming = allEvents.where((e) => e.time.isAfter(now)).firstOrNull;
    final nowLevel = _levelAt(tide.heights, now);

    String fmtM(double v) {
      final s = v.toStringAsFixed(1);
      return locale.startsWith('fr') ? s.replaceAll('.', ',') : s;
    }

    String duration(Duration d) =>
        '${d.inHours} h ${(d.inMinutes % 60).toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      children: [
        head,
        DayChips(
          start: today,
          // A cached Stormglass answer may cover fewer than 7 days ahead.
          count: tide.heights.last.$1.difference(today).inDays.clamp(1, ForecastService.days),
          selected: _day,
          onSelected: (i) => setState(() => _day = i),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CardHead(
              title: DateFormat.MMMMEEEEd(locale).format(day),
              trailing: StatusChip(label: '${t.tidalRange} ${fmtM(range)} m'),
            ),
            AspectRatio(
              aspectRatio: 390 / 205,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: CustomPaint(
                  painter: TideChartPainter(
                    series: series,
                    events: events
                        .map((e) => (
                              e.time.difference(day).inMinutes / 60,
                              e.height,
                              '${e.isHigh ? t.hwShort : t.lwShort} ${hm.format(e.time)}',
                              e.isHigh
                            ))
                        .toList(),
                    lo: lo,
                    hi: hi,
                    now: _day == 0 && nowLevel != null
                        ? (now.hour + now.minute / 60, nowLevel,
                            '${hm.format(now)} · ${fmtM(nowLevel)} m')
                        : null,
                    p: p,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
            if (range >= maxRange * 0.85)
              StatusChip(label: t.springTide, tone: ChipTone.solid, icon: 'waves')
            else if (range <= minRange * 1.15)
              StatusChip(label: t.neapTide, icon: 'waves')
            else
              StatusChip(label: t.midTide, icon: 'waves'),
            StatusChip(
              label: switch (tide.source) {
                TideSource.worldTides => t.tideSourcePrecise,
                TideSource.stormglass when tide.correctedFor != null =>
                  t.tideSourceCorrected(tide.correctedFor!),
                TideSource.stormglass => t.tideSourceUncalibrated,
                TideSource.model => t.tideSourceModel,
              },
              tone: tide.source == TideSource.worldTides || tide.correctedFor != null
                  ? ChipTone.ok
                  : ChipTone.warn,
              icon: tide.source == TideSource.worldTides || tide.correctedFor != null
                  ? 'check'
                  : 'info',
            ),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(p.radiusS),
              ),
              child: Row(children: [
                LineIcon('clock', size: 17, color: p.classic ? p.accent : p.accentInk),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _day == 0 && upcoming != null
                        ? '${t.nextTide} : ${upcoming.isHigh ? t.highTide : t.lowTide} · ${hm.format(upcoming.time)} · ${t.inDuration(duration(upcoming.time.difference(now)))}'
                        : events.map((e) => '${e.isHigh ? t.highTide : t.lowTide} ${hm.format(e.time)}').join(' · '),
                    style: const TextStyle(fontSize: 14.5),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        for (final e in events)
          Stack(clipBehavior: Clip.none, children: [
            AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 64),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: e.isHigh ? p.surface2 : p.warnSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    LineIcon(e.isHigh ? 'up' : 'down',
                        size: 14, color: e.isHigh ? p.accentInk : p.warnInk),
                    const SizedBox(width: 5),
                    Text(e.isHigh ? t.hwShort : t.lwShort,
                        style: p.title(13,
                            color: e.isHigh ? p.accentInk : p.warnInk)),
                  ]),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(hm.format(e.time), style: p.num(28)),
                  ),
                ),
                const Spacer(),
                Text.rich(TextSpan(children: [
                  TextSpan(text: fmtM(e.height), style: p.num(28)),
                  TextSpan(
                      text: ' m',
                      style: TextStyle(fontSize: 15, color: p.muted)),
                ])),
              ]),
            ),
            if (_day == 0 && identical(e, upcoming))
              PositionedDirectional(
                top: -9,
                end: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                      color: p.ok, borderRadius: BorderRadius.circular(99)),
                  child: Text(t.upcoming,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        const SizedBox(height: 4),
        Text(precise ? t.tidesDisclaimerPrecise : t.tidesDisclaimer, style: TextStyle(fontSize: 12.5, color: p.muted)),
        const SizedBox(height: 14),
        const Frieze(),
      ],
    );
  }

  static double? _levelAt(List<(DateTime, double)> pts, DateTime t) {
    for (var i = 0; i < pts.length - 1; i++) {
      final (ta, va) = pts[i];
      final (tb, vb) = pts[i + 1];
      if (!t.isBefore(ta) && t.isBefore(tb)) {
        final f = t.difference(ta).inSeconds / tb.difference(ta).inSeconds;
        return va + (vb - va) * f;
      }
    }
    return null;
  }
}

/// Tide curve with a metre grid, hour labels, labelled high/low markers
/// and an optional pulsing "now" point. Modern: filled area; classic: ink.
class TideChartPainter extends CustomPainter {
  TideChartPainter({
    required this.series,
    required this.events,
    required this.lo,
    required this.hi,
    required this.now,
    required this.p,
  });

  /// (hour of day, level in m).
  final List<(double, double)> series;

  /// (hour, level, label, isHigh).
  final List<(double, double, String, bool)> events;
  final double lo, hi;
  final (double, double, String)? now;
  final Palette p;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    canvas.scale(size.width / 390);
    // Plot area in a 390×205 box.
    const left = 36.0, right = 380.0, top = 18.0, bottom = 150.0;
    final step = (hi - lo) > 2.5 ? 1.0 : 0.5;
    final gLo = (lo / step).floor() * step, gHi = (hi / step).ceil() * step;
    double x(double h) => left + h / 24 * (right - left);
    double y(double v) => bottom - (v - gLo) / (gHi - gLo) * (bottom - top);

    final grid = Paint()
      ..color = p.border
      ..strokeWidth = 1;
    final labelStyle = p.num(10.5, weight: FontWeight.w500, color: p.muted);
    for (var v = gLo; v <= gHi + 1e-6; v += step) {
      canvas.drawLine(Offset(left, y(v)), Offset(right, y(v)), grid);
      _text(canvas, '${v.toStringAsFixed(step < 1 ? 1 : 0)} m', labelStyle,
          Offset(left - 6, y(v)), align: 1);
    }
    for (final h in [0, 6, 12, 18, 24]) {
      _text(canvas, '${h.toString().padLeft(2, '0')}:00', labelStyle,
          Offset(x(h.toDouble()), 170), align: 0.5);
    }

    // Smooth curve through the hourly points (Catmull-Rom).
    final pts = [for (final (h, v) in series) Offset(x(h), y(v))];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1];
      final p3 = pts[min(pts.length - 1, i + 2)];
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx, p2.dy,
      );
    }
    if (!p.classic) {
      final area = Path.from(path)
        ..lineTo(pts.last.dx, bottom)
        ..lineTo(pts.first.dx, bottom)
        ..close();
      canvas.drawPath(area, Paint()..color = p.accent.withValues(alpha: 0.14));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = p.classic ? const Color(0xFF33220F) : p.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = p.classic ? 2.4 : 3
        ..strokeCap = StrokeCap.round,
    );

    for (final (h, v, label, high) in events) {
      final c = Offset(x(h), y(v));
      canvas.drawCircle(c, 4.5, Paint()..color = p.surface);
      canvas.drawCircle(
          c,
          4.5,
          Paint()
            ..color = p.classic ? const Color(0xFF33220F) : p.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      _text(canvas, label, p.num(11.5),
          Offset(c.dx, high ? c.dy - 14 : c.dy + 16), align: 0.5, clampTo: (left, right));
    }

    if (now != null) {
      final (h, v, label) = now!;
      final c = Offset(x(h), y(v));
      final dash = Paint()
        ..color = p.danger
        ..strokeWidth = 1.6;
      for (var yy = c.dy; yy < bottom; yy += 8) {
        canvas.drawLine(Offset(c.dx, yy), Offset(c.dx, min(yy + 4, bottom)), dash);
      }
      canvas.drawCircle(c, 6, Paint()..color = p.danger);
      // Label at the foot of the dashed line, clear of the high/low labels.
      final rightSide = c.dx < (left + right) / 2;
      _text(canvas, label, p.num(11.5, color: p.danger),
          Offset(c.dx + (rightSide ? 6 : -6), bottom - 9),
          align: rightSide ? 0 : 1, clampTo: (left, right));
    }
  }

  void _text(Canvas canvas, String s, TextStyle style, Offset at,
      {double align = 0, (double, double)? clampTo}) {
    final tp = TextPainter(
        text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)
      ..layout();
    var dx = at.dx - tp.width * align;
    if (clampTo != null) {
      dx = dx.clamp(clampTo.$1 - 30, clampTo.$2 - tp.width + 8).toDouble();
    }
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(TideChartPainter old) =>
      old.series != series || old.now != now || old.p != p;
}
