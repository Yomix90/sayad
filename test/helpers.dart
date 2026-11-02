import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
  // flutter_map caches tiles in the app's cache folder.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.createTempSync('sayad_test').path);
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

Map<String, dynamic> _article(int id, {bool full = false}) => {
      'id': id,
      'title': 'Belle courbine à Dakhla $id',
      'category': id.isEven ? 'catches' : 'qa',
      'excerpt': 'Une prise de 12 kg au lever du jour, avec un leurre souple…',
      'author': id.isEven ? 'Alice' : 'لكديرة',
      'user_id': id.isEven ? 7 : null,
      'images': id.isEven ? ['/media/abc.jpg', 'https://x.example/b.jpg'] : <String>[],
      'created_at': 1730000000 + id,
      'source': id.isEven ? 'app' : 'tifnit',
      'comments': 2,
      'reactions': {'like': 3, 'fish': 1},
      if (full) ...{
        'body': 'Premier paragraphe.\nVidéo : https://www.youtube.com/watch?v=abcdefghijk',
        'comment_list': [
          {'id': 1, 'user_id': 7, 'author': 'Alice', 'body': 'Bravo !', 'created_at': 1730000100},
          {'id': 2, 'user_id': 9, 'author': 'Bob', 'body': 'Où exactement ?', 'created_at': 1730000200},
        ],
        'my_reaction': 'like',
      },
    };

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status,
        headers: {'content-type': 'application/json'});

/// Fake forum server: two articles, one with photos and comments.
MockClient forumMockServer([List<http.BaseRequest>? calls]) => MockClient((req) async {
      calls?.add(req);
      final path = req.url.path;
      if (path == '/forum/articles' && req.method == 'GET') {
        return _json({'total': 2, 'items': [_article(2), _article(3)]});
      }
      if (path.startsWith('/forum/articles/') && req.method == 'GET') {
        return _json(_article(int.parse(path.split('/').last), full: true));
      }
      if (path == '/forum/ai') return _json({'enabled': true});
      if (path == '/forum/ai/improve') {
        final b = jsonDecode(req is http.Request ? req.body : '{}') as Map<String, dynamic>;
        return _json({'title': 'Titre revu', 'body': '${b['body']} (revu)'});
      }
      if (path.endsWith('/react')) return _json({'reactions': {'like': 2, 'fish': 2}, 'my_reaction': 'fish'});
      if (path == '/auth/login') {
        return _json({'token': 'tok', 'user': {'id': 7, 'username': 'alice', 'display_name': 'Alice'}});
      }
      return _json({'detail': 'Not found'}, 404);
    });

/// Fake Open-Meteo: wind over every requested point for 72 hours.
MockClient weatherMockServer() => MockClient((req) async {
      final lats = req.url.queryParameters['latitude']!.split(',');
      final lons = req.url.queryParameters['longitude']!.split(',');
      final times = [
        for (var h = 0; h < 72; h++)
          '2026-11-0${2 + h ~/ 24}T${(h % 24).toString().padLeft(2, '0')}:00'
      ];
      return _json([
        for (var i = 0; i < lats.length; i++)
          {
            'hourly': {
              'time': times,
              'wind_speed_10m': [
                for (var h = 0; h < 72; h++)
                  12 + 30 * sin(double.parse(lats[i]) * 1.3 + h / 9) * cos(double.parse(lons[i]) * 0.9)
              ],
              'wind_direction_10m': [
                for (var h = 0; h < 72; h++) (20 + 40 * double.parse(lons[i]) + h * 3) % 360
              ],
            }
          }
      ]);
    });
