import 'package:flutter_test/flutter_test.dart';
import 'package:sayad/screens/splash_screen.dart';

import 'helpers.dart';

void main() {
  for (final lang in ['ar', 'fr', 'en']) {
    testWidgets('splash plays then calls onDone ($lang)', (tester) async {
      phoneView(tester);
      final state = await testState();
      var done = false;
      await tester.pumpWidget(
          testApp(state, SplashScreen(onDone: () => done = true), lang: lang));
      await tester.pump(const Duration(seconds: 1));
      expect(done, isFalse);
      await tester.pump(SplashScreen.duration);
      expect(done, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
