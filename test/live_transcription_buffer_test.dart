import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/audio/live_transcription_buffer.dart';

String _applyEdit(String source, LiveTranscriptionEdit edit) {
  return source.replaceRange(
    edit.startOffset,
    edit.endOffset,
    edit.replacementText,
  );
}

void main() {
  group('LiveTranscriptionBuffer', () {
    test('replaces interim partial dictation in place', () {
      final buffer = LiveTranscriptionBuffer();
      var text = '';

      buffer.startSession(anchorOffset: 0);

      final firstPartial = buffer.buildEdit(
        text: 'hello',
        isFinal: false,
        currentTextLength: text.length,
      );
      expect(firstPartial, isNotNull);
      text = _applyEdit(text, firstPartial!);
      expect(text, 'hello');

      final secondPartial = buffer.buildEdit(
        text: 'hello world',
        isFinal: false,
        currentTextLength: text.length,
      );
      expect(secondPartial, isNotNull);
      text = _applyEdit(text, secondPartial!);
      expect(text, 'hello world');

      final committed = buffer.buildEdit(
        text: 'hello world',
        isFinal: true,
        currentTextLength: text.length,
      );
      expect(committed, isNotNull);
      text = _applyEdit(text, committed!);
      expect(text, 'hello world ');

      final duplicateFinal = buffer.buildEdit(
        text: 'hello world',
        isFinal: true,
        currentTextLength: text.length,
      );
      expect(duplicateFinal, isNull);

      final nextPartial = buffer.buildEdit(
        text: 'again',
        isFinal: false,
        currentTextLength: text.length,
      );
      expect(nextPartial, isNotNull);
      text = _applyEdit(text, nextPartial!);
      expect(text, 'hello world again');
    });

    test('falls back to provided anchor when session was not started', () {
      final buffer = LiveTranscriptionBuffer();

      final edit = buffer.buildEdit(
        text: 'draft',
        isFinal: false,
        currentTextLength: 10,
        fallbackAnchorOffset: 4,
      );

      expect(edit, isNotNull);
      expect(edit!.startOffset, 4);
      expect(edit.replacedLength, 0);
      expect(edit.replacementText, 'draft');
    });

    test('reset clears duplicate-final suppression', () {
      final buffer = LiveTranscriptionBuffer();
      var text = '';

      buffer.startSession(anchorOffset: 0);
      final firstFinal = buffer.buildEdit(
        text: 'done',
        isFinal: true,
        currentTextLength: text.length,
      );
      expect(firstFinal, isNotNull);
      text = _applyEdit(text, firstFinal!);

      final duplicateFinal = buffer.buildEdit(
        text: 'done',
        isFinal: true,
        currentTextLength: text.length,
      );
      expect(duplicateFinal, isNull);

      buffer.reset();
      buffer.startSession(anchorOffset: 0);

      final afterReset = buffer.buildEdit(
        text: 'done',
        isFinal: true,
        currentTextLength: text.length,
      );
      expect(afterReset, isNotNull);
    });
  });
}
