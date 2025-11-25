import 'dart:io';

import 'package:kivixa/data/calendar_storage.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/project_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum representing different types of app data that can be cleared
enum AppDataType {
  notes('Notes & Documents', 'All your handwritten notes and documents'),
  markdown('Markdown Files', 'All markdown text files'),
  projects('Projects', 'All project data and tracking information'),
  calendar('Calendar Events', 'All calendar events and tasks'),
  preferences('Preferences', 'All app settings and preferences'),
  recentFiles('Recent Files', 'Recently accessed files list'),
  all('All Data', 'Clear all app data completely');

  final String displayName;
  final String description;

  const AppDataType(this.displayName, this.description);
}

/// Service class for managing app data clearing operations
class AppDataClearService {
  /// Clears the specified types of app data
  /// Returns a map of data type to whether it was successfully cleared
  static Future<Map<AppDataType, bool>> clearData(
    Set<AppDataType> dataTypes,
  ) async {
    final results = <AppDataType, bool>{};

    for (final dataType in dataTypes) {
      try {
        switch (dataType) {
          case AppDataType.notes:
            await _clearNotes();
            results[dataType] = true;
          case AppDataType.markdown:
            await _clearMarkdown();
            results[dataType] = true;
          case AppDataType.projects:
            await _clearProjects();
            results[dataType] = true;
          case AppDataType.calendar:
            await _clearCalendar();
            results[dataType] = true;
          case AppDataType.preferences:
            await _clearPreferences();
            results[dataType] = true;
          case AppDataType.recentFiles:
            await _clearRecentFiles();
            results[dataType] = true;
          case AppDataType.all:
            await _clearAllData();
            results[dataType] = true;
        }
      } catch (e) {
        results[dataType] = false;
      }
    }

    return results;
  }

  /// Clears all notes (.kvx files)
  static Future<void> _clearNotes() async {
    final files = await FileManager.getAllFiles(includeExtensions: true);
    for (final file in files) {
      if (file.endsWith('.kvx') || file.endsWith('.kvx1')) {
        await FileManager.deleteFile(file, alsoDeleteAssets: true);
      }
    }
  }

  /// Clears all markdown files
  static Future<void> _clearMarkdown() async {
    final files = await FileManager.getAllFiles(includeExtensions: true);
    for (final file in files) {
      if (file.endsWith('.md')) {
        await FileManager.deleteFile(file, alsoDeleteAssets: false);
      }
    }
  }

  /// Clears all projects
  static Future<void> _clearProjects() async {
    await ProjectStorage.saveProjects([]);
  }

  /// Clears all calendar events
  static Future<void> _clearCalendar() async {
    await CalendarStorage.saveEvents([]);
  }

  /// Clears app preferences (but not essential ones)
  static Future<void> _clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Get keys to preserve (like terms acceptance)
    final keysToPreserve = ['termsAccepted', 'termsAcceptedVersion'];
    final allKeys = prefs.getKeys().toList();

    for (final key in allKeys) {
      if (!keysToPreserve.contains(key)) {
        await prefs.remove(key);
      }
    }
  }

  /// Clears recent files list
  static Future<void> _clearRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recentFiles');
  }

  /// Clears all app data
  static Future<void> _clearAllData() async {
    // Clear all files in the documents directory
    final rootDir = FileManager.getRootDirectory();
    if (rootDir.existsSync()) {
      await for (final entity in rootDir.list(recursive: true)) {
        if (entity is File) {
          await entity.delete();
        }
      }
      // Clean up empty directories
      await for (final entity in rootDir.list(recursive: true)) {
        if (entity is Directory) {
          try {
            await entity.delete(recursive: false);
          } catch (_) {
            // Directory not empty, skip
          }
        }
      }
    }

    // Clear SharedPreferences (except terms)
    await _clearPreferences();

    // Clear projects and calendar
    await _clearProjects();
    await _clearCalendar();
  }

  /// Gets the estimated size of each data type
  static Future<Map<AppDataType, int>> getDataSizes() async {
    final sizes = <AppDataType, int>{};

    try {
      final files = await FileManager.getAllFiles(
        includeExtensions: true,
        includeAssets: true,
      );

      int notesSize = 0;
      int markdownSize = 0;

      for (final filePath in files) {
        try {
          final file = FileManager.getFile(filePath);
          if (!file.existsSync()) continue;

          final size = await file.length();
          if (filePath.endsWith('.kvx') || filePath.endsWith('.kvx1')) {
            notesSize += size;
          } else if (filePath.endsWith('.md')) {
            markdownSize += size;
          }
        } catch (_) {
          // Skip files we can't access
        }
      }

      sizes[AppDataType.notes] = notesSize;
      sizes[AppDataType.markdown] = markdownSize;
    } catch (_) {
      sizes[AppDataType.notes] = 0;
      sizes[AppDataType.markdown] = 0;
    }

    // Projects and calendar are stored in SharedPreferences
    // so their sizes are relatively small
    final prefs = await SharedPreferences.getInstance();

    final projectsJson = prefs.getString('projects');
    sizes[AppDataType.projects] = projectsJson?.length ?? 0;

    final calendarJson = prefs.getString('calendar_events');
    sizes[AppDataType.calendar] = calendarJson?.length ?? 0;

    return sizes;
  }

  /// Formats bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
