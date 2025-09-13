import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum BackupFrequency { daily, weekly, monthly }

class BackupManager {
  static final BackupManager _instance = BackupManager._internal();
  factory BackupManager() => _instance;
  BackupManager._internal();

  late final Directory _backupDir;
  bool _isInitialized = false;
  Timer? _scheduledBackupTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;
    final documentsDir = await getApplicationDocumentsDirectory();
    _backupDir = Directory(p.join(documentsDir.path, 'backups'));
    if (!await _backupDir.exists()) {
      await _backupDir.create(recursive: true);
    }
    _isInitialized = true;
  }

  Future<File> createBackup() async {
    if (!_isInitialized) await initialize();

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile = File(p.join(_backupDir.path, 'kivixa_backup_$timestamp.kivixa.zip'));

    final encoder = ZipFileEncoder();
    encoder.create(backupFile.path);

    // Add SQLite database
    final dbPath = await _getDbPath();
    encoder.addFile(File(dbPath));

    // Add assets
    final assetsPath = await _getAssetsPath();
    encoder.addDirectory(Directory(assetsPath));

    // Create manifest
    final manifest = await _createManifest();
    encoder.addArchiveFile(ArchiveFile('manifest.json', utf8.encode(jsonEncode(manifest)).length, utf8.encode(jsonEncode(manifest))));

    // Create hash file
    final backupHash = await _calculateFileHash(backupFile);
    encoder.addArchiveFile(ArchiveFile('backup.sha256', backupHash.length, utf8.encode(backupHash)));

    encoder.close();
    return backupFile;
  }

  Future<bool> validateBackup(File backupFile) async {
    final archive = ZipDecoder().decodeBytes(backupFile.readAsBytesSync());
    final manifestFile = archive.findFile('manifest.json');
    final hashFile = archive.findFile('backup.sha256');

    if (manifestFile == null || hashFile == null) return false;

    // Validate hash
    final storedHash = utf8.decode(hashFile.content);
    final actualHash = await _calculateFileHash(backupFile, skipHashFile: true);
    if (storedHash != actualHash) return false;

    // Further validation can be done against the manifest
    return true;
  }

  Future<void> restoreBackup(File backupFile) async {
    if (!await validateBackup(backupFile)) {
      throw Exception('Backup validation failed. Restore aborted.');
    }

    final archive = ZipDecoder().decodeBytes(backupFile.readAsBytesSync());
    final dbPath = await _getDbPath();
    final assetsPath = await _getAssetsPath();

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final restoredFile = File(p.join(p.dirname(dbPath), '..', filename));
        await restoredFile.create(recursive: true);
        await restoredFile.writeAsBytes(data);
      }
    }
  }

  void scheduleBackups(BackupFrequency frequency, int retainN) {
    _scheduledBackupTimer?.cancel();
    Duration interval;
    switch (frequency) {
      case BackupFrequency.daily:
        interval = const Duration(days: 1);
        break;
      case BackupFrequency.weekly:
        interval = const Duration(days: 7);
        break;
      case BackupFrequency.monthly:
        // This is a simplification. A real implementation would handle month ends.
        interval = const Duration(days: 30);
        break;
    }

    _scheduledBackupTimer = Timer.periodic(interval, (timer) {
      createBackup().then((_) => _applyRetentionPolicy(frequency, retainN));
    });
  }

  void _applyRetentionPolicy(BackupFrequency frequency, int retainN) {
    final backups = _backupDir.listSync()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    if (backups.length > retainN) {
      for (int i = retainN; i < backups.length; i++) {
        backups[i].delete();
      }
    }
  }

  Future<String> _getDbPath() async {
    final dbFolder = await getApplicationSupportDirectory();
    return p.join(dbFolder.path, 'app.db');
  }

  Future<String> _getAssetsPath() async {
    final assetsFolder = await getApplicationSupportDirectory();
    return p.join(assetsFolder.path, 'assets_original');
  }

  Future<Map<String, dynamic>> _createManifest() async {
    return {
      'createdAt': DateTime.now().toIso8601String(),
      'version': '1.0.0', // App version
      'files': [
        'app.db',
        'assets_original/'
      ]
    };
  }

  Future<String> _calculateFileHash(File file, {bool skipHashFile = false}) async {
    final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
    final digest = sha256.newInstance();

    for (final file in archive) {
      if (skipHashFile && file.name == 'backup.sha256') continue;
      digest.add(file.content);
    }
    return digest.close().toString();
  }
}
