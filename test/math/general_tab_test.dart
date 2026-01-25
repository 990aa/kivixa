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

    testWidgets('MathGeneralTab has nPr and nCr buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathGeneralTab())),
      );
      await tester.pumpAndSettle();

      // Should have nPr and nCr buttons
      expect(find.text('nPr'), findsOneWidget);
      expect(find.text('nCr'), findsOneWidget);
    });

    testWidgets('MathGeneralTab has number buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathGeneralTab())),
      );
      await tester.pumpAndSettle();

      // Should have number buttons 0-9
      for (var i = 0; i < 10; i++) {
        expect(find.text('$i'), findsWidgets);
      }
    });

    testWidgets('MathGeneralTab has scrollable content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathGeneralTab())),
      );
      await tester.pumpAndSettle();

      // Should have scrollable content
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('MathGeneralTab has constants section', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathGeneralTab())),
      );
      await tester.pumpAndSettle();

      // Should have constants section with ListTile
      expect(find.text('Constants'), findsOneWidget);
    });
  });
}
