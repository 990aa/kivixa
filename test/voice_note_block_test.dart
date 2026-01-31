import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/audio/voice_note_block.dart';

void main() {
  group('TranscriptSegment', () {
    test('should create with all parameters', () {
      const segment = TranscriptSegment(
        text: 'Hello world',
        startTime: 0.0,
        endTime: 1.5,
        confidence: 0.95,
        speakerId: 'Speaker 1',
      );

      expect(segment.text, 'Hello world');
      expect(segment.startTime, 0.0);
      expect(segment.endTime, 1.5);
      expect(segment.confidence, 0.95);
      expect(segment.speakerId, 'Speaker 1');
    });

    test('should create without speakerId', () {
      const segment = TranscriptSegment(
        text: 'Hello',
        startTime: 0.0,
        endTime: 0.5,
        confidence: 0.9,
      );

      expect(segment.speakerId, isNull);
    });

    test('should use default confidence of 1.0', () {
      const segment = TranscriptSegment(
        text: 'Test',
        startTime: 0.0,
        endTime: 0.5,
      );

      expect(segment.confidence, 1.0);
    });
  });

  group('VoiceNoteData', () {
    test('should create with required parameters', () {
      const data = VoiceNoteData(
        samples: [0.1, 0.2, 0.3],
        duration: 3.0,
        sampleRate: 16000,
        segments: [],
        fullText: '',
        waveformPeaks: [],
      );

      expect(data.samples.length, 3);
      expect(data.duration, 3.0);
      expect(data.sampleRate, 16000);
    });

    test('should create with transcript segments', () {
      const data = VoiceNoteData(
        samples: [0.5],
        duration: 1.0,
        sampleRate: 16000,
        segments: [
          TranscriptSegment(
            text: 'Test',
            startTime: 0.0,
            endTime: 0.5,
            confidence: 0.9,
          ),
        ],
        fullText: 'Test',
        waveformPeaks: [0.5],
      );

      expect(data.segments.length, 1);
      expect(data.fullText, 'Test');
    });

    test('should have static empty constant', () {
      const data = VoiceNoteData.empty;

      expect(data.samples, isEmpty);
      expect(data.duration, 0);
      expect(data.sampleRate, 16000);
      expect(data.segments, isEmpty);
      expect(data.fullText, '');
      expect(data.waveformPeaks, isEmpty);
    });

    test('getSegmentAtTime should return correct segment', () {
      const data = VoiceNoteData(
        samples: [],
        duration: 5.0,
        sampleRate: 16000,
        segments: [
          TranscriptSegment(text: 'First', startTime: 0.0, endTime: 2.0),
          TranscriptSegment(text: 'Second', startTime: 2.0, endTime: 5.0),
        ],
        fullText: 'First Second',
        waveformPeaks: [],
      );

      final segment = data.getSegmentAtTime(1.0);
      expect(segment?.text, 'First');

      final segment2 = data.getSegmentAtTime(3.0);
      expect(segment2?.text, 'Second');

      final noSegment = data.getSegmentAtTime(10.0);
      expect(noSegment, isNull);
    });

    test('search should find matching segments', () {
      const data = VoiceNoteData(
        samples: [],
        duration: 5.0,
        sampleRate: 16000,
        segments: [
          TranscriptSegment(text: 'Hello world', startTime: 0.0, endTime: 2.0),
          TranscriptSegment(
            text: 'Goodbye world',
            startTime: 2.0,
            endTime: 5.0,
          ),
        ],
        fullText: 'Hello world Goodbye world',
        waveformPeaks: [],
      );

      final results = data.search('world');
      expect(results.length, 2);

      final helloResults = data.search('Hello');
      expect(helloResults.length, 1);
      expect(helloResults.first.text, 'Hello world');
    });
  });

  group('VoiceNoteBlock', () {
    const testData = VoiceNoteData(
      samples: [0.1, 0.2, 0.3, 0.4, 0.5],
      duration: 5.0,
      sampleRate: 16000,
      segments: [
        TranscriptSegment(
          text: 'Hello world',
          startTime: 0.0,
          endTime: 2.0,
          confidence: 0.9,
        ),
        TranscriptSegment(
          text: 'This is a test',
          startTime: 2.0,
          endTime: 5.0,
          confidence: 0.85,
        ),
      ],
      fullText: 'Hello world This is a test',
      waveformPeaks: [0.3, 0.5, 0.8, 0.6, 0.4],
    );

    testWidgets('should render with data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoiceNoteBlock(data: testData)),
        ),
      );

      expect(find.byType(VoiceNoteBlock), findsOneWidget);
    });

    testWidgets('should render without data (recording mode)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: VoiceNoteBlock())),
      );

      expect(find.byType(VoiceNoteBlock), findsOneWidget);
    });

    testWidgets('should show play button when data provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoiceNoteBlock(data: testData)),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should accept showTranscript parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceNoteBlock(data: testData, showTranscript: true),
          ),
        ),
      );

      expect(find.byType(VoiceNoteBlock), findsOneWidget);
    });

    testWidgets('should accept enableKaraokeMode parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceNoteBlock(data: testData, enableKaraokeMode: true),
          ),
        ),
      );

      expect(find.byType(VoiceNoteBlock), findsOneWidget);
    });

    testWidgets('should accept searchQuery parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceNoteBlock(
              data: testData,
              showTranscript: true,
              searchQuery: 'world',
            ),
          ),
        ),
      );

      expect(find.byType(VoiceNoteBlock), findsOneWidget);
    });

    testWidgets('should accept initiallyExpanded parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceNoteBlock(data: testData, initiallyExpanded: true),
          ),
        ),
      );

      expect(find.byType(VoiceNoteBlock), findsOneWidget);
    });

    testWidgets('should accept onRecordingComplete callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceNoteBlock(
              onRecordingComplete: (data) {
                // Callback provided - would be called when recording completes
              },
            ),
          ),
        ),
      );

      expect(find.byType(VoiceNoteBlock), findsOneWidget);
    });

    testWidgets('should accept onPositionChanged callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceNoteBlock(
              data: testData,
              onPositionChanged: (pos) {
                // Callback provided - would be called when position changes
              },
            ),
          ),
        ),
      );

      expect(find.byType(VoiceNoteBlock), findsOneWidget);
    });
  });
}
