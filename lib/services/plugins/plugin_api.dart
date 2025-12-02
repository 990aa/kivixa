import 'dart:io';

import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';
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
    final fullPath = p.normalize(p.join(FileManager.documentsDirectory, cleanPath));

    // Verify the path is still within the documents directory
    final docsDir = p.normalize(FileManager.documentsDirectory);
    if (!fullPath.startsWith(docsDir)) {
      _log.warning('Path escape attempt blocked: $inputPath -> $fullPath');
      return null;
    }

    return fullPath;
  }

  /// Check if a path would escape the sandbox (for warning purposes)
  static bool _wouldEscapeSandbox(String? inputPath) {
    if (inputPath == null || inputPath.isEmpty) return false;
    return inputPath.contains('..') ||
        (inputPath.startsWith('/') && !inputPath.startsWith('//'));
  }

  /// Register the App API with a Lua state
  static void register(LuaState state) {
    // Create the App table
    state.newTable();

    // Register methods
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
}
