import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App renders consistently on all themes and screen sizes', (
    WidgetTester tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MyApp),
        matchesGoldenFile(
          'goldens/app_${brightness == Brightness.light ? 'light' : 'dark'}.png',
        ),
      );
    }
  });
}
