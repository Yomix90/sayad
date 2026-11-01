import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../l10n/app_localizations.dart';
import '../services/ephemeris.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sub_page.dart';

class BigTide {
  BigTide(this.peak, this.full, this.coefficient);

  /// Strongest day (about 1.5 days after the new or full moon).
  final DateTime peak;
  final bool full;
  final int coefficient;
}

/// Spring tides of [year], computed from the Moon and Sun positions.
List<BigTide> bigTidesOf(int year) => [
      for (final s in syzygies(DateTime.utc(year - 1, 12, 28), DateTime.utc(year, 12, 31)))
        if (s.time.add(const Duration(hours: 36)).toLocal().year == year)
          BigTide(s.time.add(const Duration(hours: 36)).toLocal(), s.full,
              tideCoefficient(s.time.add(const Duration(hours: 36)))),
    ];

/// The year's spring tides, biggest highlighted: best days to collect bait
/// on the foreshore and to fish the edges at low tide.
class BigTidesScreen extends StatefulWidget {
  const BigTidesScreen({super.key});

  @override
  State<BigTidesScreen> createState() => _BigTidesScreenState();
}

class _BigTidesScreenState extends State<BigTidesScreen> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final tides = bigTidesOf(_year);
    final top = ([...tides]..sort((a, b) => b.coefficient.compareTo(a.coefficient)))
        .take(6)
        .map((e) => e.peak)
        .toSet();
    final now = DateTime.now();

    return SubPage(
      title: t.bigTides,
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Row(children: [
          for (final y in [now.year, now.year + 1])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: StatusChip(
                label: '$y',
                compact: false,
                tone: y == _year ? ChipTone.solid : ChipTone.neutral,
                onTap: () => setState(() => _year = y),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        Text(t.bigTidesHelp, style: TextStyle(fontSize: 13.5, color: p.muted, height: 1.45)),
        const SizedBox(height: 12),
        for (final e in tides)
          Opacity(
            opacity: e.peak.isBefore(now.subtract(const Duration(days: 1))) ? 0.45 : 1,
            child: AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: top.contains(e.peak) ? p.surface2 : null,
              borderColor: top.contains(e.peak) ? p.accent : null,
              child: Row(children: [
                MoonIcon(age: e.full ? 14.77 : 0.3, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(DateFormat.MMMMEEEEd(locale).format(e.peak), style: p.title(15)),
                    Text(
                        '${e.full ? t.moonFull : t.moonNew}${top.contains(e.peak) ? ' · ${t.bigTideTop}' : ''}',
                        style: TextStyle(fontSize: 12.5, color: p.muted)),
                  ]),
                ),
                Column(children: [
                  Text('${e.coefficient}',
                      style: p.num(24,
                          color: e.coefficient >= 100
                              ? p.dangerInk
                              : e.coefficient >= 90
                                  ? p.warnInk
                                  : p.text)),
                  Text(t.coefficientShort, style: TextStyle(fontSize: 11, color: p.muted)),
                ]),
              ]),
            ),
          ),
        const SizedBox(height: 4),
        Text(t.coefficientDisclaimer, style: TextStyle(fontSize: 12.5, color: p.muted)),
      ]),
    );
  }
}
