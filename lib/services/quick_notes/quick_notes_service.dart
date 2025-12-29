import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A quick note that will be auto-deleted after a certain time.
class QuickNote {
  QuickNote({
    required this.id,
    required this.content,
    required this.createdAt,
    this.isHandwritten = false,
    this.handwrittenData,
  });

  final String id;
  String content;
  final DateTime createdAt;
  final bool isHandwritten;
  final String? handwrittenData;

  /// Time remaining before auto-delete
  Duration remainingTime(Duration autoDeleteDuration) {
    final expiresAt = createdAt.add(autoDeleteDuration);
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether this note has expired
  bool isExpired(Duration autoDeleteDuration) {
    return remainingTime(autoDeleteDuration) == Duration.zero;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'isHandwritten': isHandwritten,
    'handwrittenData': handwrittenData,
  };

  factory QuickNote.fromJson(Map<String, dynamic> json) {
    return QuickNote(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isHandwritten: json['isHandwritten'] as bool? ?? false,
      handwrittenData: json['handwrittenData'] as String?,
    );
  }

  QuickNote copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    bool? isHandwritten,
    String? handwrittenData,
  }) {
    return QuickNote(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isHandwritten: isHandwritten ?? this.isHandwritten,
      handwrittenData: handwrittenData ?? this.handwrittenData,
    );
  }
}

/// Service for managing quick notes with auto-delete functionality.
/// PERFORMANCE: Uses cached SharedPreferences and debounced saves
class QuickNotesService extends ChangeNotifier {
  QuickNotesService._();

  static final _instance = QuickNotesService._();
  static QuickNotesService get instance => _instance;

  // Settings
  var _autoDeleteDuration = const Duration(hours: 24);
  var _autoDeleteEnabled = true;

  // State
  final List<QuickNote> _notes = [];
  Timer? _cleanupTimer;
  var _initialized = false;

  // PERFORMANCE: Cache SharedPreferences instance and debounce saves
  SharedPreferences? _prefs;
  Timer? _saveNotesDebounce;
  Timer? _saveSettingsDebounce;
  static const _debounceDelay = Duration(milliseconds: 500);

  // Persistence keys
  static const _notesKey = 'quick_notes';
  static const _settingsKey = 'quick_notes_settings';

  // Getters
  List<QuickNote> get notes => List.unmodifiable(_notes);
  Duration get autoDeleteDuration => _autoDeleteDuration;
  bool get autoDeleteEnabled => _autoDeleteEnabled;
  bool get isEmpty => _notes.isEmpty;
  int get count => _notes.length;

  /// Get only non-expired notes
  List<QuickNote> get activeNotes {
    if (!_autoDeleteEnabled) return notes;
    return _notes
        .where((note) => !note.isExpired(_autoDeleteDuration))
        .toList();
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    // PERFORMANCE: Pre-cache SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    await _loadSettings();
    await _loadNotes();
    _startCleanupTimer();
    _initialized = true;
  }

  /// Add a new quick note
  QuickNote addNote({
    required String content,
    bool isHandwritten = false,
    String? handwrittenData,
  }) {
    final note = QuickNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
      isHandwritten: isHandwritten,
      handwrittenData: handwrittenData,
    );
    _notes.insert(0, note);
    _saveNotes();
    notifyListeners();
    return note;
  }

  /// Update an existing note
  void updateNote(String id, {String? content, String? handwrittenData}) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) return;

    _notes[index] = _notes[index].copyWith(
      content: content,
      handwrittenData: handwrittenData,
    );
    _saveNotes();
    notifyListeners();
  }

  /// Delete a specific note
  void deleteNote(String id) {
    _notes.removeWhere((note) => note.id == id);
    _saveNotes();
    notifyListeners();
  }

  /// Clear all notes
  void clearAllNotes() {
    _notes.clear();
    _saveNotes();
    notifyListeners();
  }

  /// Clean up expired notes
  void cleanupExpiredNotes() {
    if (!_autoDeleteEnabled) return;

    final before = _notes.length;
    _notes.removeWhere((note) => note.isExpired(_autoDeleteDuration));

    if (_notes.length != before) {
      _saveNotes();
      notifyListeners();
    }
  }

  /// Set auto-delete duration
  void setAutoDeleteDuration(Duration duration) {
    _autoDeleteDuration = duration;
    _saveSettings();
    notifyListeners();
  }

  /// Enable or disable auto-delete
  void setAutoDeleteEnabled(bool enabled) {
    _autoDeleteEnabled = enabled;
    _saveSettings();
    notifyListeners();
  }

  /// Start the cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      cleanupExpiredNotes();
    });
  }

  /// Load notes from storage
  Future<void> _loadNotes() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      final notesJson = prefs.getString(_notesKey);
      if (notesJson == null) return;

      // PERFORMANCE: Offload JSON parsing to isolate for larger lists
      final notesList = await compute(_parseJsonList, notesJson);
      _notes.clear();
      _notes.addAll(
        notesList.map(
          (json) => QuickNote.fromJson(json as Map<String, dynamic>),
        ),
      );

      // Clean up expired notes on load
      cleanupExpiredNotes();
    } catch (e) {
      debugPrint('Failed to load quick notes: $e');
    }
  }

  static List<dynamic> _parseJsonList(String json) => jsonDecode(json) as List;

  /// Save notes to storage
  void _saveNotes() {
    // PERFORMANCE: Debounce saves
    _saveNotesDebounce?.cancel();
    _saveNotesDebounce = Timer(_debounceDelay, () async {
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        _prefs = prefs;
        final notesJson = jsonEncode(_notes.map((n) => n.toJson()).toList());
        await prefs.setString(_notesKey, notesJson);
      } catch (e) {
        debugPrint('Failed to save quick notes: $e');
      }
    });
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson == null) return;

      final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
      _autoDeleteDuration = Duration(
        minutes: settings['autoDeleteMinutes'] as int? ?? 1440,
      );
      _autoDeleteEnabled = settings['autoDeleteEnabled'] as bool? ?? true;
    } catch (e) {
      debugPrint('Failed to load quick notes settings: $e');
    }
  }

  /// Save settings to storage
  void _saveSettings() {
    // PERFORMANCE: Debounce saves
    _saveSettingsDebounce?.cancel();
    _saveSettingsDebounce = Timer(_debounceDelay, () async {
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        _prefs = prefs;
        final settingsJson = jsonEncode({
          'autoDeleteMinutes': _autoDeleteDuration.inMinutes,
          'autoDeleteEnabled': _autoDeleteEnabled,
        });
        await prefs.setString(_settingsKey, settingsJson);
      } catch (e) {
        debugPrint('Failed to save quick notes settings: $e');
      }
    });
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _saveNotesDebounce?.cancel();
    _saveSettingsDebounce?.cancel();
    super.dispose();
  }
}

/// Preset durations for auto-delete
class QuickNoteAutoDeletePresets {
  static const fifteenMinutes = Duration(minutes: 15);
  static const thirtyMinutes = Duration(minutes: 30);
  static const oneHour = Duration(hours: 1);
  static const fourHours = Duration(hours: 4);
  static const twelveHours = Duration(hours: 12);
  static const oneDay = Duration(hours: 24);
  static const threeDays = Duration(days: 3);
  static const oneWeek = Duration(days: 7);

  static const presets = <Duration>[
    fifteenMinutes,
    thirtyMinutes,
    oneHour,
    fourHours,
    twelveHours,
    oneDay,
    threeDays,
    oneWeek,
  ];

  static String formatDuration(Duration duration) {
    if (duration.inDays >= 7) {
      return '${duration.inDays ~/ 7} week${duration.inDays >= 14 ? 's' : ''}';
    } else if (duration.inDays >= 1) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }
}
