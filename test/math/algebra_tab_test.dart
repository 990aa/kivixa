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

    testWidgets('MathAlgebraTab has TabBar with 4 tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathAlgebraTab())),
      );
      await tester.pumpAndSettle();

      // Should have a TabBar
      expect(find.byType(TabBar), findsOneWidget);

      // Should have 4 tabs: Matrix, Complex, Equations, Systems
      expect(find.byType(Tab), findsNWidgets(4));
      expect(find.text('Matrix'), findsOneWidget);
      expect(find.text('Complex'), findsOneWidget);
      expect(find.text('Equations'), findsOneWidget);
      expect(find.text('Systems'), findsOneWidget);
    });

    testWidgets('MathAlgebraTab has matrix input fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathAlgebraTab())),
      );
      await tester.pumpAndSettle();

      // Should have text fields for matrix input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathAlgebraTab can navigate to Complex tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathAlgebraTab())),
      );
      await tester.pumpAndSettle();

      // Navigate to Complex tab
      await tester.tap(find.text('Complex'));
      await tester.pumpAndSettle();

      // Should have input fields for complex numbers
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathAlgebraTab has scrollable content', (
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
