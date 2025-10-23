import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kivixa/main.dart';
import 'package:kivixa/database/database_helper.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory testDir;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('kivixa_widget_test_');
    await DatabaseHelper.initialize(testDir.path);
  });

  tearDown(() async {
    await DatabaseHelper.close();
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('Home Screen Integration', () {
    testWidgets('should show drawer menu', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify drawer items
      expect(find.text('Kivixa'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('File Browser'), findsOneWidget);
      expect(find.text('Archive Management'), findsOneWidget);
      expect(find.text('Resource Cleanup'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('should navigate to file browser from drawer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap file browser
      await tester.tap(find.text('File Browser'));
      await tester.pumpAndSettle();

      // Should navigate to file browser screen
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('should navigate to archive management from drawer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap archive management
      await tester.tap(find.text('Archive Management'));
      await tester.pumpAndSettle();

      // Should navigate to archive management screen
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('should trigger resource cleanup from drawer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap resource cleanup
      await tester.tap(find.text('Resource Cleanup'));
      await tester.pumpAndSettle();

      // Should show snackbar
      expect(find.text('Cleanup completed'), findsOneWidget);
    });

    testWidgets('should show about dialog from drawer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap about
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      // Should show about dialog
      expect(find.text('Kivixa'), findsWidgets);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Quick Action Buttons', () {
    testWidgets('should show all quick action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Import PDF'), findsOneWidget);
      expect(find.text('Markdown'), findsOneWidget);
      expect(find.text('Canvas'), findsOneWidget);
    });

    testWidgets('should show markdown creation dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap markdown button
      await tester.tap(find.text('Markdown'));
      await tester.pumpAndSettle();

      // Should show name input dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Create Markdown Document'), findsOneWidget);
    });

    testWidgets('should show canvas type selection dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap canvas button
      await tester.tap(find.text('Canvas'));
      await tester.pumpAndSettle();

      // Should show canvas type dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Choose Canvas Type'), findsOneWidget);
      expect(find.text('Infinite Canvas'), findsOneWidget);
      expect(find.text('Drawing Canvas'), findsOneWidget);
    });
  });

  group('File Browser UI', () {
    testWidgets('should show folders section', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Folders'), findsOneWidget);
      expect(find.byIcon(Icons.create_new_folder), findsOneWidget);
    });

    testWidgets('should show documents section', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Documents'), findsOneWidget);
    });

    testWidgets('should show folder creation button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.create_new_folder), findsOneWidget);
    });

    testWidgets('should show refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('Folder Management', () {
    testWidgets('should show folder creation dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap folder creation button
      await tester.tap(find.byIcon(Icons.create_new_folder));
      await tester.pumpAndSettle();

      // Should show dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Create Folder'), findsOneWidget);
    });

    testWidgets('should create folder with valid name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Open folder creation dialog
      await tester.tap(find.byIcon(Icons.create_new_folder));
      await tester.pumpAndSettle();

      // Enter folder name
      await tester.enterText(find.byType(TextField), 'Test Folder');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Dialog should close and folder should be created
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('should not create folder with empty name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Open folder creation dialog
      await tester.tap(find.byIcon(Icons.create_new_folder));
      await tester.pumpAndSettle();

      // Try to create without entering name
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Dialog should still be open
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('App Lifecycle', () {
    testWidgets('should initialize resource cleanup', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // App should launch without error
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should handle app pause and resume', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Simulate app lifecycle changes
      final binding = tester.binding;
      await binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      await binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // App should still be functional
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Navigation', () {
    testWidgets('should have proper navigation structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Check that MaterialApp is present
      expect(find.byType(MaterialApp), findsOneWidget);

      // Check that home screen is shown
      expect(find.text('Kivixa'), findsOneWidget);
    });

    testWidgets('should close drawer when tapping home', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Drawer should be closed
      expect(find.text('Advanced Drawing & Canvas'), findsNothing);
    });
  });

  group('UI Responsiveness', () {
    testWidgets('should show loading indicator during initial load', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      // Before pumping and settling, might see loading indicator
      // After settling, content should be shown
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('should handle refresh action', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // UI should still be functional
      expect(find.text('Kivixa'), findsOneWidget);
    });
  });

  group('Theme and Styling', () {
    testWidgets('should use Material 3 design', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, true);
    });

    testWidgets('should have proper app bar styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Kivixa'), findsOneWidget);
    });
  });

  group('Error Handling', () {
    testWidgets('should handle database errors gracefully', (
      WidgetTester tester,
    ) async {
      // Close database to simulate error
      await DatabaseHelper.close();

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // App should still launch (with error handling)
      expect(find.byType(MaterialApp), findsOneWidget);

      // Reinitialize for cleanup
      await DatabaseHelper.initialize(testDir.path);
    });
  });
}
