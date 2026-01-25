import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/math/discrete_tab.dart';

void main() {
  group('MathDiscreteTab Widget Tests', () {
    testWidgets('MathDiscreteTab renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathDiscreteTab())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathDiscreteTab), findsOneWidget);
    });

    testWidgets('MathDiscreteTab has number input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathDiscreteTab())),
      );
      await tester.pumpAndSettle();

      // Should have text fields for number input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathDiscreteTab has discrete math sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathDiscreteTab())),
      );
      await tester.pumpAndSettle();

      // Should have scrollable content
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}
