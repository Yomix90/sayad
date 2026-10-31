import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/astro.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sub_page.dart';

/// 30-day solunar calendar: moon phase, day rating and fishing periods.
class SolunarScreen extends StatelessWidget {
  const SolunarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pos = AppScope.of(context).position;
    final locale = Localizations.localeOf(context).toString();
    final hm = DateFormat.Hm(locale);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final p = Palette.of(context);
    return SubPage(
      title: t.solunarCalendar,
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: 31,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(t.solunarHelp,
                  style: Theme.of(context).textTheme.bodySmall),
            );
          }
          final day = today.add(Duration(days: i - 1));
          final moon = moonInfo(day.add(const Duration(hours: 12)));
          final rating = solunarDayRating(pos.latitude, pos.longitude, day);
          final periods = solunarPeriods(pos.latitude, pos.longitude, day);
          return AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            color: i == 1 ? p.surface2 : null,
            borderColor: i == 1 ? p.accent : null,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  MoonIcon(age: moon.age, size: 36),
                  const SizedBox(height: 4),
                  Text('${(moon.illumination * 100).round()}%',
                      style: Theme.of(context).textTheme.labelSmall),
                ]),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(DateFormat.MMMEd(locale).format(day),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: p.text)),
                          ),
                          for (var s = 0; s < 4; s++)
                            Icon(s < rating ? Icons.star : Icons.star_border,
                                size: 18, color: p.warn),
                        ]),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          for (final per in periods)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: per.major ? p.bandMajor : p.bandMinor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  '${per.major ? t.major : t.minor} ${hm.format(per.start)}–${hm.format(per.end)}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: per.major
                                          ? (p.classic ? const Color(0xFFF3E9D2) : const Color(0xFF04222B))
                                          : p.text)),
                            ),
                        ]),
                      ]),
                ),
              ]),
          );
        },
      ),
    );
  }
}
