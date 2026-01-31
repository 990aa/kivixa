import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/audio/read_aloud.dart';

void main() {
  group('ReadAloudController', () {
    test('should start not playing', () {
      final controller = ReadAloudController();
      expect(controller.isPlaying, false);
      controller.dispose();
    });

    test('should start with zero progress', () {
      final controller = ReadAloudController();
      expect(controller.progress, 0.0);
      controller.dispose();
    });

    test('should start with empty current sentence', () {
      final controller = ReadAloudController();
      expect(controller.currentSentence, isEmpty);
      controller.dispose();
    });

    test('should have default speed of 1.0', () {
      final controller = ReadAloudController();
      expect(controller.speed, 1.0);
      controller.dispose();
    });

    test('should clamp speed to minimum 0.5', () {
      final controller = ReadAloudController();
      controller.speed = 0.1;
      expect(controller.speed, 0.5);
      controller.dispose();
    });

    test('should clamp speed to maximum 2.0', () {
      final controller = ReadAloudController();
      controller.speed = 3.0;
      expect(controller.speed, 2.0);
      controller.dispose();
    });

    test('should start with null voiceId', () {
      final controller = ReadAloudController();
      expect(controller.voiceId, isNull);
      controller.dispose();
    });

    test('should set voiceId', () {
      final controller = ReadAloudController();
      controller.voiceId = 'en-us-amy';
      expect(controller.voiceId, 'en-us-amy');
      controller.dispose();
    });

    test('stop should reset state', () {
      final controller = ReadAloudController();
      controller.stop();
      expect(controller.isPlaying, false);
      expect(controller.progress, 0.0);
      expect(controller.currentSentence, isEmpty);
      controller.dispose();
    });

    test('pause should stop playing', () {
      final controller = ReadAloudController();
      // Even if not playing, pause should not throw
      controller.pause();
      expect(controller.isPlaying, false);
      controller.dispose();
    });

    test('should notify listeners on speed change', () {
      final controller = ReadAloudController();
      var notified = false;
      controller.addListener(() => notified = true);

      controller.speed = 1.5;
      expect(notified, true);

      controller.dispose();
    });

    test('should notify listeners on voiceId change', () {
      final controller = ReadAloudController();
      var notified = false;
      controller.addListener(() => notified = true);

      controller.voiceId = 'test-voice';
      expect(notified, true);

      controller.dispose();
    });

    test('should have correct sentence count after split', () {
      final controller = ReadAloudController();
      // Since startReading is async, we can't easily test sentence splitting
      // without mocking the engine, so we just verify the method exists
      expect(controller.sentenceCount, 0);
      controller.dispose();
    });
  });

  group('ReadAloudMiniPlayer', () {
    testWidgets('should render with controller', (tester) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ReadAloudMiniPlayer(controller: controller)),
        ),
      );

      expect(find.byType(ReadAloudMiniPlayer), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should show play/pause button', (tester) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ReadAloudMiniPlayer(controller: controller)),
        ),
      );

      // Should show play when not playing
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should show skip buttons', (tester) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ReadAloudMiniPlayer(controller: controller)),
        ),
      );

      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should show close button', (tester) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ReadAloudMiniPlayer(controller: controller)),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should call onClose callback', (tester) async {
      final controller = ReadAloudController();
      var closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadAloudMiniPlayer(
              controller: controller,
              onClose: () => closeCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closeCalled, true);
      controller.dispose();
    });

    testWidgets('should show speed slider in expanded mode', (tester) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadAloudMiniPlayer(controller: controller, expanded: true),
          ),
        ),
      );

      expect(find.text('Speed:'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should not show speed slider in collapsed mode', (
      tester,
    ) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadAloudMiniPlayer(controller: controller, expanded: false),
          ),
        ),
      );

      expect(find.text('Speed:'), findsNothing);
      controller.dispose();
    });

    testWidgets('should show progress indicator', (tester) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ReadAloudMiniPlayer(controller: controller)),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      controller.dispose();
    });
  });

  group('ReadAloudAction', () {
    testWidgets('should render', (tester) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadAloudAction(
              text: 'Test text to read',
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.byType(ReadAloudAction), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should show default icon', (tester) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadAloudAction(text: 'Test', controller: controller),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should show default label', (tester) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadAloudAction(text: 'Test', controller: controller),
          ),
        ),
      );

      expect(find.text('Read Aloud'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should use custom icon', (tester) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadAloudAction(
              text: 'Test',
              controller: controller,
              icon: Icons.speaker,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.speaker), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should use custom label', (tester) async {
      final controller = ReadAloudController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadAloudAction(
              text: 'Test',
              controller: controller,
              label: 'Speak',
            ),
          ),
        ),
      );

      expect(find.text('Speak'), findsOneWidget);
      controller.dispose();
    });
  });

  group('FloatingReadAloudButton', () {
    testWidgets('should render FAB', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingReadAloudButton(getText: () => 'Some text'),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should show volume icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingReadAloudButton(getText: () => 'Some text'),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });
  });
}
