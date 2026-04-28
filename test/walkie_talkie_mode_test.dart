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

  group('WalkieTalkieMode', () {
    test('should accept onSendMessage callback', () {
      Future<String> sendMessage(String input) async => 'echo:$input';

      final widget = WalkieTalkieMode(onSendMessage: sendMessage);
      expect(widget.onSendMessage, same(sendMessage));
    });

    test('should accept optional onExit callback', () {
      void onExit() {}

      final widget = WalkieTalkieMode(
        onSendMessage: (input) async => input,
        onExit: onExit,
      );

      expect(widget.onExit, same(onExit));
    });
  });
}
