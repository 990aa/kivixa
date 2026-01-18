import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/models/calendar_event.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';
import 'package:kivixa/services/productivity/productivity_timer_service.dart';
import 'package:logging/logging.dart';
import 'package:lua_dardo/lua.dart';
import 'package:path/path.dart' as p;

/// API exposed to Lua plugins
///
/// Note: When Lua calls methods with `:` syntax (App:method(args)),
/// the first argument at index 1 is `self` (the App table),
/// and actual arguments start at index 2.
///
/// SECURITY: All file operations are sandboxed within the Kivixa documents
/// folder. Paths are normalized and validated to prevent directory traversal
/// attacks or access to files outside the app's data folder.
class PluginApi {
  static final _log = Logger('PluginApi');
  static final _random = Random.secure();

  /// Generate a simple UUID-like identifier
  static String _generateId() {
    const chars = 'abcdef0123456789';
    String segment(int length) => List.generate(
      length,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    return '${segment(8)}-${segment(4)}-${segment(4)}-${segment(4)}-${segment(12)}';
  }

  /// Helper to check if a value is a boolean (lua_dardo doesn't have isBool)
  static bool _isBoolean(LuaState state, int index) {
    // lua_dardo uses type() which returns LuaType enum
    // We need to check for boolean type manually
    try {
      // Try calling toBoolean and see if it makes sense
      // This is a workaround since lua_dardo lacks isBool
      final type = state.type(index);
      return type == LuaType.luaBoolean;
    } catch (_) {
      return false;
    }
  }

  /// Sanitize and validate a path to ensure it stays within the Kivixa sandbox.
  /// Returns null if the path is invalid or attempts to escape the sandbox.
  static String? _sandboxPath(String? inputPath) {
    if (inputPath == null || inputPath.isEmpty) {
      return null;
    }

    // Remove leading slashes and backslashes to prevent absolute path interpretation
    var cleanPath = inputPath;
    while (cleanPath.startsWith('/') || cleanPath.startsWith('\\')) {
      cleanPath = cleanPath.substring(1);
    }

    // Reject paths with parent directory traversal
    if (cleanPath.contains('..')) {
      _log.warning('Path traversal attempt blocked: $inputPath');
      return null;
    }

    // Build the full path within the documents directory
    final fullPath = p.normalize(
      p.join(FileManager.documentsDirectory, cleanPath),
    );

    // Verify the path is still within the documents directory
    final docsDir = p.normalize(FileManager.documentsDirectory);
    if (!fullPath.startsWith(docsDir)) {
      _log.warning('Path escape attempt blocked: $inputPath -> $fullPath');
      return null;
    }

    return fullPath;
  }

  /// Register the App API with a Lua state
  static void register(LuaState state) {
    // Create the App table
    state.newTable();

    // Register note methods
    _registerMethod(state, 'readNote', _readNote);
    _registerMethod(state, 'writeNote', _writeNote);
    _registerMethod(state, 'deleteNote', _deleteNote);
    _registerMethod(state, 'findNotes', _findNotes);
    _registerMethod(state, 'getRecentNotes', _getRecentNotes);
    _registerMethod(state, 'getNotesOlderThan', _getNotesOlderThan);
    _registerMethod(state, 'getAllNotes', _getAllNotes);
    _registerMethod(state, 'createFolder', _createFolder);
    _registerMethod(state, 'moveNote', _moveNote);
    _registerMethod(state, 'getStats', _getStats);
    _registerMethod(state, 'log', _luaLog);
    _registerMethod(state, 'notify', _notify);

    // Register calendar methods
    _registerMethod(state, 'getCalendarEvents', _getCalendarEvents);
    _registerMethod(state, 'getEventsForDate', _getEventsForDate);
    _registerMethod(state, 'getEventsForMonth', _getEventsForMonth);
    _registerMethod(state, 'addCalendarEvent', _addCalendarEvent);
    _registerMethod(state, 'updateCalendarEvent', _updateCalendarEvent);
    _registerMethod(state, 'deleteCalendarEvent', _deleteCalendarEvent);
    _registerMethod(state, 'completeTask', _completeTask);

    // Register productivity timer methods
    _registerMethod(state, 'getTimerStats', _getTimerStats);
    _registerMethod(state, 'getTimerState', _getTimerState);
    _registerMethod(state, 'startTimer', _startTimer);
    _registerMethod(state, 'pauseTimer', _pauseTimer);
    _registerMethod(state, 'resumeTimer', _resumeTimer);
    _registerMethod(state, 'stopTimer', _stopTimer);
    _registerMethod(state, 'getSessionHistory', _getSessionHistory);

    // Set as global 'App'
    state.setGlobal('App');
  }

  static void _registerMethod(
    LuaState state,
    String name,
    int Function(LuaState) method,
  ) {
    state.pushString(name);
    state.pushDartFunction(method);
    state.setTable(-3);
  }

  /// Read the content of a note
  /// Lua: App:readNote(path) -> string or nil
  /// Note: Index 1 is self, index 2 is path
  static int _readNote(LuaState state) {
    // When called with :, index 1 is self (App table), index 2 is the path
    final path = state.toStr(2);
    final basePath = _sandboxPath(path);

    if (basePath == null) {
      state.pushNil();
      return 1;
    }

    try {
      String? content;

      // Try markdown
      final mdFile = File('$basePath.md');
      if (mdFile.existsSync()) {
        content = mdFile.readAsStringSync();
      }

      // Try text file
      if (content == null) {
        final txtFile = File('$basePath${TextFileEditor.internalExtension}');
        if (txtFile.existsSync()) {
          content = txtFile.readAsStringSync();
        }
      }

      // Try without extension (if already has extension)
      if (content == null) {
        final directFile = File(basePath);
        if (directFile.existsSync() && FileSystemEntity.isFileSync(basePath)) {
          content = directFile.readAsStringSync();
        }
      }

      if (content != null) {
        state.pushString(content);
      } else {
        state.pushNil();
      }
    } catch (e) {
      _log.warning('readNote error: $e');
      state.pushNil();
    }

    return 1;
  }

  /// Write content to a note (creates or updates)
  /// Lua: App:writeNote(path, content) -> boolean
  /// Note: Index 1 is self, index 2 is path, index 3 is content
  static int _writeNote(LuaState state) {
    final path = state.toStr(2);
    final content = state.toStr(3);
    final basePath = _sandboxPath(path);

    if (basePath == null || content == null) {
      state.pushBoolean(false);
      return 1;
    }

    try {
      // Determine file type based on existing file or default to markdown
      String filePath;

      if (File('$basePath.md').existsSync()) {
        filePath = '$basePath.md';
      } else if (File(
        '$basePath${TextFileEditor.internalExtension}',
      ).existsSync()) {
        filePath = '$basePath${TextFileEditor.internalExtension}';
      } else {
        // Default to markdown for new files
        filePath = '$basePath.md';
      }

      // Create parent directory if needed
      final file = File(filePath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);

      state.pushBoolean(true);
    } catch (e) {
      _log.warning('writeNote error: $e');
      state.pushBoolean(false);
    }

    return 1;
  }

  /// Delete a note
  /// Lua: App:deleteNote(path) -> boolean
  /// Note: Index 1 is self, index 2 is path
  static int _deleteNote(LuaState state) {
    final path = state.toStr(2);
    final basePath = _sandboxPath(path);

    if (basePath == null) {
      state.pushBoolean(false);
      return 1;
    }

    try {
      bool deleted = false;

      // Try all extensions
      for (final ext in [
        '.md',
        TextFileEditor.internalExtension,
        Editor.extension,
      ]) {
        final file = File('$basePath$ext');
        if (file.existsSync()) {
          file.deleteSync();
          deleted = true;
        }
      }

      state.pushBoolean(deleted);
    } catch (e) {
      _log.warning('deleteNote error: $e');
      state.pushBoolean(false);
    }

    return 1;
  }

  /// Find notes matching a pattern
  /// Lua: App:findNotes(pattern) -> table of paths
  /// Note: Index 1 is self, index 2 is pattern
  static int _findNotes(LuaState state) {
    final pattern = state.toStr(2) ?? '';

    try {
      final matches = <String>[];
      final dir = Directory(FileManager.documentsDirectory);

      if (dir.existsSync()) {
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File) {
            final relativePath = p.relative(
              entity.path,
              from: FileManager.documentsDirectory,
            );

            // Skip hidden files and lifegit
            if (relativePath.startsWith('.')) continue;

            // Check if it's a note file
            if (!relativePath.endsWith('.md') &&
                !relativePath.endsWith(TextFileEditor.internalExtension) &&
                !relativePath.endsWith(Editor.extension)) {
              continue;
            }

            // Check pattern match
            if (pattern.isEmpty ||
                relativePath.toLowerCase().contains(pattern.toLowerCase())) {
              // Remove extension for cleaner path
              var cleanPath = relativePath;
              for (final ext in [
                '.md',
                TextFileEditor.internalExtension,
                Editor.extension,
              ]) {
                if (cleanPath.endsWith(ext)) {
                  cleanPath = cleanPath.substring(
                    0,
                    cleanPath.length - ext.length,
                  );
                  break;
                }
              }
              if (!matches.contains(cleanPath)) {
                matches.add('/$cleanPath');
              }
            }
          }
        }
      }

      // Push as Lua table
      state.newTable();
      for (var i = 0; i < matches.length; i++) {
        state.pushInteger(i + 1);
        state.pushString(matches[i]);
        state.setTable(-3);
      }
    } catch (e) {
      _log.warning('findNotes error: $e');
      state.newTable(); // Empty table on error
    }

    return 1;
  }

  /// Get recently modified notes
  /// Lua: App:getRecentNotes(count) -> table of paths
  /// Note: Index 1 is self, index 2 is count
  static int _getRecentNotes(LuaState state) {
    var count = 10;
    if (state.isNumber(2)) {
      count = state.toInteger(2);
    }

    try {
      final notes = <MapEntry<String, DateTime>>[];
      final dir = Directory(FileManager.documentsDirectory);

      if (dir.existsSync()) {
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File) {
            final relativePath = p.relative(
              entity.path,
              from: FileManager.documentsDirectory,
            );

            if (relativePath.startsWith('.')) continue;

            if (relativePath.endsWith('.md') ||
                relativePath.endsWith(TextFileEditor.internalExtension) ||
                relativePath.endsWith(Editor.extension)) {
              final stat = entity.statSync();
              var cleanPath = relativePath;
              for (final ext in [
                '.md',
                TextFileEditor.internalExtension,
                Editor.extension,
              ]) {
                if (cleanPath.endsWith(ext)) {
                  cleanPath = cleanPath.substring(
                    0,
                    cleanPath.length - ext.length,
                  );
                  break;
                }
              }
              notes.add(MapEntry('/$cleanPath', stat.modified));
            }
          }
        }
      }

      // Sort by modified date (most recent first)
      notes.sort((a, b) => b.value.compareTo(a.value));

      // Take only the requested count
      final recentNotes = notes.take(count).map((e) => e.key).toList();

      // Push as Lua table
      state.newTable();
      for (var i = 0; i < recentNotes.length; i++) {
        state.pushInteger(i + 1);
        state.pushString(recentNotes[i]);
        state.setTable(-3);
      }
    } catch (e) {
      _log.warning('getRecentNotes error: $e');
      state.newTable();
    }

    return 1;
  }

  /// Get notes older than X days
  /// Lua: App:getNotesOlderThan(days) -> table of paths
  /// Note: Index 1 is self, index 2 is days
  static int _getNotesOlderThan(LuaState state) {
    var days = 7;
    if (state.isNumber(2)) {
      days = state.toInteger(2);
    }
    final cutoff = DateTime.now().subtract(Duration(days: days));

    try {
      final notes = <String>[];
      final dir = Directory(FileManager.documentsDirectory);

      if (dir.existsSync()) {
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File) {
            final relativePath = p.relative(
              entity.path,
              from: FileManager.documentsDirectory,
            );

            if (relativePath.startsWith('.')) continue;

            if (relativePath.endsWith('.md') ||
                relativePath.endsWith(TextFileEditor.internalExtension) ||
                relativePath.endsWith(Editor.extension)) {
              final stat = entity.statSync();
              if (stat.modified.isBefore(cutoff)) {
                var cleanPath = relativePath;
                for (final ext in [
                  '.md',
                  TextFileEditor.internalExtension,
                  Editor.extension,
                ]) {
                  if (cleanPath.endsWith(ext)) {
                    cleanPath = cleanPath.substring(
                      0,
                      cleanPath.length - ext.length,
                    );
                    break;
                  }
                }
                notes.add('/$cleanPath');
              }
            }
          }
        }
      }

      // Push as Lua table
      state.newTable();
      for (var i = 0; i < notes.length; i++) {
        state.pushInteger(i + 1);
        state.pushString(notes[i]);
        state.setTable(-3);
      }
    } catch (e) {
      _log.warning('getNotesOlderThan error: $e');
      state.newTable();
    }

    return 1;
  }

  /// Get all notes
  /// Lua: App:getAllNotes() -> table of paths
  static int _getAllNotes(LuaState state) {
    state.pushInteger(0); // Empty pattern for findNotes
    return _findNotes(state);
  }

  /// Create a folder
  /// Lua: App:createFolder(path) -> boolean
  /// Note: Index 1 is self, index 2 is path
  static int _createFolder(LuaState state) {
    final path = state.toStr(2);
    final fullPath = _sandboxPath(path);

    if (fullPath == null) {
      state.pushBoolean(false);
      return 1;
    }

    try {
      Directory(fullPath).createSync(recursive: true);
      state.pushBoolean(true);
    } catch (e) {
      _log.warning('createFolder error: $e');
      state.pushBoolean(false);
    }

    return 1;
  }

  /// Move a note to a new location
  /// Lua: App:moveNote(fromPath, toPath) -> boolean
  /// Note: Index 1 is self, index 2 is fromPath, index 3 is toPath
  static int _moveNote(LuaState state) {
    final fromPath = state.toStr(2);
    final toPath = state.toStr(3);
    final fromBase = _sandboxPath(fromPath);
    final toBase = _sandboxPath(toPath);

    if (fromBase == null || toBase == null) {
      state.pushBoolean(false);
      return 1;
    }

    try {
      bool moved = false;

      // Try to move files with various extensions
      for (final ext in [
        '.md',
        TextFileEditor.internalExtension,
        Editor.extension,
      ]) {
        final fromFile = File('$fromBase$ext');
        if (fromFile.existsSync()) {
          final toFile = File('$toBase$ext');
          toFile.parent.createSync(recursive: true);
          fromFile.renameSync(toFile.path);
          moved = true;
        }
      }

      state.pushBoolean(moved);
    } catch (e) {
      _log.warning('moveNote error: $e');
      state.pushBoolean(false);
    }

    return 1;
  }

  /// Get statistics about the notes database
  /// Lua: App:getStats() -> table {totalNotes, totalFolders}
  static int _getStats(LuaState state) {
    try {
      int noteCount = 0;
      final folders = <String>{};
      final dir = Directory(FileManager.documentsDirectory);

      if (dir.existsSync()) {
        for (final entity in dir.listSync(recursive: true)) {
          final relativePath = p.relative(
            entity.path,
            from: FileManager.documentsDirectory,
          );

          if (relativePath.startsWith('.')) continue;

          if (entity is File) {
            if (relativePath.endsWith('.md') ||
                relativePath.endsWith(TextFileEditor.internalExtension) ||
                relativePath.endsWith(Editor.extension)) {
              noteCount++;
            }
          } else if (entity is Directory) {
            folders.add(relativePath);
          }
        }
      }

      state.newTable();

      state.pushString('totalNotes');
      state.pushInteger(noteCount);
      state.setTable(-3);

      state.pushString('totalFolders');
      state.pushInteger(folders.length);
      state.setTable(-3);
    } catch (e) {
      _log.warning('getStats error: $e');
      state.newTable();
    }

    return 1;
  }

  /// Log a message (for debugging)
  /// Lua: App:log(message)
  /// Note: Index 1 is self, index 2 is message
  static int _luaLog(LuaState state) {
    final message = state.toStr(2) ?? '';
    _log.info('[Plugin] $message');
    return 0;
  }

  /// Show a notification (placeholder - actual implementation depends on UI)
  /// Lua: App:notify(message)
  /// Note: Index 1 is self, index 2 is message
  static int _notify(LuaState state) {
    final message = state.toStr(2) ?? '';
    _log.info('[Plugin Notification] $message');
    // In a real implementation, this would show a snackbar or notification
    return 0;
  }

  // ==========================================================================
  // Calendar API
  // ==========================================================================

  /// Get all calendar events
  /// Lua: App:getCalendarEvents() -> table of events
  static int _getCalendarEvents(LuaState state) {
    try {
      // Note: This is async but Lua doesn't support async directly,
      // so we use a synchronous approach by storing results
      final events = _loadEventsSync();
      _pushEventsTable(state, events);
    } catch (e) {
      _log.warning('getCalendarEvents error: $e');
      state.newTable();
    }
    return 1;
  }

  /// Get events for a specific date
  /// Lua: App:getEventsForDate(year, month, day) -> table of events
  /// Note: Index 1 is self, index 2 is year, index 3 is month, index 4 is day
  static int _getEventsForDate(LuaState state) {
    try {
      final year = state.isNumber(2) ? state.toInteger(2) : DateTime.now().year;
      final month = state.isNumber(3)
          ? state.toInteger(3)
          : DateTime.now().month;
      final day = state.isNumber(4) ? state.toInteger(4) : DateTime.now().day;

      final date = DateTime(year, month, day);
      final events = _loadEventsSync();
      final filtered = events.where((e) => e.occursOn(date)).toList();
      _pushEventsTable(state, filtered);
    } catch (e) {
      _log.warning('getEventsForDate error: $e');
      state.newTable();
    }
    return 1;
  }

  /// Get events for a specific month
  /// Lua: App:getEventsForMonth(year, month) -> table of events
  /// Note: Index 1 is self, index 2 is year, index 3 is month
  static int _getEventsForMonth(LuaState state) {
    try {
      final year = state.isNumber(2) ? state.toInteger(2) : DateTime.now().year;
      final month = state.isNumber(3)
          ? state.toInteger(3)
          : DateTime.now().month;

      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0);

      final events = _loadEventsSync();
      final filtered = <CalendarEvent>[];

      for (
        var day = firstDay;
        day.isBefore(lastDay.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))
      ) {
        for (final event in events) {
          if (event.occursOn(day) && !filtered.any((e) => e.id == event.id)) {
            filtered.add(event);
          }
        }
      }

      _pushEventsTable(state, filtered);
    } catch (e) {
      _log.warning('getEventsForMonth error: $e');
      state.newTable();
    }
    return 1;
  }

  /// Add a calendar event
  /// Lua: App:addCalendarEvent(title, year, month, day, options) -> string (event ID) or nil
  /// options is a table with optional fields: description, startHour, startMinute,
  /// endHour, endMinute, isAllDay, type ("event" or "task"), meetingLink
  /// Note: Index 1 is self, 2 is title, 3 is year, 4 is month, 5 is day, 6 is options
  static int _addCalendarEvent(LuaState state) {
    try {
      final title = state.toStr(2);
      if (title == null || title.isEmpty) {
        _log.warning('addCalendarEvent: title is required');
        state.pushNil();
        return 1;
      }

      final year = state.isNumber(3) ? state.toInteger(3) : DateTime.now().year;
      final month = state.isNumber(4)
          ? state.toInteger(4)
          : DateTime.now().month;
      final day = state.isNumber(5) ? state.toInteger(5) : DateTime.now().day;

      // Parse options table if provided
      String? description;
      TimeOfDay? startTime;
      TimeOfDay? endTime;
      bool isAllDay = false;
      EventType type = EventType.event;
      String? meetingLink;

      if (state.isTable(6)) {
        state.getField(6, 'description');
        if (state.isString(-1)) description = state.toStr(-1);
        state.pop(1);

        state.getField(6, 'startHour');
        final startHour = state.isNumber(-1) ? state.toInteger(-1) : null;
        state.pop(1);

        state.getField(6, 'startMinute');
        final startMinute = state.isNumber(-1) ? state.toInteger(-1) : 0;
        state.pop(1);

        if (startHour != null) {
          startTime = TimeOfDay(hour: startHour, minute: startMinute);
        }

        state.getField(6, 'endHour');
        final endHour = state.isNumber(-1) ? state.toInteger(-1) : null;
        state.pop(1);

        state.getField(6, 'endMinute');
        final endMinute = state.isNumber(-1) ? state.toInteger(-1) : 0;
        state.pop(1);

        if (endHour != null) {
          endTime = TimeOfDay(hour: endHour, minute: endMinute);
        }

        state.getField(6, 'isAllDay');
        if (_isBoolean(state, -1)) isAllDay = state.toBoolean(-1);
        state.pop(1);

        state.getField(6, 'type');
        if (state.isString(-1)) {
          final typeStr = state.toStr(-1);
          if (typeStr == 'task') type = EventType.task;
        }
        state.pop(1);

        state.getField(6, 'meetingLink');
        if (state.isString(-1)) meetingLink = state.toStr(-1);
        state.pop(1);
      }

      final event = CalendarEvent(
        id: _generateId(),
        title: title,
        description: description,
        date: DateTime(year, month, day),
        startTime: startTime,
        endTime: endTime,
        isAllDay: isAllDay,
        type: type,
        meetingLink: meetingLink,
      );

      // Save synchronously
      _addEventSync(event);

      state.pushString(event.id);
    } catch (e) {
      _log.warning('addCalendarEvent error: $e');
      state.pushNil();
    }
    return 1;
  }

  /// Update a calendar event
  /// Lua: App:updateCalendarEvent(eventId, updates) -> boolean
  /// updates is a table with optional fields: title, description, year, month, day,
  /// startHour, startMinute, endHour, endMinute, isAllDay, type, meetingLink
  /// Note: Index 1 is self, index 2 is eventId, index 3 is updates table
  static int _updateCalendarEvent(LuaState state) {
    try {
      final eventId = state.toStr(2);
      if (eventId == null || eventId.isEmpty) {
        state.pushBoolean(false);
        return 1;
      }

      final events = _loadEventsSync();
      final index = events.indexWhere((e) => e.id == eventId);
      if (index == -1) {
        state.pushBoolean(false);
        return 1;
      }

      var event = events[index];

      if (state.isTable(3)) {
        state.getField(3, 'title');
        final title = state.isString(-1) ? state.toStr(-1) : null;
        state.pop(1);

        state.getField(3, 'description');
        final description = state.isString(-1) ? state.toStr(-1) : null;
        state.pop(1);

        state.getField(3, 'year');
        final year = state.isNumber(-1) ? state.toInteger(-1) : null;
        state.pop(1);

        state.getField(3, 'month');
        final month = state.isNumber(-1) ? state.toInteger(-1) : null;
        state.pop(1);

        state.getField(3, 'day');
        final day = state.isNumber(-1) ? state.toInteger(-1) : null;
        state.pop(1);

        DateTime? newDate;
        if (year != null || month != null || day != null) {
          newDate = DateTime(
            year ?? event.date.year,
            month ?? event.date.month,
            day ?? event.date.day,
          );
        }

        state.getField(3, 'isAllDay');
        final isAllDay = _isBoolean(state, -1) ? state.toBoolean(-1) : null;
        state.pop(1);

        state.getField(3, 'type');
        EventType? type;
        if (state.isString(-1)) {
          final typeStr = state.toStr(-1);
          type = typeStr == 'task' ? EventType.task : EventType.event;
        }
        state.pop(1);

        state.getField(3, 'meetingLink');
        final meetingLink = state.isString(-1) ? state.toStr(-1) : null;
        state.pop(1);

        state.getField(3, 'isCompleted');
        final isCompleted = _isBoolean(state, -1) ? state.toBoolean(-1) : null;
        state.pop(1);

        event = event.copyWith(
          title: title,
          description: description,
          date: newDate,
          isAllDay: isAllDay,
          type: type,
          meetingLink: meetingLink,
          isCompleted: isCompleted,
        );

        events[index] = event;
        _saveEventsSync(events);
      }

      state.pushBoolean(true);
    } catch (e) {
      _log.warning('updateCalendarEvent error: $e');
      state.pushBoolean(false);
    }
    return 1;
  }

  /// Delete a calendar event
  /// Lua: App:deleteCalendarEvent(eventId) -> boolean
  /// Note: Index 1 is self, index 2 is eventId
  static int _deleteCalendarEvent(LuaState state) {
    try {
      final eventId = state.toStr(2);
      if (eventId == null || eventId.isEmpty) {
        state.pushBoolean(false);
        return 1;
      }

      final events = _loadEventsSync();
      final initialLength = events.length;
      events.removeWhere((e) => e.id == eventId);

      if (events.length < initialLength) {
        _saveEventsSync(events);
        state.pushBoolean(true);
      } else {
        state.pushBoolean(false);
      }
    } catch (e) {
      _log.warning('deleteCalendarEvent error: $e');
      state.pushBoolean(false);
    }
    return 1;
  }

  /// Mark a task as completed
  /// Lua: App:completeTask(eventId, completed) -> boolean
  /// Note: Index 1 is self, index 2 is eventId, index 3 is completed (optional, defaults to true)
  static int _completeTask(LuaState state) {
    try {
      final eventId = state.toStr(2);
      final completed = _isBoolean(state, 3) ? state.toBoolean(3) : true;

      if (eventId == null || eventId.isEmpty) {
        state.pushBoolean(false);
        return 1;
      }

      final events = _loadEventsSync();
      final index = events.indexWhere((e) => e.id == eventId);
      if (index == -1) {
        state.pushBoolean(false);
        return 1;
      }

      events[index] = events[index].copyWith(isCompleted: completed);
      _saveEventsSync(events);
      state.pushBoolean(true);
    } catch (e) {
      _log.warning('completeTask error: $e');
      state.pushBoolean(false);
    }
    return 1;
  }

  // Calendar helper methods
  static List<CalendarEvent> _loadEventsSync() {
    // Using a simple file-based approach for sync access
    // SharedPreferences is async, so we need a workaround
    final file = File(
      p.join(FileManager.documentsDirectory, '.calendar_events.json'),
    );
    if (!file.existsSync()) {
      return [];
    }
    try {
      final content = file.readAsStringSync();
      final List<dynamic> decoded = jsonDecode(content);
      return decoded
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log.warning('Failed to load events: $e');
      return [];
    }
  }

  static void _saveEventsSync(List<CalendarEvent> events) {
    final file = File(
      p.join(FileManager.documentsDirectory, '.calendar_events.json'),
    );
    final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
    file.writeAsStringSync(encoded);
  }

  static void _addEventSync(CalendarEvent event) {
    final events = _loadEventsSync();
    events.add(event);
    _saveEventsSync(events);
  }

  static void _pushEventsTable(LuaState state, List<CalendarEvent> events) {
    state.newTable();
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      state.pushInteger(i + 1);

      // Create event table
      state.newTable();

      state.pushString('id');
      state.pushString(event.id);
      state.setTable(-3);

      state.pushString('title');
      state.pushString(event.title);
      state.setTable(-3);

      if (event.description != null) {
        state.pushString('description');
        state.pushString(event.description!);
        state.setTable(-3);
      }

      state.pushString('year');
      state.pushInteger(event.date.year);
      state.setTable(-3);

      state.pushString('month');
      state.pushInteger(event.date.month);
      state.setTable(-3);

      state.pushString('day');
      state.pushInteger(event.date.day);
      state.setTable(-3);

      if (event.startTime != null) {
        state.pushString('startHour');
        state.pushInteger(event.startTime!.hour);
        state.setTable(-3);

        state.pushString('startMinute');
        state.pushInteger(event.startTime!.minute);
        state.setTable(-3);
      }

      if (event.endTime != null) {
        state.pushString('endHour');
        state.pushInteger(event.endTime!.hour);
        state.setTable(-3);

        state.pushString('endMinute');
        state.pushInteger(event.endTime!.minute);
        state.setTable(-3);
      }

      state.pushString('isAllDay');
      state.pushBoolean(event.isAllDay);
      state.setTable(-3);

      state.pushString('type');
      state.pushString(event.type.name);
      state.setTable(-3);

      if (event.meetingLink != null) {
        state.pushString('meetingLink');
        state.pushString(event.meetingLink!);
        state.setTable(-3);
      }

      state.pushString('isCompleted');
      state.pushBoolean(event.isCompleted);
      state.setTable(-3);

      state.setTable(-3);
    }
  }

  // ==========================================================================
  // Productivity Timer API
  // ==========================================================================

  /// Get timer statistics
  /// Lua: App:getTimerStats() -> table with stats
  static int _getTimerStats(LuaState state) {
    try {
      final service = ProductivityTimerService.instance;
      final stats = service.stats;

      state.newTable();

      state.pushString('totalFocusMinutes');
      state.pushInteger(stats.totalFocusMinutes);
      state.setTable(-3);

      state.pushString('totalSessions');
      state.pushInteger(stats.totalSessions);
      state.setTable(-3);

      state.pushString('completedSessions');
      state.pushInteger(stats.completedSessions);
      state.setTable(-3);

      state.pushString('currentStreak');
      state.pushInteger(stats.currentStreak);
      state.setTable(-3);

      state.pushString('longestStreak');
      state.pushInteger(stats.longestStreak);
      state.setTable(-3);

      state.pushString('todayFocusMinutes');
      state.pushInteger(stats.todayFocusMinutes);
      state.setTable(-3);

      state.pushString('todaySessions');
      state.pushInteger(stats.todaySessions);
      state.setTable(-3);

      state.pushString('completionRate');
      state.pushNumber(stats.completionRate);
      state.setTable(-3);

      state.pushString('averageSessionMinutes');
      state.pushNumber(stats.averageSessionMinutes);
      state.setTable(-3);
    } catch (e) {
      _log.warning('getTimerStats error: $e');
      state.newTable();
    }
    return 1;
  }

  /// Get current timer state
  /// Lua: App:getTimerState() -> table with state info
  static int _getTimerState(LuaState luaState) {
    try {
      final service = ProductivityTimerService.instance;

      luaState.newTable();

      luaState.pushString('state');
      luaState.pushString(service.state.name);
      luaState.setTable(-3);

      luaState.pushString('isRunning');
      luaState.pushBoolean(service.state == TimerState.running);
      luaState.setTable(-3);

      luaState.pushString('isPaused');
      luaState.pushBoolean(service.state == TimerState.paused);
      luaState.setTable(-3);

      luaState.pushString('remainingSeconds');
      luaState.pushInteger(service.remainingTime.inSeconds);
      luaState.setTable(-3);

      luaState.pushString('remainingMinutes');
      luaState.pushInteger(service.remainingTime.inMinutes);
      luaState.setTable(-3);

      luaState.pushString('currentCycle');
      luaState.pushInteger(service.currentCycle);
      luaState.setTable(-3);

      luaState.pushString('totalCycles');
      luaState.pushInteger(service.totalCycles);
      luaState.setTable(-3);

      luaState.pushString('sessionType');
      luaState.pushString(service.sessionType.name);
      luaState.setTable(-3);
    } catch (e) {
      _log.warning('getTimerState error: $e');
      luaState.newTable();
    }
    return 1;
  }

  /// Start a new timer session
  /// Lua: App:startTimer(minutes, sessionType) -> boolean
  /// sessionType: "focus", "deepWork", "sprint", "meeting", "study", "workout", "custom"
  /// Note: Index 1 is self, index 2 is minutes (optional), index 3 is sessionType (optional)
  static int _startTimer(LuaState luaState) {
    try {
      final service = ProductivityTimerService.instance;

      // If timer is already running, return false
      if (service.state == TimerState.running) {
        luaState.pushBoolean(false);
        return 1;
      }

      final minutes = luaState.isNumber(2) ? luaState.toInteger(2) : 25;
      final sessionTypeStr = luaState.isString(3) ? luaState.toStr(3) : 'focus';

      final sessionType = SessionType.values.firstWhere(
        (t) => t.name.toLowerCase() == sessionTypeStr?.toLowerCase(),
        orElse: () => SessionType.focus,
      );

      service.startSession(
        duration: Duration(minutes: minutes),
        type: sessionType,
      );

      luaState.pushBoolean(true);
    } catch (e) {
      _log.warning('startTimer error: $e');
      luaState.pushBoolean(false);
    }
    return 1;
  }

  /// Pause the current timer
  /// Lua: App:pauseTimer() -> boolean
  static int _pauseTimer(LuaState luaState) {
    try {
      final service = ProductivityTimerService.instance;

      if (service.state != TimerState.running) {
        luaState.pushBoolean(false);
        return 1;
      }

      service.pause();
      luaState.pushBoolean(true);
    } catch (e) {
      _log.warning('pauseTimer error: $e');
      luaState.pushBoolean(false);
    }
    return 1;
  }

  /// Resume a paused timer
  /// Lua: App:resumeTimer() -> boolean
  static int _resumeTimer(LuaState luaState) {
    try {
      final service = ProductivityTimerService.instance;

      if (service.state != TimerState.paused) {
        luaState.pushBoolean(false);
        return 1;
      }

      service.resume();
      luaState.pushBoolean(true);
    } catch (e) {
      _log.warning('resumeTimer error: $e');
      luaState.pushBoolean(false);
    }
    return 1;
  }

  /// Stop/reset the current timer
  /// Lua: App:stopTimer() -> boolean
  static int _stopTimer(LuaState luaState) {
    try {
      final service = ProductivityTimerService.instance;
      service.stop();
      luaState.pushBoolean(true);
    } catch (e) {
      _log.warning('stopTimer error: $e');
      luaState.pushBoolean(false);
    }
    return 1;
  }

  /// Get session history for a date range
  /// Lua: App:getSessionHistory(days) -> table with daily minutes
  /// Note: Index 1 is self, index 2 is days (default 7)
  static int _getSessionHistory(LuaState state) {
    try {
      final service = ProductivityTimerService.instance;
      final days = state.isNumber(2) ? state.toInteger(2) : 7;
      final stats = service.stats;

      state.newTable();

      final today = DateTime.now();
      for (var i = 0; i < days; i++) {
        final date = today.subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final minutes = stats.dailyMinutes[dateKey] ?? 0;

        state.pushString(dateKey);
        state.pushInteger(minutes);
        state.setTable(-3);
      }
    } catch (e) {
      _log.warning('getSessionHistory error: $e');
      state.newTable();
    }
    return 1;
  }
}
