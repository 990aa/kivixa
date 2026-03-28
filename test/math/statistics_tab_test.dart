import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/math/statistics_tab.dart';

void main() {
  group('MathStatisticsTab Widget Tests', () {
    Future<void> pumpStatisticsTab(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathStatisticsTab())),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('MathStatisticsTab renders correctly', (
      WidgetTester tester,
    ) async {
      await pumpStatisticsTab(tester);

      expect(find.byType(MathStatisticsTab), findsOneWidget);
    });

    testWidgets('MathStatisticsTab has TabBar with 5 tabs', (
      WidgetTester tester,
    ) async {
      await pumpStatisticsTab(tester);

      // Should have a TabBar for different statistics sections
      expect(find.byType(TabBar), findsOneWidget);

      // Should have 5 tabs: Descriptive, Correlation, Distributions,
      // Regression, Hypothesis
      expect(find.byType(Tab), findsNWidgets(5));
    });

    testWidgets('MathStatisticsTab has data input', (
      WidgetTester tester,
    ) async {
      await pumpStatisticsTab(tester);

      // Should have text fields for data input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('MathStatisticsTab has distribution dropdown', (
      WidgetTester tester,
    ) async {
      await pumpStatisticsTab(tester);

      // Navigate to Distributions tab
      await tester.ensureVisible(find.text('Distributions'));
      await tester.tap(find.text('Distributions'));
      await tester.pumpAndSettle();

      // Should have dropdown for distribution selection
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    });

    testWidgets('MathStatisticsTab has hypothesis test options', (
      WidgetTester tester,
    ) async {
      await pumpStatisticsTab(tester);

      // Navigate to Hypothesis tab
      await tester.ensureVisible(find.text('Hypothesis'));
      await tester.tap(find.text('Hypothesis'));
      await tester.pumpAndSettle();

      // Should have dropdown for test selection
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    });

    testWidgets('MathStatisticsTab has scrollable content', (
      WidgetTester tester,
    ) async {
      await pumpStatisticsTab(tester);

      // Should have scrollable content
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}
