// Renders screens with the real fonts into PNG previews:
//   flutter test test/preview_test.dart --update-goldens --tags preview --run-skipped
// Skipped in normal test runs.
@Tags(['preview'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayad/data/knots.dart';
import 'package:sayad/main.dart';
import 'package:sayad/screens/guides_screens.dart';
import 'package:sayad/screens/onboarding_screen.dart';
import 'package:sayad/screens/splash_screen.dart';
import 'package:sayad/theme.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  // (name, tab index or -1, screen builder)
  final shots = <(String, int, Widget Function())>[
    ('today', 0, () => const HomeShell()),
    ('tides', 1, () => const HomeShell()),
    ('forecast', 3, () => const HomeShell()),
    ('tools', 4, () => const HomeShell()),
    ('guide', -1, () => const GuideScreen()),
    ('knot', -1, () => GuideDetailScreen(item: guide.first)),
    ('welcome', -1, () => const OnboardingScreen()),
  ];
  const tabLabels = ["Aujourd'hui", 'Marées', 'Carte', 'Prévisions', 'Outils'];
  const tabLabelsAr = ['اليوم', 'المد والجزر', 'الخريطة', 'التوقعات', 'الأدوات'];

  for (final (lang, ms) in [('fr', 600), ('fr', 1800), ('ar', 3000)]) {
    testWidgets('preview splash $lang $ms', (tester) async {
      phoneView(tester);
      final state = await testState();
      await tester.pumpWidget(testApp(state, SplashScreen(onDone: () {}), lang: lang));
      await tester.pump(Duration(milliseconds: ms));
      await expectLater(find.byType(SplashScreen),
          matchesGoldenFile('previews/splash_${lang}_$ms.png'));
      await tester.pump(SplashScreen.duration);
    });
  }

  for (final (style, lang) in [(AppStyle.modern, 'fr'), (AppStyle.classic, 'ar')]) {
    testWidgets('preview city picker ${style.name} $lang', (tester) async {
      phoneView(tester);
      debugDisableShadows = false;
      final state = await testState(style: style);
      await tester.pumpWidget(testApp(state, const HomeShell(), lang: lang));
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text(lang == 'ar' ? 'الدار البيضاء' : 'Casablanca').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('previews/city_${style.name}_$lang.png'));
      debugDisableShadows = true;
    });
  }

  for (final style in AppStyle.values) {
    for (final lang in ['fr', 'ar']) {
      for (final (name, tab, build) in shots) {
        testWidgets('preview $name ${style.name} $lang', (tester) async {
          phoneView(tester);
          // Draw real blurred shadows, as on a phone (reset before the end).
          debugDisableShadows = false;
          final state = await testState(style: style);
          await tester.pumpWidget(testApp(state, build(), lang: lang));
          await tester.pump(const Duration(seconds: 2));
          if (tab > 0) {
            await tester.tap(find.text((lang == 'ar' ? tabLabelsAr : tabLabels)[tab]).last);
            await tester.pump(const Duration(seconds: 2));
          }
          // Let entry animations (gauge) finish.
          await tester.pump(const Duration(seconds: 2));
          await expectLater(find.byType(MaterialApp),
              matchesGoldenFile('previews/${name}_${style.name}_$lang.png'));
          debugDisableShadows = true;
        });
      }
    }
  }
}
