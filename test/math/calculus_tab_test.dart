import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/math/calculus_tab.dart';

void main() {
  group('MathCalculusTab Widget Tests', () {
    testWidgets('MathCalculusTab renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathCalculusTab())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathCalculusTab), findsOneWidget);
    });

    testWidgets('MathCalculusTab has function input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathCalculusTab())),
      );
      await tester.pumpAndSettle();

      // Should have text fields for function expressions
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathCalculusTab has calculus operation sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathCalculusTab())),
      );
      await tester.pumpAndSettle();

      // Should have scrollable content
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}
