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

    testWidgets('MathStatisticsTab has TabBar with 4 tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathStatisticsTab())),
      );
      await tester.pumpAndSettle();

      // Should have a TabBar for different statistics sections
      expect(find.byType(TabBar), findsOneWidget);

      // Should have 4 tabs: Descriptive, Distributions, Regression, Hypothesis
      expect(find.byType(Tab), findsNWidgets(4));
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

    testWidgets('MathStatisticsTab has distribution dropdown', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathStatisticsTab())),
      );
      await tester.pumpAndSettle();

      // Navigate to Distributions tab
      await tester.tap(find.text('Distributions'));
      await tester.pumpAndSettle();

      // Should have dropdown for distribution selection
      expect(find.byType(DropdownButton<String>), findsWidgets);
    });

    testWidgets('MathStatisticsTab has hypothesis test options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathStatisticsTab())),
      );
      await tester.pumpAndSettle();

      // Navigate to Hypothesis tab
      await tester.tap(find.text('Hypothesis'));
      await tester.pumpAndSettle();

      // Should have dropdown for test selection
      expect(find.byType(DropdownButton<String>), findsWidgets);
    });

    testWidgets('MathStatisticsTab has scrollable content', (
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
