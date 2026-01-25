import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';

/// Service to manage folder colors persistently.
/// Colors are stored in a JSON file in the app's documents directory.
class FolderColorService {
  FolderColorService._();
  static final instance = FolderColorService._();

  static const _fileName = '.folder_colors.json';

  /// Map of folder path to color value (as int)
  final Map<String, int> _folderColors = {};

  var _initialized = false;

  /// Initialize the service by loading colors from storage
  Future<void> initialize() async {
    if (_initialized) return;
    await _loadColors();
    _initialized = true;
  }

  /// Get the color for a folder, or null if using default
  Color? getColor(String folderPath) {
    final colorValue = _folderColors[_normalizePath(folderPath)];
    return colorValue != null ? Color(colorValue) : null;
  }

  /// Set the color for a folder
  Future<void> setColor(String folderPath, Color? color) async {
    final normalizedPath = _normalizePath(folderPath);
    if (color == null) {
      _folderColors.remove(normalizedPath);
    } else {
      // ignore: deprecated_member_use
      _folderColors[normalizedPath] = color.value;
    }
    await _saveColors();
  }

  /// Remove color when folder is deleted
  Future<void> removeColor(String folderPath) async {
    _folderColors.remove(_normalizePath(folderPath));
    await _saveColors();
  }

  /// Update color when folder is renamed
  Future<void> renameFolder(String oldPath, String newPath) async {
    final normalizedOld = _normalizePath(oldPath);
    final normalizedNew = _normalizePath(newPath);
    final color = _folderColors.remove(normalizedOld);
    if (color != null) {
      _folderColors[normalizedNew] = color;
      await _saveColors();
    }
  }

  String _normalizePath(String path) {
    // Normalize path for consistent storage
    return path.replaceAll('\\', '/').toLowerCase();
  }

  String get _filePath => '${FileManager.documentsDirectory}/$_fileName';

  Future<void> _loadColors() async {
    try {
      final file = File(_filePath);
      if (file.existsSync()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);
        _folderColors.clear();
        for (final entry in data.entries) {
          _folderColors[entry.key] = entry.value as int;
        }
      }
    } catch (e) {
      debugPrint('Failed to load folder colors: $e');
    }
  }

  Future<void> _saveColors() async {
    try {
      final file = File(_filePath);
      await file.writeAsString(jsonEncode(_folderColors));
    } catch (e) {
      debugPrint('Failed to save folder colors: $e');
    }
  }
}
