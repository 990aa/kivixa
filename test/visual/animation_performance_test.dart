import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Splash animation is smooth', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    stopwatch.stop();
    expect(
      stopwatch.elapsedMilliseconds < 1200,
      true,
      reason: 'Splash animation should be smooth',
    );
  });
}
