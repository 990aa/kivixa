// ignore_for_file: avoid_slow_async_io
// This service intentionally uses async I/O for content-addressable storage

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/services/life_git/models/commit.dart';
import 'package:kivixa/services/life_git/models/snapshot.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// Life Git - Version control system for notes
/// Uses content-addressable storage similar to Git's internal structure
class LifeGitService {
  static final _log = Logger('LifeGitService');
  static LifeGitService? _instance;

  static LifeGitService get instance {
    _instance ??= LifeGitService._();
    return _instance!;
  }

  LifeGitService._();

  /// Base directory for Life Git storage
  late String _gitDir;

  /// Objects directory (content-addressable blobs)
  String get _objectsDir => p.join(_gitDir, 'objects');

  /// Commits directory
  String get _commitsDir => p.join(_gitDir, 'commits');

  /// Refs directory (branch pointers)
  String get _refsDir => p.join(_gitDir, 'refs');

  /// HEAD file (current branch)
  String get _headFile => p.join(_gitDir, 'HEAD');

  /// Debounce timer for auto-commits
  Timer? _autoCommitTimer;

  /// Duration to wait before auto-committing (debounce)
  static const autoCommitDelay = Duration(seconds: 2);

  /// Initialize the Life Git system
  Future<void> initialize() async {
    _gitDir = p.join(FileManager.documentsDirectory, '.lifegit');

    // Create directory structure
    await Directory(_objectsDir).create(recursive: true);
    await Directory(_commitsDir).create(recursive: true);
    await Directory(_refsDir).create(recursive: true);

    // Initialize HEAD if it doesn't exist
    final headFile = File(_headFile);
    if (!await headFile.exists()) {
      await headFile.writeAsString('ref: refs/main');
    }

    // Initialize main branch if it doesn't exist
    final mainRef = File(p.join(_refsDir, 'main'));
    if (!await mainRef.exists()) {
      await mainRef.writeAsString('');
    }

    _log.info('Life Git initialized at $_gitDir');

    // Run auto-cleanup if enabled
    await _runAutoCleanupIfNeeded();
  }

  /// Run auto-cleanup if configured and enough time has passed
  Future<void> _runAutoCleanupIfNeeded() async {
    final days = stows.lifeGitAutoCleanupDays.value;
    if (days <= 0) return; // Auto-cleanup disabled

    // Check if we already ran cleanup today
    final lastCleanup = stows.lifeGitLastAutoCleanup.value;
    if (lastCleanup != null) {
      final lastDate = DateTime.tryParse(lastCleanup);
      if (lastDate != null) {
        final today = DateTime.now();
        if (lastDate.year == today.year &&
            lastDate.month == today.month &&
            lastDate.day == today.day) {
          _log.fine('Auto-cleanup already ran today, skipping');
          return;
        }
      }
    }

    try {
      _log.info('Running auto-cleanup for commits older than $days days');
      final deleted = await deleteHistoryOlderThan(days);
      stows.lifeGitLastAutoCleanup.value = DateTime.now().toIso8601String();
      _log.info('Auto-cleanup completed: deleted $deleted commits');
    } catch (e) {
      _log.warning('Auto-cleanup failed: $e');
    }
  }

  /// Compute SHA-256 hash of content
  String _computeHash(Uint8List content) {
    return sha256.convert(content).toString();
  }

  /// Store a blob (file content) and return its hash
  Future<String> _storeBlob(Uint8List content) async {
    final hash = _computeHash(content);
    final blobPath = p.join(
      _objectsDir,
      hash.substring(0, 2),
      hash.substring(2),
    );

    final blobFile = File(blobPath);
    if (!await blobFile.exists()) {
      await blobFile.parent.create(recursive: true);
      await blobFile.writeAsBytes(content);
    }

    return hash;
  }

  /// Retrieve a blob by its hash
  Future<Uint8List?> _getBlob(String hash) async {
    final blobPath = p.join(
      _objectsDir,
      hash.substring(0, 2),
      hash.substring(2),
    );
    final blobFile = File(blobPath);

    if (await blobFile.exists()) {
      return await blobFile.readAsBytes();
    }
    return null;
  }

  /// Create a snapshot of a single file
  Future<FileSnapshot> snapshotFile(String filePath) async {
    // Normalize the path - remove leading slash if present since we're joining with documentsDirectory
    final normalizedPath = filePath.startsWith('/')
        ? filePath.substring(1)
        : filePath;
    final fullPath = p.join(FileManager.documentsDirectory, normalizedPath);
    final file = File(fullPath);

    _log.fine('Snapshotting file: $filePath -> $fullPath');

    if (!await file.exists()) {
      _log.fine('File does not exist: $fullPath');
      return FileSnapshot(
        path: filePath,
        blobHash: '',
        exists: false,
        modifiedAt: DateTime.now(),
      );
    }

    final content = await file.readAsBytes();
    final blobHash = await _storeBlob(content);
    final stat = await file.stat();

    _log.fine(
      'Created snapshot for: $filePath with hash: ${blobHash.substring(0, 8)}',
    );

    return FileSnapshot(
      path: filePath,
      blobHash: blobHash,
      exists: true,
      modifiedAt: stat.modified,
    );
  }

  /// Create a snapshot of all files in a directory
  Future<List<FileSnapshot>> snapshotDirectory(String dirPath) async {
    final snapshots = <FileSnapshot>[];
    final dir = Directory(p.join(FileManager.documentsDirectory, dirPath));

    if (!await dir.exists()) return snapshots;

    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          try {
            final relativePath = p.relative(
              entity.path,
              from: FileManager.documentsDirectory,
            );

            // Skip .lifegit directory and system files
            if (relativePath.startsWith('.lifegit')) continue;
            if (relativePath.contains(r'$'))
              continue; // Skip system files like $Recycle.Bin
            if (relativePath.startsWith('.')) continue; // Skip hidden files

            final snapshot = await snapshotFile(relativePath);
            snapshots.add(snapshot);
          } catch (e) {
            // Skip files that can't be accessed
            _log.fine('Skipping inaccessible file: ${entity.path} - $e');
          }
        }
      }
    } catch (e) {
      _log.warning('Error listing directory $dirPath: $e');
    }

    return snapshots;
  }

  /// Create a commit with the given snapshots
  Future<LifeGitCommit> createCommit({
    required List<FileSnapshot> snapshots,
    required String message,
    String? parentHash,
  }) async {
    if (snapshots.isEmpty) {
      _log.warning('createCommit called with empty snapshots list');
    }

    // Filter out snapshots where file doesn't exist (unless tracking deletions)
    final validSnapshots = snapshots.where((s) => s.exists).toList();
    if (validSnapshots.isEmpty && snapshots.isNotEmpty) {
      _log.warning('All snapshots have exists=false, files may not be found');
    }

    // Get parent hash from current HEAD if not provided
    parentHash ??= await _getCurrentCommitHash();
    _log.fine('Parent hash: $parentHash');

    final commit = LifeGitCommit(
      hash: '', // Will be computed
      message: message,
      timestamp: DateTime.now(),
      parentHash: parentHash,
      snapshots: snapshots,
    );

    // Serialize and store commit
    final commitJson = jsonEncode(commit.toJson());
    final commitBytes = utf8.encode(commitJson);
    final commitHash = _computeHash(Uint8List.fromList(commitBytes));

    final commitWithHash = commit.copyWith(hash: commitHash);

    // Store commit
    final commitFile = File(p.join(_commitsDir, commitHash));
    await commitFile.writeAsString(jsonEncode(commitWithHash.toJson()));
    _log.fine('Stored commit at: ${commitFile.path}');

    // Update HEAD
    await _updateHead(commitHash);

    _log.info(
      'Created commit: $commitHash - $message (${snapshots.length} files)',
    );

    return commitWithHash;
  }

  /// Get the current commit hash from HEAD
  Future<String?> _getCurrentCommitHash() async {
    final headFile = File(_headFile);
    if (!await headFile.exists()) return null;

    final headContent = await headFile.readAsString();

    if (headContent.startsWith('ref: ')) {
      // HEAD points to a branch
      final refName = headContent.substring(5).trim();
      final refFile = File(p.join(_gitDir, refName));
      if (await refFile.exists()) {
        final hash = await refFile.readAsString();
        return hash.isEmpty ? null : hash.trim();
      }
      return null;
    }

    // HEAD is a direct commit hash
    return headContent.trim().isEmpty ? null : headContent.trim();
  }

  /// Update HEAD to point to a commit
  Future<void> _updateHead(String commitHash) async {
    final headFile = File(_headFile);
    final headContent = await headFile.readAsString();

    if (headContent.startsWith('ref: ')) {
      // Update the branch reference
      final refName = headContent.substring(5).trim();
      final refFile = File(p.join(_gitDir, refName));
      await refFile.writeAsString(commitHash);
    } else {
      // Detached HEAD - update directly
      await headFile.writeAsString(commitHash);
    }
  }

  /// Get a commit by its hash
  Future<LifeGitCommit?> getCommit(String hash) async {
    final commitFile = File(p.join(_commitsDir, hash));
    if (!await commitFile.exists()) return null;

    final content = await commitFile.readAsString();
    return LifeGitCommit.fromJson(jsonDecode(content) as Map<String, dynamic>);
  }

  /// Get the commit history (walk back from HEAD)
  Future<List<LifeGitCommit>> getHistory({int limit = 100}) async {
    final commits = <LifeGitCommit>[];
    String? currentHash = await _getCurrentCommitHash();

    while (currentHash != null && commits.length < limit) {
      final commit = await getCommit(currentHash);
      if (commit == null) break;

      commits.add(commit);
      currentHash = commit.parentHash;
    }

    return commits;
  }

  /// Get commits for a specific file
  Future<List<LifeGitCommit>> getFileHistory(
    String filePath, {
    int limit = 50,
  }) async {
    final allCommits = await getHistory(limit: 500);
    final fileCommits = <LifeGitCommit>[];

    for (final commit in allCommits) {
      final hasFile = commit.snapshots.any((s) => s.path == filePath);
      if (hasFile) {
        fileCommits.add(commit);
        if (fileCommits.length >= limit) break;
      }
    }

    return fileCommits;
  }

  /// Restore a file to a specific commit
  Future<Uint8List?> getFileAtCommit(String filePath, String commitHash) async {
    final commit = await getCommit(commitHash);
    if (commit == null) return null;

    final snapshot = commit.snapshots
        .where((s) => s.path == filePath)
        .firstOrNull;
    if (snapshot == null || !snapshot.exists) return null;

    return await _getBlob(snapshot.blobHash);
  }

  /// Get commits within a time range
  Future<List<LifeGitCommit>> getCommitsInRange(
    DateTime start,
    DateTime end, {
    int limit = 100,
  }) async {
    final allCommits = await getHistory(limit: 500);
    return allCommits
        .where((c) => c.timestamp.isAfter(start) && c.timestamp.isBefore(end))
        .take(limit)
        .toList();
  }

  /// Get the closest commit to a specific timestamp
  Future<LifeGitCommit?> getCommitAtTime(DateTime time) async {
    final commits = await getHistory(limit: 500);
    if (commits.isEmpty) return null;

    // Find the commit closest to the given time but not after it
    LifeGitCommit? closest;
    for (final commit in commits) {
      if (commit.timestamp.isBefore(time) ||
          commit.timestamp.isAtSameMomentAs(time)) {
        if (closest == null || commit.timestamp.isAfter(closest.timestamp)) {
          closest = commit;
        }
      }
    }

    return closest ?? commits.last;
  }

  /// Auto-commit with debouncing (called when a file is saved)
  void scheduleAutoCommit(String filePath) {
    _autoCommitTimer?.cancel();
    _autoCommitTimer = Timer(autoCommitDelay, () async {
      try {
        final snapshot = await snapshotFile(filePath);
        await createCommit(
          snapshots: [snapshot],
          message: 'Auto-save: ${p.basename(filePath)}',
        );
      } catch (e) {
        _log.warning('Auto-commit failed: $e');
      }
    });
  }

  /// Create a full backup commit of all files
  Future<LifeGitCommit> createFullBackup({String? message}) async {
    final snapshots = await snapshotDirectory('/');
    return await createCommit(
      snapshots: snapshots,
      message: message ?? 'Full backup',
    );
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final objectsDir = Directory(_objectsDir);
    final commitsDir = Directory(_commitsDir);

    int objectCount = 0;
    int objectsSize = 0;
    int commitCount = 0;

    if (await objectsDir.exists()) {
      await for (final entity in objectsDir.list(recursive: true)) {
        if (entity is File) {
          objectCount++;
          objectsSize += await entity.length();
        }
      }
    }

    if (await commitsDir.exists()) {
      await for (final entity in commitsDir.list()) {
        if (entity is File) {
          commitCount++;
        }
      }
    }

    return {
      'objectCount': objectCount,
      'objectsSize': objectsSize,
      'commitCount': commitCount,
      'objectsSizeFormatted': _formatBytes(objectsSize),
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clean up old objects that are no longer referenced
  Future<int> garbageCollect() async {
    // Collect all referenced blob hashes
    final referencedHashes = <String>{};
    final commits = await getHistory(limit: 10000);

    for (final commit in commits) {
      for (final snapshot in commit.snapshots) {
        if (snapshot.blobHash.isNotEmpty) {
          referencedHashes.add(snapshot.blobHash);
        }
      }
    }

    // Remove unreferenced blobs
    int removedCount = 0;
    final objectsDir = Directory(_objectsDir);

    if (await objectsDir.exists()) {
      await for (final subDir in objectsDir.list()) {
        if (subDir is Directory) {
          await for (final file in subDir.list()) {
            if (file is File) {
              final hash = p.basename(subDir.path) + p.basename(file.path);
              if (!referencedHashes.contains(hash)) {
                await file.delete();
                removedCount++;
              }
            }
          }
        }
      }
    }

    _log.info('Garbage collection removed $removedCount objects');
    return removedCount;
  }

  /// Delete all history (commits and objects)
  Future<void> deleteAllHistory() async {
    _log.warning('Deleting all Life Git history');

    // Delete all commits
    final commitsDir = Directory(_commitsDir);
    if (await commitsDir.exists()) {
      await for (final file in commitsDir.list()) {
        if (file is File) {
          await file.delete();
        }
      }
    }

    // Delete all objects
    final objectsDir = Directory(_objectsDir);
    if (await objectsDir.exists()) {
      await for (final subDir in objectsDir.list()) {
        if (subDir is Directory) {
          await subDir.delete(recursive: true);
        }
      }
    }

    // Reset branch reference
    final mainRef = File(p.join(_refsDir, 'main'));
    if (await mainRef.exists()) {
      await mainRef.writeAsString('');
    }

    _log.info('All Life Git history deleted');
  }

  /// Delete history older than a specified number of days
  Future<int> deleteHistoryOlderThan(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final commits = await getHistory(limit: 10000);
    int deletedCount = 0;

    // Find commits to delete (older than cutoff)
    final commitsToDelete = commits
        .where((c) => c.timestamp.isBefore(cutoffDate))
        .toList();

    for (final commit in commitsToDelete) {
      final commitFile = File(p.join(_commitsDir, commit.hash));
      if (await commitFile.exists()) {
        await commitFile.delete();
        deletedCount++;
      }
    }

    // Run garbage collection to clean up orphaned blobs
    if (deletedCount > 0) {
      await garbageCollect();
    }

    _log.info('Deleted $deletedCount commits older than $days days');
    return deletedCount;
  }

  /// Delete history for a specific file
  Future<int> deleteFileHistory(String filePath) async {
    final commits = await getHistory(limit: 10000);
    int deletedCount = 0;

    for (final commit in commits) {
      // Check if this commit only contains the specified file
      final hasOnlyThisFile =
          commit.snapshots.length == 1 &&
          commit.snapshots.first.path == filePath;

      if (hasOnlyThisFile) {
        final commitFile = File(p.join(_commitsDir, commit.hash));
        if (await commitFile.exists()) {
          await commitFile.delete();
          deletedCount++;
        }
      }
    }

    // Run garbage collection to clean up orphaned blobs
    if (deletedCount > 0) {
      await garbageCollect();
    }

    _log.info('Deleted $deletedCount commits for file: $filePath');
    return deletedCount;
  }
}
