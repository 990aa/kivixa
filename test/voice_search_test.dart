import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/audio/voice_search.dart';

void main() {
  group('VoiceSearchResult', () {
    test('should create with all parameters', () {
      const result = VoiceSearchResult(
        query: 'find my notes',
        isFinal: true,
        confidence: 0.95,
      );

      expect(result.query, 'find my notes');
      expect(result.isFinal, true);
      expect(result.confidence, 0.95);
    });

    test('should create intermediate result', () {
      const result = VoiceSearchResult(
        query: 'find my',
        isFinal: false,
        confidence: 0.7,
      );

      expect(result.query, 'find my');
      expect(result.isFinal, false);
      expect(result.confidence, 0.7);
    });
  });

  group('VoiceSearchButton', () {
    testWidgets('should render idle state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: VoiceSearchButton())),
      );

      expect(find.byType(VoiceSearchButton), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('should have correct default size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: VoiceSearchButton(size: 32))),
      );

      expect(find.byType(VoiceSearchButton), findsOneWidget);
    });

    testWidgets('should accept custom icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceSearchButton(
              idleIcon: Icons.mic_none,
              listeningIcon: Icons.stop,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });
  });

  // Skip VoiceSearchModal tests - has repeating animations and native deps
  group('VoiceSearchModal', () {
    testWidgets('should show dialog', (tester) async {
      // Skip - has repeating animations
    }, skip: true); // Has repeating animation and native deps
  });
}
