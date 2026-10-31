import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/forecast_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/line_icons.dart';
import 'city_picker.dart';

/// Marine forecast: best window of the day and a 3-hourly table.
class ForecastTableScreen extends StatefulWidget {
  const ForecastTableScreen({super.key});

  @override
  State<ForecastTableScreen> createState() => _ForecastTableScreenState();
}

class _ForecastTableScreenState extends State<ForecastTableScreen> {
  int _day = 0;
  Future<Forecast>? _future;
  Object? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pos = AppScope.of(context).position;
    if (pos != _position) {
      _position = pos;
      _future = ForecastService().fetch(pos.latitude, pos.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = AppScope.of(context);
    final head = ScreenHead(
      title: t.marineForecast,
      trailing: StatusChip(
        label: state.usingGps ? t.myPosition : state.region.name.of(context),
        icon: 'pin',
        onTap: () => showCityPicker(context),
      ),
    );
    return FutureBuilder<Forecast>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return ListView(padding: const EdgeInsets.all(14), children: [
            head,
            AppCard(
              child: Column(children: [
                Text(t.errorLoad, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(() => _future = ForecastService()
                      .fetch(state.position.latitude, state.position.longitude,
                          refresh: true)),
                  child: Text(t.retry),
                ),
              ]),
            ),
          ]);
        }
        return _content(context, snap.data!, head);
      },
    );
  }

  Widget _content(BuildContext context, Forecast f, Widget head) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final hm = DateFormat.Hm(locale);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = today.add(Duration(days: _day));
    final next = day.add(const Duration(days: 1));
    final hours = f.hourly
        .where((h) => !h.time.isBefore(day) && h.time.isBefore(next))
        .toList();
    final rows = hours.where((h) => h.time.hour % 3 == 0).toList();
    final best = _bestWindow(hours, now);

    final seaLabels = [t.calm, t.moderate, t.rough];
    String fmt(double v) {
      final s = v.toStringAsFixed(1);
      return locale.startsWith('fr') ? s.replaceAll('.', ',') : s;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      children: [
        head,
        DayChips(
          start: today,
          count: ForecastService.days,
          selected: _day,
          onSelected: (i) => setState(() => _day = i),
        ),
        const SizedBox(height: 12),
        if (best != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: best.$3 == 0 ? p.okSoft : p.warnSoft,
              borderRadius: BorderRadius.circular(p.radiusS),
            ),
            child: Row(children: [
              LineIcon('check',
                  size: 18, color: best.$3 == 0 ? p.okInk : p.warnInk),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  t.bestWindow('${hm.format(best.$1)} – ${hm.format(best.$2)}',
                      seaLabels[best.$3].toLowerCase()),
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: best.$3 == 0 ? p.okInk : p.warnInk),
                ),
              ),
            ]),
          ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _header(context, [t.hour, t.wind, t.swell, t.sea]),
            for (final h in rows)
              _dataRow(context, h, seaLabels, fmt,
                  past: h.time.isBefore(now.subtract(const Duration(hours: 3)))),
          ]),
        ),
        Wrap(spacing: 10, runSpacing: 8, children: [
          for (var i = 0; i < 3; i++) SeaPill(state: i, label: seaLabels[i]),
        ]),
        const SizedBox(height: 16),
        const Frieze(),
      ],
    );
  }

  // Column flex: hour, wind (+ gusts), swell, sea state.
  static const _flex = [20, 30, 27, 33];

  Widget _header(BuildContext context, List<String> cells) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 10, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border, width: 1.5)),
      ),
      child: Row(children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: _flex[i],
            child: Text(cells[i].toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                    color: p.muted)),
          ),
      ]),
    );
  }

  Widget _dataRow(BuildContext context, HourPoint h, List<String> seaLabels,
      String Function(double) fmt,
      {required bool past}) {
    final p = Palette.of(context);
    final t = AppLocalizations.of(context);
    final state = seaState(h.windSpeed, h.waveHeight);
    final small = TextStyle(fontSize: 12.5, color: p.muted);
    return Opacity(
      opacity: past ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(13, 9, 10, 9),
        decoration: BoxDecoration(
          border: BorderDirectional(
            bottom: BorderSide(color: p.border),
            start: BorderSide(
                color: state == 2 ? p.danger : Colors.transparent, width: 3),
          ),
        ),
        child: Row(children: [
          Expanded(
            flex: _flex[0],
            child: Text(
                DateFormat.Hm(Localizations.localeOf(context).toString())
                    .format(h.time),
                style: p.num(15.5)),
          ),
          Expanded(
            flex: _flex[1],
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                WindArrow(
                    degrees: h.windDirection,
                    size: 17,
                    color: p.classic ? p.primary : p.accentInk),
                const SizedBox(width: 5),
                Text('${h.windSpeed.round()}',
                    style: p.num(16, weight: FontWeight.w600)),
                Flexible(
                  child: Text(' ${compassPoint(h.windDirection)}',
                      overflow: TextOverflow.clip, style: small),
                ),
              ]),
              Text('${t.gusts} ${h.windGusts.round()}',
                  overflow: TextOverflow.ellipsis, style: small),
            ]),
          ),
          Expanded(
            flex: _flex[2],
            child: h.waveHeight == null
                ? Text('–', style: TextStyle(color: p.muted))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: fmt(h.waveHeight!),
                          style: p.num(16, weight: FontWeight.w600)),
                      TextSpan(text: ' m', style: small),
                    ])),
                    if (h.wavePeriod != null)
                      Text('${h.wavePeriod!.round()} s', style: small),
                  ]),
          ),
          Expanded(
            flex: _flex[3],
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SeaPill(state: state, label: seaLabels[state]),
            ),
          ),
        ]),
      ),
    );
  }

  /// Best 4-hour daylight window ahead: lowest sea state, then wind.
  /// Returns (start, end, worst sea state in the window).
  static (DateTime, DateTime, int)? _bestWindow(
      List<HourPoint> hours, DateTime now) {
    final candidates = hours
        .where((h) =>
            h.isDay && h.time.isAfter(now.subtract(const Duration(hours: 1))))
        .toList();
    (DateTime, DateTime, int)? best;
    var bestScore = double.infinity;
    for (var i = 0; i + 4 <= candidates.length; i++) {
      final w = candidates.sublist(i, i + 4);
      if (w.last.time.difference(w.first.time).inHours != 3) continue;
      final worst = w
          .map((h) => seaState(h.windSpeed, h.waveHeight))
          .reduce((a, b) => a > b ? a : b);
      final score =
          worst * 100 + w.map((h) => h.windSpeed).reduce((a, b) => a + b);
      if (score < bestScore) {
        bestScore = score;
        best = (w.first.time, w.last.time.add(const Duration(hours: 1)), worst);
      }
    }
    return best;
  }
}

/// Calm / moderate / rough pill.
class SeaPill extends StatelessWidget {
  const SeaPill({super.key, required this.state, required this.label});
  final int state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final (bg, fg) = switch (state) {
      0 => (p.okSoft, p.okInk),
      1 => (p.warnSoft, p.warnInk),
      _ => (p.dangerSoft, p.dangerInk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        LineIcon('waves', size: 14, color: fg),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
        ),
      ]),
    );
  }
}
