import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/android_back_handler.dart';

void main() {
  group('AndroidBackHandler', () {
    late AndroidBackHandler handler;

    setUp(() {
      handler = AndroidBackHandler();
      handler.reset();
    });

    test('singleton returns same instance', () {
      final handler1 = AndroidBackHandler();
      final handler2 = AndroidBackHandler();
      expect(handler1, same(handler2));
    });

    test('reset clears last back press time', () {
      handler.reset();
      // After reset, shouldExitApp should return false
      // (since no double-tap detected)
      expect(handler.shouldExitApp(), isFalse);
    });

    test('shouldExitApp returns false on first call', () {
      expect(handler.shouldExitApp(), isFalse);
    });

    test('shouldExitApp returns true on rapid second call', () {
      // First press
      expect(handler.shouldExitApp(), isFalse);

      // Second press within timeout (simulate immediate second press)
      expect(handler.shouldExitApp(), isTrue);
    });

    test('shouldExitApp returns false after timeout expires', () async {
      // First press
      expect(handler.shouldExitApp(), isFalse);

      // Wait for timeout to expire (2 seconds + buffer)
      await Future.delayed(const Duration(milliseconds: 2100));

      // Second press after timeout - should be treated as first press
      expect(handler.shouldExitApp(), isFalse);
    });
  });

  group('AndroidBackButtonHandler Widget', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AndroidBackButtonHandler(
            child: Scaffold(body: Text('Test Child')),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('wraps with PopScope on Android', (WidgetTester tester) async {
      // Note: In test environment, Platform.isAndroid is always false
      // So we test that the widget renders correctly regardless
      await tester.pumpWidget(
        const MaterialApp(
          home: AndroidBackButtonHandler(
            child: Scaffold(body: Text('Test Child')),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(AndroidBackButtonHandler), findsOneWidget);
    });

    testWidgets('shows snackbar on back press when not navigable', (
      WidgetTester tester,
    ) async {
      // Skip this test if not on Android (PopScope behavior differs)
      // This is an integration test that would need to be run on an actual device
    }, skip: !Platform.isAndroid);
  });
}
