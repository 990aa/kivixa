// File deleted: ink_audio_sync.dart
import 'dart:collection';
import 'dart:ui';

/// Represents a single ink stroke with a timestamp (ms since audio start)
class SyncedInkStroke {
  final int timestamp;
  final List<Offset> points;
  SyncedInkStroke({required this.timestamp, required this.points});
}

/// Represents an audio segment with associated ink strokes
class InkAudioSyncSession {
  final String audioFilePath;
  final List<SyncedInkStroke> strokes;
  InkAudioSyncSession({required this.audioFilePath}) : strokes = [];

  void addStroke(List<Offset> points, int timestamp) {
    strokes.add(SyncedInkStroke(timestamp: timestamp, points: points));
  }

  /// Get all strokes that occurred within a time window (ms)
  List<SyncedInkStroke> getStrokesInWindow(int startMs, int endMs) {
    return strokes
        .where((s) => s.timestamp >= startMs && s.timestamp <= endMs)
        .toList();
  }
}

/// Service to synchronize ink strokes with audio playback/recording
class InkAudioSync {
  final Map<String, InkAudioSyncSession> _sessions = HashMap();

  /// Start a new sync session for an audio file
  void startSession(String audioFilePath) {
    _sessions[audioFilePath] = InkAudioSyncSession(
      audioFilePath: audioFilePath,
    );
  }

  /// Add a stroke to the current session
  void addStroke(String audioFilePath, List<Offset> points, int timestamp) {
    final session = _sessions[audioFilePath];
    if (session != null) {
      session.addStroke(points, timestamp);
    }
  }

  /// Get all strokes for an audio file in a time window
  List<SyncedInkStroke> getStrokes(
    String audioFilePath,
    int startMs,
    int endMs,
  ) {
    final session = _sessions[audioFilePath];
    if (session == null) return [];
    return session.getStrokesInWindow(startMs, endMs);
  }

  /// End and remove a session
  void endSession(String audioFilePath) {
    _sessions.remove(audioFilePath);
  }
}
