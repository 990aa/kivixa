import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/math/statistics_tab.dart';

void main() {
  group('MathStatisticsTab Widget Tests', () {
    testWidgets('MathStatisticsTab renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathStatisticsTab())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MathStatisticsTab), findsOneWidget);
    });

    testWidgets('MathStatisticsTab has data input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathStatisticsTab())),
      );
      await tester.pumpAndSettle();

      // Should have text fields for data input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathStatisticsTab has statistics sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathStatisticsTab())),
      );
      await tester.pumpAndSettle();

      // Should have scrollable content
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}
