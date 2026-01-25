import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/math/general_tab.dart';

void main() {
  group('MathGeneralTab Widget Tests', () {
    testWidgets('MathGeneralTab renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathGeneralTab())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathGeneralTab), findsOneWidget);
    });

    testWidgets('MathGeneralTab has expression input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathGeneralTab())),
      );
      await tester.pumpAndSettle();

      // Should have a text field for expression input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathGeneralTab has calculator buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathGeneralTab())),
      );
      await tester.pumpAndSettle();

      // Should have InkWell buttons for calculator
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('MathGeneralTab has calculate button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathGeneralTab())),
      );
      await tester.pumpAndSettle();

      // Look for a filled button (FilledButton.tonal) or any button type
      expect(
        find.byType(FilledButton).evaluate().isNotEmpty ||
            find.byType(ElevatedButton).evaluate().isNotEmpty ||
            find.byType(IconButton).evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
