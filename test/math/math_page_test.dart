import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/math_page.dart';

void main() {
  group('MathPage Widget Tests', () {
    testWidgets('MathPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MathPage()));
      await tester.pumpAndSettle();

      // Verify the page structure exists
      expect(find.byType(MathPage), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('MathPage has all 7 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MathPage()));
      await tester.pumpAndSettle();

      // Verify all tab labels are present
      expect(find.text('General'), findsWidgets);
      expect(find.text('Algebra'), findsWidgets);
      expect(find.text('Calculus'), findsWidgets);
      expect(find.text('Statistics'), findsWidgets);
      expect(find.text('Discrete'), findsWidgets);
      expect(find.text('Graphing'), findsWidgets);
      expect(find.text('Tools'), findsWidgets);
    });

    testWidgets('Tab navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MathPage()));
      await tester.pumpAndSettle();

      // Start on General tab
      expect(find.byType(TabBarView), findsOneWidget);

      // Navigate to Algebra tab
      await tester.tap(find.text('Algebra').first);
      await tester.pumpAndSettle();

      // Navigate to Calculus tab
      await tester.tap(find.text('Calculus').first);
      await tester.pumpAndSettle();

      // Navigate to Statistics tab
      await tester.tap(find.text('Statistics').first);
      await tester.pumpAndSettle();

      // Navigation should work without errors
      expect(find.byType(MathPage), findsOneWidget);
    });

    testWidgets('MathPage has app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MathPage()));
      await tester.pumpAndSettle();

      // Should have an AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
