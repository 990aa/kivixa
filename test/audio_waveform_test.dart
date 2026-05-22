import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/audio/audio_waveform.dart';

void main() {
  group('WaveformStyle', () {
    test('should have all expected styles', () {
      expect(WaveformStyle.values.length, 4);
      expect(WaveformStyle.bars, isNotNull);
      expect(WaveformStyle.line, isNotNull);
      expect(WaveformStyle.circular, isNotNull);
      expect(WaveformStyle.orb, isNotNull);
    });
  });

  group('AudioWaveform', () {
    testWidgets('should render with default parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AudioWaveform(dataStream: Stream.empty()))),
      );

      expect(find.byType(AudioWaveform), findsOneWidget);
    });

    testWidgets('should render with custom height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AudioWaveform(dataStream: const Stream.empty(), height: 100))),
      );

      expect(find.byType(AudioWaveform), findsOneWidget);
    });

    testWidgets('should render with custom width', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AudioWaveform(dataStream: const Stream.empty(), width: 200))),
      );

      expect(find.byType(AudioWaveform), findsOneWidget);
    });

    testWidgets('should render with bar style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AudioWaveform(dataStream: const Stream.empty(), style: WaveformStyle.bars)),
        ),
      );

      expect(find.byType(AudioWaveform), findsOneWidget);
    });

    testWidgets('should render with line style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AudioWaveform(dataStream: const Stream.empty(), style: WaveformStyle.line)),
        ),
      );

      expect(find.byType(AudioWaveform), findsOneWidget);
    });

    testWidgets('should render with circular style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AudioWaveform(dataStream: const Stream.empty(), style: WaveformStyle.circular)),
        ),
      );

      expect(find.byType(AudioWaveform), findsOneWidget);
    });

    testWidgets('should accept custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AudioWaveform(dataStream: const Stream.empty(), color: Colors.blue)),
        ),
      );

      expect(find.byType(AudioWaveform), findsOneWidget);
    });

    testWidgets('should accept secondary color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AudioWaveform(dataStream: const Stream.empty(), secondaryColor: Colors.red)),
        ),
      );

      expect(find.byType(AudioWaveform), findsOneWidget);
    });

    testWidgets('should accept custom bar count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AudioWaveform(dataStream: const Stream.empty(), barCount: 64))),
      );

      expect(find.byType(AudioWaveform), findsOneWidget);
    });

    testWidgets('should respect animateIdle flag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AudioWaveform(dataStream: const Stream.empty(), animateIdle: false)),
        ),
      );

      expect(find.byType(AudioWaveform), findsOneWidget);
    });
  });
}
