import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/line_icons.dart';
import 'big_tides_screen.dart';
import 'catch_log_screen.dart';
import 'compass_screen.dart';
import 'guides_screens.dart';
import 'prayer_screen.dart';
import 'settings_screen.dart';
import 'sky_screen.dart';
import 'solunar_screen.dart';
import 'weather_map_screen.dart';

/// Grid of the other tools of the app.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final ink = p.classic ? const Color(0xFF33220F) : p.accentInk;
    final tools = <(Widget, String, String, Widget)>[
      (LineIcon('cloud', size: 30, color: ink), t.weatherMap, t.weatherMapSub, const WeatherMapScreen()),
      (LineIcon('book', size: 30, color: ink), t.guide, t.knotsAndHooks, const GuideScreen()),
      (LineIcon('info', size: 30, color: ink), t.tips, t.tipsSub, const TipsScreen()),
      (LineIcon('fish', size: 30, color: ink), t.species, t.speciesSub, const SpeciesScreen()),
      (LineIcon('waves', size: 30, color: ink), t.bigTides, t.bigTidesSub, const BigTidesScreen()),
      (LineIcon('sun', size: 30, color: ink), t.sky, t.skySub, const SkyScreen()),
      (LineIcon('moon', size: 30, color: ink), t.solunarCalendar, t.solunarSub, const SolunarScreen()),
      (LineIcon('bookmark', size: 30, color: ink), t.catchLog, t.catchLogSub, const CatchLogScreen()),
      (LineIcon('compass', size: 30, color: ink), t.compass, t.compassSub, const CompassScreen()),
      (Icon(Icons.mosque_outlined, size: 30, color: ink), t.tabPrayer, t.prayerSub, const PrayerScreen()),
      (Icon(Icons.settings_outlined, size: 30, color: ink), t.tabSettings, t.settingsSub, const SettingsScreen()),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      children: [
        ScreenHead(title: t.tabTools),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.98,
          children: [
            for (final (icon, title, sub, screen) in tools)
              AppCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(14),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => screen)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 64,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: p.surface2,
                        borderRadius: BorderRadius.circular(p.radiusS),
                      ),
                      child: Center(child: icon),
                    ),
                    const SizedBox(height: 10),
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: p.title(15).copyWith(height: 1.2)),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Text(sub,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                              fontSize: 12.5, color: p.muted, height: 1.35)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Frieze(),
      ],
    );
  }
}
