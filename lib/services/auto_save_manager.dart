import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

/// Automatic save manager with crash recovery
/// 
/// Features:
/// - Auto-save every 2 minutes
/// - Emergency save on app lifecycle changes (pause, background)
/// - Atomic file writes (prevents corruption)
/// - Backup retention (can restore from previous save)
/// - Crash recovery (detect incomplete saves)
/// 
/// Usage:
/// ```dart
/// final autoSave = AutoSaveManager(
///   savePath: '/path/to/document.json',
///   onAutoSave: () async => getCurrentDocumentData(),
/// );
/// autoSave.start();
/// // Mark changes
/// autoSave.markUnsavedChanges();
/// // Cleanup on dispose
/// autoSave.stop();
/// ```
class AutoSaveManager with WidgetsBindingObserver {
  /// Path to the main save file
  final String savePath;

  /// Callback to get current document data
  final Future<Map<String, dynamic>> Function() onAutoSave;

  /// Callback when auto-save completes
  final void Function()? onSaveComplete;

  /// Callback when auto-save fails
  final void Function(Object error)? onSaveError;

  /// Auto-save interval (default: 2 minutes)
  final Duration autoSaveInterval;

  /// Whether to show debug logs
  final bool verbose;

  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  DateTime? _lastSaveTime;

  AutoSaveManager({
    required this.savePath,
    required this.onAutoSave,
    this.onSaveComplete,
    this.onSaveError,
    this.autoSaveInterval = const Duration(minutes: 2),
    this.verbose = false,
  });

  /// Start auto-save timer and lifecycle observer
  void start() {
    _log('Starting auto-save manager');
    
    // Start periodic auto-save
    _autoSaveTimer = Timer.periodic(autoSaveInterval, (_) {
      if (_hasUnsavedChanges && !_isSaving) {
        _performAutoSave();
      }
    });

    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    
    _log('Auto-save started (interval: ${autoSaveInterval.inMinutes} minutes)');
  }

  /// Stop auto-save timer and lifecycle observer
  void stop() {
    _log('Stopping auto-save manager');
    
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    
    WidgetsBinding.instance.removeObserver(this);
    
    _log('Auto-save stopped');
  }

  /// Mark that there are unsaved changes
  void markUnsavedChanges() {
    _hasUnsavedChanges = true;
    _log('Marked unsaved changes');
  }

  /// Clear unsaved changes flag
  void clearUnsavedChanges() {
    _hasUnsavedChanges = false;
  }

  /// Check if there are unsaved changes
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Get last save time
  DateTime? get lastSaveTime => _lastSaveTime;

  /// Perform manual save (bypasses unsaved changes check)
  Future<bool> forceSave() async {
    return await _performAutoSave(force: true);
  }

  /// Perform auto-save
  Future<bool> _performAutoSave({bool force = false}) async {
    if (_isSaving) {
      _log('Save already in progress, skipping');
      return false;
    }

    if (!force && !_hasUnsavedChanges) {
      _log('No unsaved changes, skipping');
      return false;
    }

    _isSaving = true;
    _log('Starting auto-save...');

    try {
      // Get current document data
      final data = await onAutoSave();
      
      // Serialize to JSON
      final jsonString = json.encode(data);
      
      // Atomic file write
      await _atomicWrite(jsonString);
      
      _hasUnsavedChanges = false;
      _lastSaveTime = DateTime.now();
      
      _log('Auto-save completed successfully');
      onSaveComplete?.call();
      
      return true;
    } catch (e, stackTrace) {
      _log('Auto-save failed: $e\n$stackTrace');
      onSaveError?.call(e);
      return false;
    } finally {
      _isSaving = false;
    }
  }

  /// Atomic file write with backup
  /// 
  /// Process:
  /// 1. Write to .tmp file
  /// 2. Rename current file to .backup (if exists)
  /// 3. Rename .tmp to current file
  /// 4. Delete old .backup
  /// 
  /// This ensures:
  /// - No data loss if write fails
  /// - No corruption if app crashes during write
  /// - Always have working backup
  Future<void> _atomicWrite(String content) async {
    final file = File(savePath);
    final tmpFile = File('$savePath.tmp');
    final backupFile = File('$savePath.backup');

    // 1. Write to temporary file
    _log('Writing to temporary file: ${tmpFile.path}');
    await tmpFile.writeAsString(content, flush: true);

    // 2. Move current file to backup (if exists)
    if (await file.exists()) {
      _log('Moving current file to backup');
      
      // Delete old backup if exists
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      
      await file.rename(backupFile.path);
    }

    // 3. Move temporary file to current
    _log('Moving temporary file to current');
    await tmpFile.rename(file.path);

    _log('Atomic write completed');
  }

  /// Recover from crash or incomplete save
  /// 
  /// Call this on app startup to check for corrupted saves
  static Future<RecoveryResult> recoverIfNeeded(String savePath) async {
    final file = File(savePath);
    final tmpFile = File('$savePath.tmp');
    final backupFile = File('$savePath.backup');

    // Check if temporary file exists (incomplete save)
    if (await tmpFile.exists()) {
      debugPrint('Found incomplete save, cleaning up');
      await tmpFile.delete();
      
      if (!await file.exists() && await backupFile.exists()) {
        // Main file missing, restore from backup
        debugPrint('Restoring from backup');
        await backupFile.copy(file.path);
        return RecoveryResult.restoredFromBackup;
      }
      
      return RecoveryResult.cleanedIncomplete;
    }

    // Check if main file is corrupted
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        json.decode(content); // Validate JSON
        return RecoveryResult.noRecoveryNeeded;
      } catch (e) {
        // Corrupted, try to restore from backup
        if (await backupFile.exists()) {
          debugPrint('Main file corrupted, restoring from backup');
          await file.delete();
          await backupFile.copy(file.path);
          return RecoveryResult.restoredFromBackup;
        }
        
        return RecoveryResult.unrecoverable;
      }
    }

    return RecoveryResult.noRecoveryNeeded;
  }

  /// App lifecycle observer - emergency save on pause/background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log('App lifecycle changed: $state');
    
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App going to background or closing - emergency save!
      if (_hasUnsavedChanges && !_isSaving) {
        _log('Emergency save triggered by lifecycle change');
        _performAutoSave();
      }
    }
  }

  void _log(String message) {
    if (verbose) {
      debugPrint('[AutoSave] $message');
    }
  }
}

/// Result of crash recovery operation
enum RecoveryResult {
  /// No recovery needed, file is fine
  noRecoveryNeeded,
  
  /// Cleaned up incomplete save
  cleanedIncomplete,
  
  /// Restored from backup file
  restoredFromBackup,
  
  /// File is corrupted and no backup available
  unrecoverable,
}

/// Extension to get human-readable description
extension RecoveryResultExtension on RecoveryResult {
  String get description {
    switch (this) {
      case RecoveryResult.noRecoveryNeeded:
        return 'File loaded successfully';
      case RecoveryResult.cleanedIncomplete:
        return 'Cleaned up incomplete save from previous session';
      case RecoveryResult.restoredFromBackup:
        return 'Restored from backup (main file was corrupted)';
      case RecoveryResult.unrecoverable:
        return 'File corrupted and no backup available';
    }
  }

  bool get isSuccess => 
      this == RecoveryResult.noRecoveryNeeded || 
      this == RecoveryResult.cleanedIncomplete ||
      this == RecoveryResult.restoredFromBackup;
}
