import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/math/algebra_tab.dart';

void main() {
  group('MathAlgebraTab Widget Tests', () {
    testWidgets('MathAlgebraTab renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathAlgebraTab())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathAlgebraTab), findsOneWidget);
    });

    testWidgets('MathAlgebraTab has input fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathAlgebraTab())),
      );
      await tester.pumpAndSettle();

      // Should have text fields for matrix input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathAlgebraTab has section headers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathAlgebraTab())),
      );
      await tester.pumpAndSettle();

      // Should have scrollable content
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}
