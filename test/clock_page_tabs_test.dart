import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/clock_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('clock page has no Chains tab and keeps routines create action', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ClockPage()));
    await tester.pumpAndSettle();

    expect(find.byType(Tab), findsNWidgets(4));
    expect(
      find.descendant(of: find.byType(TabBar), matching: find.text('Focus')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(TabBar), matching: find.text('Presets')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(TabBar), matching: find.text('Routines')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(TabBar), matching: find.text('Stats')),
      findsOneWidget,
    );
    expect(find.text('Chains'), findsNothing);

    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Create routine'), findsOneWidget);
    expect(find.text('Chained Routines'), findsOneWidget);
    expect(find.text('Custom Chains'), findsNothing);
  });
}
