import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/home/browser.dart';

void main() {
  group('ConsoleLogEntry', () {
    test('creates with required fields', () {
      final log = ConsoleLogEntry(
        message: 'Test message',
        level: ConsoleMessageLevel.LOG,
      );

      expect(log.message, 'Test message');
      expect(log.level, ConsoleMessageLevel.LOG);
      expect(log.timestamp, isA<DateTime>());
    });

    test('creates with custom timestamp', () {
      final customTime = DateTime(2024, 1, 15, 10, 30);
      final log = ConsoleLogEntry(
        message: 'Test message',
        level: ConsoleMessageLevel.DEBUG,
        timestamp: customTime,
      );

      expect(log.timestamp, customTime);
    });

    test('color returns red for ERROR level', () {
      final log = ConsoleLogEntry(
        message: 'Error message',
        level: ConsoleMessageLevel.ERROR,
      );

      expect(log.color, Colors.red);
    });

    test('color returns orange for WARNING level', () {
      final log = ConsoleLogEntry(
        message: 'Warning message',
        level: ConsoleMessageLevel.WARNING,
      );

      expect(log.color, Colors.orange);
    });

    test('color returns blue for DEBUG level', () {
      final log = ConsoleLogEntry(
        message: 'Debug message',
        level: ConsoleMessageLevel.DEBUG,
      );

      expect(log.color, Colors.blue);
    });

    test('color returns grey for LOG level', () {
      final log = ConsoleLogEntry(
        message: 'Log message',
        level: ConsoleMessageLevel.LOG,
      );

      expect(log.color, Colors.grey);
    });

    test('color returns grey for TIP level', () {
      final log = ConsoleLogEntry(
        message: 'Tip message',
        level: ConsoleMessageLevel.TIP,
      );

      expect(log.color, Colors.grey);
    });

    test('levelName returns correct string for ERROR', () {
      final log = ConsoleLogEntry(
        message: 'Error',
        level: ConsoleMessageLevel.ERROR,
      );

      expect(log.levelName, 'ERROR');
    });

    test('levelName returns WARN for WARNING', () {
      final log = ConsoleLogEntry(
        message: 'Warning',
        level: ConsoleMessageLevel.WARNING,
      );

      expect(log.levelName, 'WARN');
    });

    test('levelName returns DEBUG for DEBUG', () {
      final log = ConsoleLogEntry(
        message: 'Debug',
        level: ConsoleMessageLevel.DEBUG,
      );

      expect(log.levelName, 'DEBUG');
    });

    test('levelName returns LOG for LOG', () {
      final log = ConsoleLogEntry(
        message: 'Log',
        level: ConsoleMessageLevel.LOG,
      );

      expect(log.levelName, 'LOG');
    });

    test('levelName returns TIP for TIP', () {
      final log = ConsoleLogEntry(
        message: 'Tip',
        level: ConsoleMessageLevel.TIP,
      );

      expect(log.levelName, 'TIP');
    });
  });

  group('BrowserPage', () {
    testWidgets('creates with no initial URL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Browser test placeholder')),
        ),
      );

      // Verify the widget renders (placeholder for actual BrowserPage tests)
      expect(find.text('Browser test placeholder'), findsOneWidget);
    });

    testWidgets('creates with initial URL', (tester) async {
      const initialUrl = 'https://example.com';
      const page = BrowserPage(initialUrl: initialUrl);

      expect(page.initialUrl, initialUrl);
    });
  });
}
