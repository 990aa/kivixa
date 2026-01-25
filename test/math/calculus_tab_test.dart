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

    testWidgets('MathCalculusTab has TabBar with 6 tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathCalculusTab())),
      );
      await tester.pumpAndSettle();

      // Should have a TabBar
      expect(find.byType(TabBar), findsOneWidget);

      // Should have 6 tabs: Derivative, Partial, Integral, Multiple Int, Limits, Series
      expect(find.byType(Tab), findsNWidgets(6));
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

    testWidgets('MathCalculusTab can navigate to Partial tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathCalculusTab())),
      );
      await tester.pumpAndSettle();

      // Navigate to Partial tab
      await tester.tap(find.text('Partial'));
      await tester.pumpAndSettle();

      // Should show partial derivative content
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathCalculusTab can navigate to Multiple Int tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathCalculusTab())),
      );
      await tester.pumpAndSettle();

      // Navigate to Multiple Int tab
      await tester.tap(find.text('Multiple Int'));
      await tester.pumpAndSettle();

      // Should show multiple integral content
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathCalculusTab has calculate button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathCalculusTab())),
      );
      await tester.pumpAndSettle();

      // Should have FilledButton for compute operations
      expect(find.byType(FilledButton), findsWidgets);
    });

    testWidgets('MathCalculusTab has scrollable content', (
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
