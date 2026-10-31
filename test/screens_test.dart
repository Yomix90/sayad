import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayad/data/knots.dart';
import 'package:sayad/data/species.dart';
import 'package:sayad/main.dart';
import 'package:sayad/screens/catch_log_screen.dart';
import 'package:sayad/screens/guides_screens.dart';
import 'package:sayad/screens/onboarding_screen.dart';
import 'package:sayad/screens/prayer_screen.dart';
import 'package:sayad/screens/settings_screen.dart';
import 'package:sayad/screens/solunar_screen.dart';
import 'package:sayad/theme.dart';

import 'helpers.dart';

void main() {
  final screens = <String, Widget Function()>{
    'shell': () => const HomeShell(),
    'onboarding': () => const OnboardingScreen(),
    'guide': () => const GuideScreen(),
    'tips': () => const TipsScreen(),
    'guideDetail': () => GuideDetailScreen(item: guide.first),
    'species': () => const SpeciesScreen(),
    'speciesDetail': () => SpeciesDetailScreen(species: species.first),
    'solunar': () => const SolunarScreen(),
    'catchLog': () => const CatchLogScreen(),
    'addCatch': () => const AddCatchScreen(),
    'prayer': () => const PrayerScreen(),
    'settings': () => const SettingsScreen(),
  };

  for (final style in AppStyle.values) {
    for (final lang in ['ar', 'fr', 'en']) {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} renders in $lang (${style.name})', (tester) async {
          phoneView(tester);
          final state = await testState(style: style);
          await tester.pumpWidget(testApp(state, entry.value(), lang: lang));
          await tester.pump(const Duration(seconds: 2));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('every tab of the shell renders with data', (tester) async {
    phoneView(tester);
    final state = await testState();
    await tester.pumpWidget(testApp(state, const HomeShell()));
    await tester.pump(const Duration(seconds: 2));
    for (final label in ['Marées', 'Prévisions', 'Outils', "Aujourd'hui"]) {
      await tester.tap(find.text(label).last);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: label);
    }
    expect(find.text('Indice de pêche'), findsOneWidget);
  });
}
