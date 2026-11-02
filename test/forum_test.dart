import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:sayad/screens/forum_screen.dart';
import 'package:sayad/screens/tools_screen.dart';
import 'package:sayad/screens/weather_map_screen.dart';
import 'package:sayad/services/forum_api.dart';
import 'package:sayad/services/spots_api.dart';
import 'package:sayad/services/weather_grid.dart';
import 'package:sayad/theme.dart';

import 'helpers.dart';

void main() {
  final calls = <http.BaseRequest>[];

  setUp(() {
    SpotsApi.overrideBase = 'https://api.example';
    ForumApi.testClient = forumMockServer(calls);
    calls.clear();
  });
  tearDown(() {
    SpotsApi.overrideBase = null;
    ForumApi.testClient = null;
    WeatherGridService.testClient = null;
  });

  test('articles, reactions and login go through the server', () async {
    final api = ForumApi(token: 'tok');
    final (total, items) = await api.articles(category: 'qa');
    expect(total, 2);
    expect(items.first.images.first, 'https://api.example/media/abc.jpg');
    expect(items.first.reactionCount, 4);
    expect(calls.single.url.queryParameters['category'], 'qa');
    expect(calls.single.headers['Authorization'], 'Bearer tok');

    final a = await api.article(2);
    expect(a.comments.map((c) => c.author), ['Alice', 'Bob']);
    expect(a.myReaction, 'like');
    final (counts, mine) = await api.react(2, 'fish');
    expect(counts['fish'], 2);
    expect(mine, 'fish');

    final (token, user) = await api.login('alice', 'secret');
    expect(token, 'tok');
    expect(user.displayName, 'Alice');
    await expectLater(api.comment(99, 'x'), throwsA(isA<ForumException>()));
  });

  test('shop details: info lines without repeats, WhatsApp only for mobiles', () {
    ServerSpot shop(String phone, String desc) => ServerSpot(
        id: 1, name: 'Hassan Peche', position: const LatLng(30, -9), phone: phone, description: desc);
    final s = shop('0528332232', 'Hassan Peche\nwww.hassan-peche.com\n0528 33 22 32\nLundi au samedi');
    expect(s.infoLines, ['www.hassan-peche.com', 'Lundi au samedi']);
    expect(s.whatsapp, isNull); // landline
    expect(shop('0661 23 45 67', '').whatsapp, '212661234567');
    expect(shop('+212712345678', '').whatsapp, '212712345678');
    expect(shop('97484158', '').whatsapp, isNull);
  });

  test('weather grid interpolates and leaves land empty for waves', () {
    final g = WeatherGrid(
      south: 30, west: -10, north: 31, east: -9, rows: 2, cols: 2,
      start: DateTime.utc(2026, 11, 2),
      values: [
        [10, 20, 30, 40],
        [null, null, null, 1],
      ],
    );
    expect(g.at(const LatLng(30.5, -9.5), 0), closeTo(25, 1e-9));
    expect(g.at(const LatLng(30, -10), 0), 10);
    expect(g.at(const LatLng(29, -9.5), 0), isNull);
    // Only one corner has data: no value far from it.
    expect(g.at(const LatLng(30.1, -9.9), 1), isNull);
    expect(g.at(const LatLng(30.95, -9.05), 1), 1);
    expect(wxScales[WxLayer.wind]!.color(1000), wxScales[WxLayer.wind]!.stops.last.$2);
  });

  for (final style in AppStyle.values) {
    for (final lang in ['ar', 'fr', 'en']) {
      testWidgets('forum list, article and compose render in $lang (${style.name})', (tester) async {
        phoneView(tester);
        final state = await testState(style: style);
        await tester.pumpWidget(testApp(state, const Scaffold(body: ForumScreen()), lang: lang));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.text('Belle courbine à Dakhla 2'), findsOneWidget);

        await tester.tap(find.text('Belle courbine à Dakhla 2'));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        final bravo = find.byWidgetPredicate(
            (w) => w is SelectableText && w.textSpan!.toPlainText() == 'Bravo !');
        await tester.drag(find.text('Belle courbine à Dakhla 2'), const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 300));
        expect(bravo, findsOneWidget);

        await state.setForumSession(
            'tok', ForumUser(id: 7, username: 'alice', displayName: 'Alice'));
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(testApp(state, const ComposeScreen(), lang: lang));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(testApp(state, const AccountScreen(), lang: lang));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('@alice'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('logging in from the account page saves the session', (tester) async {
    phoneView(tester);
    final state = await testState();
    await tester.pumpWidget(testApp(state, const AccountScreen()));
    await tester.enterText(find.byType(TextField).first, 'alice');
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.tap(find.text('Se connecter'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(state.forumUser?.displayName, 'Alice');
    expect(state.forumToken, 'tok');
  });

  testWidgets('tools grid and weather map render', (tester) async {
    phoneView(tester);
    WeatherGridService.testClient = weatherMockServer();
    final state = await testState();
    for (final lang in ['ar', 'fr']) {
      await tester.pumpWidget(testApp(state, const Scaffold(body: ToolsScreen()), lang: lang));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(testApp(state, const WeatherMapScreen(), lang: lang));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byType(Slider), findsOneWidget);
    }
  });
}
