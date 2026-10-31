import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/hijri.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/line_icons.dart';
import '../widgets/sub_page.dart';
import 'city_picker.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    const languages = <(String?, String)>[
      (null, ''),
      ('fr', 'Français'),
      ('ar', 'العربية'),
      ('en', 'English'),
    ];
    return SubPage(
      title: t.tabSettings,
      body: ListView(padding: const EdgeInsets.all(14), children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CardHead(title: t.language),
            for (final (code, name) in languages)
              OptionTile(
                selected: state.locale?.languageCode == code,
                leading: LineIcon('globe', size: 20, color: p.accentInk),
                title: code == null ? t.systemLanguage : name,
                onTap: () => state.setLocale(code == null ? null : Locale(code)),
              ),
          ]),
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CardHead(title: t.appearance),
            OptionTile(
              selected: state.style == AppStyle.modern,
              leading: LineIcon('compass', size: 20, color: p.accentInk),
              title: t.styleModern,
              subtitle: t.styleModernSub,
              onTap: () => state.setStyle(AppStyle.modern),
            ),
            OptionTile(
              selected: state.style == AppStyle.classic,
              leading: LineIcon('sun', size: 20, color: p.accentInk),
              title: t.styleClassic,
              subtitle: t.styleClassicSub,
              onTap: () => state.setStyle(AppStyle.classic),
            ),
          ]),
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CardHead(title: t.fishingRegion),
            OptionTile(
              selected: true,
              leading: LineIcon('pin', size: 20, color: p.accentInk),
              title: state.usingGps ? t.myPosition : state.region.name.of(context),
              subtitle: t.changeCity,
              onTap: () => showCityPicker(context),
            ),
          ]),
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CardHead(title: t.hijriCalendar),
            Text(t.hijriHelp, style: TextStyle(fontSize: 13.5, color: p.muted, height: 1.4)),
            const SizedBox(height: 10),
            for (final o in const [-1, 0, 1])
              OptionTile(
                selected: state.hijriOffset == o,
                leading: LineIcon('moon', size: 20, color: p.accentInk),
                title: formatHijri(DateTime.now(),
                    Localizations.localeOf(context).languageCode, offsetDays: o),
                subtitle: o == -1 ? t.hijriMorocco : o == 0 ? t.hijriUmmAlQura : '+1',
                onTap: () => state.setHijriOffset(o),
              ),
          ]),
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CardHead(title: t.about),
            Text(t.dataSources,
                style: TextStyle(fontSize: 14.5, height: 1.45, color: p.muted)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(replay: true))),
              child: Text(t.replayWelcome),
            ),
          ]),
        ),
      ]),
    );
  }
}
