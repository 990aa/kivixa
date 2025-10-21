// Widget tests for Kivixa app
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kivixa/main.dart';

void main() {
  testWidgets('App launches and shows home screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for async data loading
    await tester.pumpAndSettle();

    // Verify that the app title is displayed in the AppBar
    expect(find.text('Kivixa'), findsAtLeastNWidgets(1));

    // Verify the app has a Scaffold
    expect(find.byType(Scaffold), findsOneWidget);
  });
  testWidgets('Home screen shows quick action buttons', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for loading to complete
    await tester.pumpAndSettle();

    // Verify that quick action buttons are displayed
    expect(find.text('Import PDF'), findsOneWidget);
    expect(find.text('Markdown'), findsOneWidget);
    expect(find.text('Canvas'), findsOneWidget);
  });
  testWidgets('Home screen has folders section', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for loading
    await tester.pumpAndSettle();

    // Verify that the folders section is displayed
    expect(find.text('Folders'), findsOneWidget);

    // Verify new folder button exists
    expect(find.byIcon(Icons.create_new_folder), findsOneWidget);
  });

  testWidgets('Refresh button is present', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for loading
    await tester.pumpAndSettle();

    // Verify refresh button is present
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
