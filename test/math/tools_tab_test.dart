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

    testWidgets('MathToolsTab has input fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathToolsTab())),
      );
      await tester.pumpAndSettle();

      // Should have text fields for various inputs
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathToolsTab has tool sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathToolsTab())),
      );
      await tester.pumpAndSettle();

      // Should have scrollable content
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('MathToolsTab has unit conversion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathToolsTab())),
      );
      await tester.pumpAndSettle();

      // Should have a dropdown for unit categories
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    });
  });
}
