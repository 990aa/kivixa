import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/audio/walkie_talkie_mode.dart';

void main() {
  group('ConversationTurn', () {
    test('should create user turn', () {
      final turn = ConversationTurn(
        isUser: true,
        text: 'Hello AI',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      expect(turn.isUser, true);
      expect(turn.text, 'Hello AI');
      expect(turn.timestamp.hour, 10);
      expect(turn.timestamp.minute, 30);
    });

    test('should create AI turn', () {
      final turn = ConversationTurn(
        isUser: false,
        text: 'Hello human',
        timestamp: DateTime.now(),
      );

      expect(turn.isUser, false);
      expect(turn.text, 'Hello human');
    });
  });

  group('WalkieTalkieState', () {
    test('should have all expected states', () {
      expect(WalkieTalkieState.values.length, 5);
      expect(WalkieTalkieState.idle, isNotNull);
      expect(WalkieTalkieState.listening, isNotNull);
      expect(WalkieTalkieState.processing, isNotNull);
      expect(WalkieTalkieState.responding, isNotNull);
      expect(WalkieTalkieState.paused, isNotNull);
    });
  });

  // Tests with animations and native deps are skipped individually
  group('WalkieTalkieMode', () {
    testWidgets('should render', (tester) async {
      // Skip - has repeating animations and native deps
    }, skip: true); // Has repeating animations and native deps

    testWidgets(
      'should accept onSendMessage callback',
      (tester) async {
        // Skip - has repeating animations and native deps
      },
      skip: true, // Has repeating animations and native deps
    );

    testWidgets(
      'should accept onClose callback',
      (tester) async {
        // Skip - has repeating animations and native deps
      },
      skip: true, // Has repeating animations and native deps
    );

    testWidgets(
      'should accept title parameter',
      (tester) async {
        // Skip - has repeating animations and native deps
      },
      skip: true, // Has repeating animations and native deps
    );
  });
}
