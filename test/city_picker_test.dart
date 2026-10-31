import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayad/data/regions.dart';
import 'package:sayad/main.dart';
import 'package:sayad/screens/city_picker.dart';

import 'helpers.dart';

void main() {
  test('every town is on the Moroccan coast and ids are unique', () {
    expect(regions.map((r) => r.id).toSet(), hasLength(regions.length));
    for (final r in regions) {
      expect(r.position.latitude, inInclusiveRange(21, 36), reason: r.id);
      expect(r.position.longitude, inInclusiveRange(-17.5, -1.9), reason: r.id);
    }
  });

  test('search ignores accents and Arabic letter variants', () {
    expect(normalizeSearch('Saïdia'), normalizeSearch('saidia'));
    expect(normalizeSearch('Laâyoune Plage').contains(normalizeSearch('laayoune')), isTrue);
    expect(normalizeSearch('أصيلة'), normalizeSearch('اصيله'));
  });

  for (final lang in ['fr', 'ar']) {
    testWidgets('pick a town from the Today screen ($lang)', (tester) async {
      phoneView(tester);
      final state = await testState();
      await tester.pumpWidget(testApp(state, const HomeShell(), lang: lang));
      await tester.pump(const Duration(seconds: 3));

      await tester.tap(find.text(lang == 'ar' ? 'الدار البيضاء' : 'Casablanca').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CityPicker), findsOneWidget);

      await tester.enterText(find.byType(TextField), lang == 'ar' ? 'الداخلة' : 'dakh');
      await tester.pump();
      await tester.tap(find.text(lang == 'ar' ? 'الداخلة' : 'Dakhla').last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(state.regionId, 'dakhla');
      expect(state.usingGps, isFalse);
      expect(state.position, regionById('dakhla').position);
      expect(find.byType(CityPicker), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
