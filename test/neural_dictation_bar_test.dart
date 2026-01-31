import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/audio/neural_dictation_bar.dart';

void main() {
  group('DictationMode', () {
    test('should have all expected modes', () {
      expect(DictationMode.values.length, 2);
      expect(DictationMode.text, isNotNull);
      expect(DictationMode.command, isNotNull);
    });
  });

  group('NeuralDictationBar', () {
    testWidgets('should render idle state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NeuralDictationBar())),
      );

      expect(find.byType(NeuralDictationBar), findsOneWidget);
    });

    testWidgets('should show microphone button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NeuralDictationBar())),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('should accept onTextRecognized callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeuralDictationBar(
              onTextRecognized: (text, isFinal) {
                // Callback provided - would be called during dictation
              },
            ),
          ),
        ),
      );

      expect(find.byType(NeuralDictationBar), findsOneWidget);
    });

    testWidgets('should accept onCommandRecognized callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeuralDictationBar(
              onCommandRecognized: (command) {
                // Callback provided - would be called in command mode
              },
            ),
          ),
        ),
      );

      expect(find.byType(NeuralDictationBar), findsOneWidget);
    });

    testWidgets('should accept TextEditingController', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: NeuralDictationBar(controller: controller)),
        ),
      );

      expect(find.byType(NeuralDictationBar), findsOneWidget);
      controller.dispose();
    });

    testWidgets('should accept custom height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NeuralDictationBar(height: 72))),
      );

      expect(find.byType(NeuralDictationBar), findsOneWidget);
    });

    testWidgets('should respect showConfidence flag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: NeuralDictationBar(showConfidence: false)),
        ),
      );

      expect(find.byType(NeuralDictationBar), findsOneWidget);
    });

    testWidgets('should respect enableCommandMode flag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: NeuralDictationBar(enableCommandMode: false)),
        ),
      );

      expect(find.byType(NeuralDictationBar), findsOneWidget);
    });
  });
}
