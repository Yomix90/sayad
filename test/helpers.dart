import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:sayad/l10n/app_localizations.dart';
import 'package:sayad/services/app_state.dart';
import 'package:sayad/services/forecast_service.dart';
import 'package:sayad/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plausible 8-day forecast (sine tides, varying wind) for [AppState]'s
/// default position, so screens render without network.
Forecast fakeForecast() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
  final hourly = [
    for (var i = 0; i < 24 * 8; i++)
      () {
        final t = start.add(Duration(hours: i));
        final wind = 12 + 10 * sin(i / 9) + (i % 24 > 13 ? 8 : 0);
        return HourPoint(
          time: t,
          temperature: 17 + 5 * sin((t.hour - 9) / 24 * 2 * pi),
          windSpeed: wind,
          windDirection: (40 + i * 3) % 360,
          windGusts: wind * 1.5,
          humidity: 80 - 10 * sin(t.hour / 24 * 2 * pi),
          pressure: 1015 + sin(i / 30) * 4,
          weatherCode: i % 24 < 12 ? 1 : 3,
          isDay: t.hour >= 7 && t.hour < 19,
          waveHeight: 0.8 + 0.7 * sin(i / 14).abs(),
          waveDirection: 300,
          wavePeriod: 11,
          currentSpeed: 0.6,
          currentDirection: 200,
          seaLevel: 1.2 * sin(i / 12.42 * 2 * pi),
        );
      }(),
  ];
  return Forecast(
    temperature: 19,
    windSpeed: 14,
    windDirection: 45,
    windGusts: 22,
    pressure: 1016,
    humidity: 72,
    weatherCode: 1,
    waveHeight: 1.8,
    wavePeriod: 11,
    waveDirection: 315,
    seaTemperature: 19,
    hourly: hourly,
  );
}

Future<AppState> testState({AppStyle style = AppStyle.modern}) async {
  DateFormat.useNativeDigitsByDefaultFor('ar', false);
  SharedPreferences.setMockInitialValues({'onboarded': true});
  final state = AppState();
  await state.load();
  state.style = style;
  ForecastService.seed(state.position.latitude, state.position.longitude, fakeForecast());
  return state;
}

Widget testApp(AppState state, Widget home, {String lang = 'fr'}) => AppScope(
      state: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(lang),
        theme: buildAppTheme(state.style, arabic: lang == 'ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    );

/// Phone-sized surface (393×851 dp).
void phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

/// Loads the bundled fonts so previews show real text instead of boxes.
Future<void> loadAppFonts() async {
  final families = <String, List<String>>{};
  for (final f in Directory('assets/fonts').listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    families.putIfAbsent(name.split('-').first, () => []).add(f.path);
  }
  for (final e in families.entries) {
    final loader = FontLoader(e.key);
    for (final path in e.value) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(File(
            '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf')
        .readAsBytesSync()
        .buffer)));
  await icons.load();
}
