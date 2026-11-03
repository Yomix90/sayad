import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/line_icons.dart';
import 'forecast_table_screen.dart';
import 'weather_map_screen.dart';
import 'windy_map.dart';

/// Forecast tab: the table, the app's weather map and Windy's map.
class ForecastTabsScreen extends StatefulWidget {
  const ForecastTabsScreen({super.key});

  @override
  State<ForecastTabsScreen> createState() => _ForecastTabsScreenState();
}

class _ForecastTabsScreenState extends State<ForecastTabsScreen> {
  int _tab = 0;

  // Maps are built the first time they are opened, then kept.
  final _opened = <int>{0};

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final tabs = [
      ('cloud', t.tabForecast),
      ('map', t.mapTab),
      ('wind', 'Windy'),
    ];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: SegmentedButton<int>(
          segments: [
            for (final (i, (icon, label)) in tabs.indexed)
              ButtonSegment(
                value: i,
                label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                icon: LineIcon(icon, size: 18, color: _tab == i ? p.accentInk : p.muted),
              ),
          ],
          selected: {_tab},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() {
            _tab = v.first;
            _opened.add(_tab);
          }),
        ),
      ),
      Expanded(
        // Left-to-right maps keep their own gestures: no swipe between tabs.
        child: IndexedStack(index: _tab, children: [
          const ForecastTableScreen(),
          _opened.contains(1) ? const WeatherMapScreen(embedded: true) : const SizedBox(),
          _opened.contains(2) ? const WindyMapView() : const SizedBox(),
        ]),
      ),
    ]);
  }
}
