import 'package:flutter_test/flutter_test.dart';
import 'package:sayad/main.dart';

import 'helpers.dart';

void main() {
  testWidgets('Arabic screens use 0-9 digits, never ٠-٩', (tester) async {
    phoneView(tester);
    final state = await testState();
    await tester.pumpWidget(testApp(state, const HomeShell(), lang: 'ar'));
    await tester.pump(const Duration(seconds: 3));
    for (final tab in ['المد والجزر', 'التوقعات', 'اليوم']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(seconds: 2));
      final all = find.textContaining(RegExp('[٠-٩]'));
      expect(all, findsNothing, reason: tab);
    }
  });
}
