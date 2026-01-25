import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/math/tools_tab.dart';

void main() {
  group('MathToolsTab Widget Tests', () {
    testWidgets('MathToolsTab renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathToolsTab())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathToolsTab), findsOneWidget);
    });

    testWidgets('MathToolsTab displays Unit Converter title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathToolsTab())),
      );
      await tester.pumpAndSettle();

      // Should display Unit Converter title
      expect(find.text('Unit Converter'), findsOneWidget);
    });

    testWidgets('MathToolsTab has input fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathToolsTab())),
      );
      await tester.pumpAndSettle();

      // Should have text fields for unit conversion input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathToolsTab has category dropdown', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathToolsTab())),
      );
      await tester.pumpAndSettle();

      // Should have a dropdown for unit categories
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    });

    testWidgets('MathToolsTab has scrollable content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathToolsTab())),
      );
      await tester.pumpAndSettle();

      // Should have scrollable content
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('MathToolsTab has swap button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathToolsTab())),
      );
      await tester.pumpAndSettle();

      // Should have IconButton for swapping units
      expect(find.byType(IconButton), findsWidgets);
    });
  });
}
