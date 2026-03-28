import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/math/graphing_tab.dart';

void main() {
  group('MathGraphingTab Widget Tests', () {
    Future<void> pumpGraphingTab(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathGraphingTab())),
      );
      await tester.pump();
    }

    testWidgets('MathGraphingTab renders correctly', (
      WidgetTester tester,
    ) async {
      await pumpGraphingTab(tester);

      expect(find.byType(MathGraphingTab), findsOneWidget);
    });

    testWidgets('MathGraphingTab has function input', (
      WidgetTester tester,
    ) async {
      await pumpGraphingTab(tester);

      // Should have text fields for function expressions
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathGraphingTab has graph canvas', (
      WidgetTester tester,
    ) async {
      await pumpGraphingTab(tester);

      // Should have a custom paint widget for graph rendering
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
