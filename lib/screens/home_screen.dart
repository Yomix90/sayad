import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:latlong2/latlong.dart' show LatLng;

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/astro.dart';
import '../services/ephemeris.dart';
import '../services/forecast_service.dart';
import '../services/widget_service.dart';
import '../services/hijri.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/line_icons.dart';
import 'city_picker.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ForecastView(
      key: ValueKey(state.position),
      position: state.position,
      header: const _LocationRow(),
      feedsWidget: true,
    );
  }
}

/// Place name with its region, or "My position" with coordinates.
class _LocationRow extends StatelessWidget {
  const _LocationRow();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final t = AppLocalizations.of(context);
    final state = AppScope.of(context);
    final pos = state.position;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(p.radiusS),
              onTap: () => showCityPicker(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  LineIcon('pin', size: 22, color: p.classic ? p.accent : p.accentInk),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Flexible(
                              child: Text(
                                  state.usingGps
                                      ? t.myPosition
                                      : state.region.name.of(context),
                                  overflow: TextOverflow.ellipsis,
                                  style: p.title(19)),
                            ),
                            Icon(Icons.expand_more, color: p.muted),
                          ]),
                          Text(
                              state.usingGps
                                  ? formatCoords(pos.latitude, pos.longitude)
                                  : '${t.morocco} · ${formatCoords(pos.latitude, pos.longitude)}',
                              style: TextStyle(fontSize: 13.5, color: p.muted)),
                        ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
        if (state.locationDenied && state.usingGps)
          StatusChip(
            label: t.gpsOff,
            tone: ChipTone.warn,
            icon: 'cross',
            onTap: state.locate,
          )
        else if (state.usingGps)
          StatusChip(label: t.gpsOn, tone: ChipTone.ok, icon: 'check'),
      ]),
    );
  }
}

String formatCoords(double lat, double lon) =>
    '\u2066${lat.abs().toStringAsFixed(3)} ${lat >= 0 ? 'N' : 'S'} · '
    '${lon.abs().toStringAsFixed(3)} ${lon >= 0 ? 'E' : 'W'}\u2069';

/// Full forecast for one point: fishing index, solunar strip, weather
/// tiles, sun and moon.
class ForecastView extends StatefulWidget {
  const ForecastView(
      {super.key, required this.position, this.header, this.feedsWidget = false});

  final LatLng position;
  final Widget? header;

  /// The home screen's view also refreshes the Android home-screen widget.
  final bool feedsWidget;

  @override
  State<ForecastView> createState() => _ForecastViewState();
}

class _ForecastViewState extends State<ForecastView> {
  late Future<Forecast> _future;
  bool _widgetSent = false;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Forecast> _fetch({bool refresh = false}) => ForecastService().fetch(
      widget.position.latitude, widget.position.longitude,
      refresh: refresh);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder<Forecast>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return ListView(padding: const EdgeInsets.all(14), children: [
            ?widget.header,
            AppCard(
              child: Column(children: [
                Text(t.errorLoad, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      setState(() => _future = _fetch(refresh: true)),
                  child: Text(t.retry),
                ),
              ]),
            ),
          ]);
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _fetch(refresh: true));
            await _future;
          },
          child: _content(context, snap.data!),
        );
      },
    );
  }

  Widget _content(BuildContext context, Forecast f) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final hm = DateFormat.Hm(locale);
    final now = DateTime.now();
    final lat = widget.position.latitude, lon = widget.position.longitude;
    final moon = moonInfo(now);
    final sun = prayerTimes(lat, lon);
    final score = (fishingIndex(f, moon, sun, now) * 10).round();
    final periods = solunarPeriods(lat, lon, now);
    final (moonRise, moonSet) = moonRiseSetExact(lat, lon, now);

    final (condLabel, condTone) = score < 40
        ? (t.condPoor, ChipTone.danger)
        : score < 60
            ? (t.condFair, ChipTone.warn)
            : score < 80
                ? (t.condGood, ChipTone.ok)
                : (t.condExcellent, ChipTone.ok);

    final current = periods
        .where((x) => x.major && !now.isBefore(x.start) && now.isBefore(x.end))
        .firstOrNull;
    final next = periods.where((x) => x.major && x.start.isAfter(now)).firstOrNull;
    if (widget.feedsWidget && !_widgetSent) {
      _widgetSent = true;
      final state = AppScope.of(context);
      updateHomeWidget(
        t: t,
        locale: locale,
        place: state.usingGps ? t.myPosition : state.region.name.of(context),
        forecast: f,
        score: score,
        scoreLabel: condLabel,
        lat: lat,
        lon: lon,
      );
    }
    final note = current != null
        ? t.majorNow(hm.format(current.end))
        : next != null
            ? t.nextMajor('${hm.format(next.start)} – ${hm.format(next.end)}')
            : t.indexNote;

    final trend = f.pressureTrend;
    final trendText = trend > 0.5
        ? t.pressureRising(trend.toStringAsFixed(1))
        : trend < -0.5
            ? t.pressureFalling(trend.abs().toStringAsFixed(1))
            : t.pressureSteady;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      children: [
        ?widget.header,
        AppCard(
          child: Column(children: [
            CardHead(
              title: t.fishingIndex,
              trailing: StatusChip(label: condLabel, tone: condTone, dot: true),
            ),
            FishingGauge(score: score),
            const SizedBox(height: 10),
            Text(note,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, color: p.muted, height: 1.45)),
          ]),
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CardHead(
              title: t.solunarTable,
              trailing: StatusChip(label: t.h24),
            ),
            SolunarStrip(
              periods: periods,
              day: now,
              sunrise: sun.sunrise,
              sunset: sun.maghrib,
              moonRise: moonRise ?? now.subtract(const Duration(days: 2)),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 16, runSpacing: 6, children: [
              _Legend(color: p.bandMajor, label: t.majorPeriod),
              _Legend(color: p.bandMinor, label: t.minorPeriod),
            ]),
          ]),
        ),
        TileGrid(
          children: [
            StatTile(
              icon: 'wind',
              label: t.wind,
              value: '${f.windSpeed.round()}',
              unit: t.kmh,
              sub: '${compassPoint(f.windDirection)} · ${t.gusts.toLowerCase()} ${f.windGusts.round()} ${t.kmh}',
            ),
            StatTile(
              icon: 'waves',
              label: t.swell,
              value: f.waveHeight == null
                  ? '–'
                  : _decimal(context, f.waveHeight!),
              unit: f.waveHeight == null ? null : t.meters,
              sub: f.wavePeriod == null
                  ? t.noMarineShort
                  : '${t.wavePeriod} ${f.wavePeriod!.round()} ${t.seconds}${f.waveDirection == null ? '' : ' · ${compassPoint(f.waveDirection!)}'}',
            ),
            StatTile(
              icon: 'thermo',
              label: t.waterTemp,
              value: f.seaTemperature == null ? '–' : '${f.seaTemperature!.round()}',
              unit: f.seaTemperature == null ? null : '°C',
              sub: t.surfaceTemp,
            ),
            StatTile(
              icon: 'gauge',
              label: t.pressure,
              value: '${f.pressure.round()}',
              unit: t.hpa,
              sub: trendText,
            ),
            StatTile(
              icon: 'sun',
              label: t.airTemp,
              value: '${f.temperature.round()}',
              unit: '°C',
              sub: '${t.humidity} ${f.humidity.round()} %',
            ),
            StatTile(
              icon: 'cloud',
              label: t.weather,
              value: _weatherShort(t, f.weatherCode),
              sub: '${t.gusts} ${f.windGusts.round()} ${t.kmh}',
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Frieze(),
        AppCard(
          child: Column(children: [
            CardHead(
              title: t.sunMoon,
              trailing: StatusChip(label: t.tabToday, icon: 'clock'),
            ),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: _SunMoonColumn(
                    icon: 'sun',
                    title: t.sun,
                    rows: [
                      (t.rise, hm.format(sun.sunrise)),
                      (t.set, hm.format(sun.maghrib)),
                    ],
                  ),
                ),
                VerticalDivider(color: p.border, width: 20),
                Expanded(
                  child: _SunMoonColumn(
                    icon: 'moon',
                    title: t.moon,
                    rows: [
                      (t.rise, moonRise == null ? '—' : hm.format(moonRise)),
                      (t.set, moonSet == null ? '—' : hm.format(moonSet)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF0A2540).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: MoonIcon(age: moon.age, size: 76),
            ),
            const SizedBox(height: 6),
            Text('${(moon.illumination * 100).round()} %', style: p.num(14)),
            Text(moonPhaseName(t, moon.phase),
                style: TextStyle(fontSize: 13, color: p.muted)),
            const SizedBox(height: 10),
            StatusChip(
              label: formatHijri(now, Localizations.localeOf(context).languageCode,
                  offsetDays: AppScope.of(context).hijriOffset),
              icon: 'moon',
            ),
          ]),
        ),
      ],
    );
  }

  static String _decimal(BuildContext context, double v) {
    final s = v.toStringAsFixed(1);
    return Localizations.localeOf(context).languageCode == 'fr'
        ? s.replaceAll('.', ',')
        : s;
  }

  static String _weatherShort(AppLocalizations t, int code) {
    if (code <= 1) return t.wxClear;
    if (code <= 3) return t.wxCloudy;
    if (code <= 48) return t.wxFog;
    if (code <= 67 || (code >= 80 && code <= 82)) return t.wxRain;
    if (code <= 77 || code == 85 || code == 86) return t.wxSnow;
    return t.wxStorm;
  }
}

String moonPhaseName(AppLocalizations t, MoonPhase p) => switch (p) {
      MoonPhase.newMoon => t.moonNew,
      MoonPhase.waxingCrescent => t.moonWaxingCrescent,
      MoonPhase.firstQuarter => t.moonFirstQuarter,
      MoonPhase.waxingGibbous => t.moonWaxingGibbous,
      MoonPhase.full => t.moonFull,
      MoonPhase.waningGibbous => t.moonWaningGibbous,
      MoonPhase.lastQuarter => t.moonLastQuarter,
      MoonPhase.waningCrescent => t.moonWaningCrescent,
    };

class _SunMoonColumn extends StatelessWidget {
  const _SunMoonColumn(
      {required this.icon, required this.title, required this.rows});
  final String icon;
  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        LineIcon(icon, size: 17, color: p.warn),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: p.muted)),
      ]),
      const SizedBox(height: 8),
      for (final (label, value) in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14.5))),
            Text(value, style: p.num(16)),
          ]),
        ),
    ]);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 12,
        height: 12,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 13.5, color: p.muted)),
    ]);
  }
}

/// Semicircle gauge from 0 to 100: arc + dot (modern) or barometer
/// needle (classic). Grows and counts up when shown.
class FishingGauge extends StatelessWidget {
  const FishingGauge({super.key, required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? score / 100 : 0, end: score / 100),
      duration: const Duration(milliseconds: 1100),
      curve: const Cubic(0.3, 0.7, 0.3, 1),
      builder: (context, v, _) => SizedBox(
        width: 250,
        child: AspectRatio(
          aspectRatio: 220 / 132,
          child: Stack(children: [
            Positioned.fill(
              child: CustomPaint(painter: _GaugePainter(v, p)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 2,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${(v * 100).round()}', style: p.num(46)),
                    TextSpan(
                        text: '/100',
                        style: p.num(16, weight: FontWeight.w500, color: p.muted)),
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.value, this.p);
  final double value;
  final Palette p;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 220;
    canvas.scale(s);
    const c = Offset(110, 110);
    const r = 86.0;
    final rect = Rect.fromCircle(center: c, radius: r);
    final bg = Paint()
      ..color = p.surface2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, bg);
    final val = Paint()
      ..color = p.classic ? p.primary.withValues(alpha: 0.35) : p.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    if (value > 0) canvas.drawArc(rect, pi, pi * value, false, val);

    for (var i = 0; i <= 20; i++) {
      final th = pi * (1 - i / 20);
      final major = i % 5 == 0;
      final r2 = major ? 103.0 : 98.0;
      canvas.drawLine(
        Offset(110 + 92 * cos(th), 110 - 92 * sin(th)),
        Offset(110 + r2 * cos(th), 110 - r2 * sin(th)),
        Paint()
          ..color = p.classic ? p.muted.withValues(alpha: 0.7) : p.border
          ..strokeWidth = major ? 2.4 : 1.3,
      );
    }

    final th = pi * (1 - value);
    if (p.classic) {
      canvas.drawLine(
        c,
        Offset(110 + 72 * cos(th), 110 - 72 * sin(th)),
        Paint()
          ..color = p.danger
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(c, 6, Paint()..color = p.accent);
    } else {
      final dot = Offset(110 + r * cos(th), 110 - r * sin(th));
      canvas.drawCircle(dot, 9, Paint()..color = p.surface);
      canvas.drawCircle(dot, 6, Paint()..color = p.accent);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value || old.p != p;
}

/// 24-hour strip with major/minor solunar bands, sun and moon markers and
/// the current time.
class SolunarStrip extends StatelessWidget {
  const SolunarStrip({
    super.key,
    required this.periods,
    required this.day,
    required this.sunrise,
    required this.sunset,
    required this.moonRise,
  });

  final List<SolunarPeriod> periods;
  final DateTime day;
  final DateTime sunrise, sunset, moonRise;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    double hours(DateTime d) => d.hour + d.minute / 60;
    final start = DateTime(day.year, day.month, day.day);
    final now = DateTime.now();
    final isToday =
        now.year == day.year && now.month == day.month && now.day == day.day;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          double x(DateTime d) =>
              (w * d.difference(start).inMinutes / 60 / 24).clamp(0, w).toDouble();
          return Stack(children: [
            for (final b in periods)
              Positioned(
                left: x(b.start),
                width: x(b.end) - x(b.start),
                top: 10,
                height: 26,
                child: Container(
                  decoration: BoxDecoration(
                    color: b.major ? p.bandMajor : p.bandMinor,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            for (final (d, icon) in [
              (sunrise, 'sun'),
              (sunset, 'sun'),
              if (moonRise.day == day.day) (moonRise, 'moon'),
            ])
              Positioned(
                left: x(d) - 7,
                top: 38,
                child: LineIcon(icon, size: 14, color: p.warnInk),
              ),
            if (isToday) ...[
              Positioned(
                left: w * hours(now) / 24 - 1,
                top: 4,
                bottom: 18,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                      color: p.danger, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Positioned(
                left: w * hours(now) / 24 - 4,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: p.danger, shape: BoxShape.circle),
                ),
              ),
            ],
            Positioned(
              left: 8,
              right: 8,
              bottom: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final h in ['00', '06', '12', '18', '24'])
                    Text(h,
                        style: p.num(11, weight: FontWeight.w500, color: p.muted)),
                ],
              ),
            ),
          ]);
        }),
      ),
    );
  }
}
