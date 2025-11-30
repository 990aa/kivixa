import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/life_git/models/commit.dart';
import 'package:kivixa/services/life_git/models/snapshot.dart';

void main() {
  group('FileSnapshot', () {
    test('creates a valid snapshot', () {
      final snapshot = FileSnapshot(
        path: 'test/note.md',
        blobHash: 'abc123',
        exists: true,
        modifiedAt: DateTime(2024, 1, 1),
      );

      expect(snapshot.path, 'test/note.md');
      expect(snapshot.blobHash, 'abc123');
      expect(snapshot.exists, true);
      expect(snapshot.modifiedAt, DateTime(2024, 1, 1));
    });

    test('serializes to JSON correctly', () {
      final snapshot = FileSnapshot(
        path: 'notes/test.md',
        blobHash: 'hash123',
        exists: true,
        modifiedAt: DateTime(2024, 6, 15, 10, 30),
      );

      final json = snapshot.toJson();

      expect(json['path'], 'notes/test.md');
      expect(json['blobHash'], 'hash123');
      expect(json['exists'], true);
      expect(json['modifiedAt'], '2024-06-15T10:30:00.000');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'path': 'folder/file.md',
        'blobHash': 'xyz789',
        'exists': true,
        'modifiedAt': '2024-03-20T15:45:00.000',
      };

      final snapshot = FileSnapshot.fromJson(json);

      expect(snapshot.path, 'folder/file.md');
      expect(snapshot.blobHash, 'xyz789');
      expect(snapshot.exists, true);
      expect(snapshot.modifiedAt, DateTime(2024, 3, 20, 15, 45));
    });

    test('copyWith creates modified copy', () {
      final original = FileSnapshot(
        path: 'original.md',
        blobHash: 'hash1',
        exists: true,
        modifiedAt: DateTime(2024, 1, 1),
      );

      final modified = original.copyWith(
        path: 'modified.md',
        blobHash: 'hash2',
      );

      expect(modified.path, 'modified.md');
      expect(modified.blobHash, 'hash2');
      expect(modified.exists, true); // Unchanged
      expect(modified.modifiedAt, DateTime(2024, 1, 1)); // Unchanged
    });

    test('equality works correctly', () {
      final snapshot1 = FileSnapshot(
        path: 'test.md',
        blobHash: 'hash123',
        exists: true,
        modifiedAt: DateTime(2024, 1, 1),
      );

      final snapshot2 = FileSnapshot(
        path: 'test.md',
        blobHash: 'hash123',
        exists: true,
        modifiedAt: DateTime(2024, 6, 1), // Different time
      );

      final snapshot3 = FileSnapshot(
        path: 'different.md',
        blobHash: 'hash123',
        exists: true,
        modifiedAt: DateTime(2024, 1, 1),
      );

      expect(snapshot1, equals(snapshot2)); // Same path, hash, exists
      expect(snapshot1, isNot(equals(snapshot3))); // Different path
    });

    test('hashCode is consistent with equality', () {
      final snapshot1 = FileSnapshot(
        path: 'test.md',
        blobHash: 'hash123',
        exists: true,
        modifiedAt: DateTime(2024, 1, 1),
      );

      final snapshot2 = FileSnapshot(
        path: 'test.md',
        blobHash: 'hash123',
        exists: true,
        modifiedAt: DateTime(2024, 6, 1),
      );

      expect(snapshot1.hashCode, equals(snapshot2.hashCode));
    });

    test('handles non-existent file snapshot', () {
      final snapshot = FileSnapshot(
        path: 'deleted.md',
        blobHash: '',
        exists: false,
        modifiedAt: DateTime.now(),
      );

      expect(snapshot.exists, false);
      expect(snapshot.blobHash, isEmpty);
    });
  });

  group('LifeGitCommit', () {
    test('creates a valid commit', () {
      final snapshots = [
        FileSnapshot(
          path: 'note1.md',
          blobHash: 'hash1',
          exists: true,
          modifiedAt: DateTime.now(),
        ),
      ];

      final commit = LifeGitCommit(
        hash: 'commit123',
        message: 'Initial commit',
        timestamp: DateTime(2024, 6, 15),
        parentHash: null,
        snapshots: snapshots,
      );

      expect(commit.hash, 'commit123');
      expect(commit.message, 'Initial commit');
      expect(commit.parentHash, isNull);
      expect(commit.snapshots.length, 1);
    });

    test('serializes to JSON correctly', () {
      final commit = LifeGitCommit(
        hash: 'abc123',
        message: 'Test commit',
        timestamp: DateTime(2024, 6, 15, 10, 30),
        parentHash: 'parent456',
        snapshots: [
          FileSnapshot(
            path: 'test.md',
            blobHash: 'blob789',
            exists: true,
            modifiedAt: DateTime(2024, 6, 15, 10, 30),
          ),
        ],
      );

      final json = commit.toJson();

      expect(json['hash'], 'abc123');
      expect(json['message'], 'Test commit');
      expect(json['parentHash'], 'parent456');
      expect(json['snapshots'], isList);
      expect((json['snapshots'] as List).length, 1);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'hash': 'commit789',
        'message': 'Loaded commit',
        'timestamp': '2024-06-15T12:00:00.000',
        'parentHash': 'parent123',
        'snapshots': [
          {
            'path': 'note.md',
            'blobHash': 'hash999',
            'exists': true,
            'modifiedAt': '2024-06-15T12:00:00.000',
          },
        ],
      };

      final commit = LifeGitCommit.fromJson(json);

      expect(commit.hash, 'commit789');
      expect(commit.message, 'Loaded commit');
      expect(commit.parentHash, 'parent123');
      expect(commit.snapshots.length, 1);
      expect(commit.snapshots.first.path, 'note.md');
    });

    test('copyWith creates modified copy', () {
      final original = LifeGitCommit(
        hash: 'hash1',
        message: 'Original',
        timestamp: DateTime(2024, 1, 1),
        parentHash: null,
        snapshots: [],
      );

      final modified = original.copyWith(hash: 'hash2', message: 'Modified');

      expect(modified.hash, 'hash2');
      expect(modified.message, 'Modified');
      expect(modified.timestamp, DateTime(2024, 1, 1)); // Unchanged
    });

    test('shortHash returns first 7 characters', () {
      final commit = LifeGitCommit(
        hash: 'abcdefghijklmnop',
        message: 'Test',
        timestamp: DateTime.now(),
        snapshots: [],
      );

      expect(commit.shortHash, 'abcdefg');
    });

    test('shortHash handles short hash', () {
      final commit = LifeGitCommit(
        hash: 'abc',
        message: 'Test',
        timestamp: DateTime.now(),
        snapshots: [],
      );

      expect(commit.shortHash, 'abc');
    });

    test('ageString returns correct time descriptions', () {
      final now = DateTime.now();

      // Just now
      final justNow = LifeGitCommit(
        hash: 'h1',
        message: 'Test',
        timestamp: now.subtract(const Duration(seconds: 30)),
        snapshots: [],
      );
      expect(justNow.ageString, 'just now');

      // Minutes ago
      final minutes = LifeGitCommit(
        hash: 'h2',
        message: 'Test',
        timestamp: now.subtract(const Duration(minutes: 5)),
        snapshots: [],
      );
      expect(minutes.ageString, '5 minutes ago');

      // Hours ago
      final hours = LifeGitCommit(
        hash: 'h3',
        message: 'Test',
        timestamp: now.subtract(const Duration(hours: 3)),
        snapshots: [],
      );
      expect(hours.ageString, '3 hours ago');

      // Days ago
      final days = LifeGitCommit(
        hash: 'h4',
        message: 'Test',
        timestamp: now.subtract(const Duration(days: 5)),
        snapshots: [],
      );
      expect(days.ageString, '5 days ago');

      // Months ago
      final months = LifeGitCommit(
        hash: 'h5',
        message: 'Test',
        timestamp: now.subtract(const Duration(days: 60)),
        snapshots: [],
      );
      expect(months.ageString, '2 months ago');

      // Years ago
      final years = LifeGitCommit(
        hash: 'h6',
        message: 'Test',
        timestamp: now.subtract(const Duration(days: 400)),
        snapshots: [],
      );
      expect(years.ageString, '1 years ago');
    });

    test('equality works correctly', () {
      final commit1 = LifeGitCommit(
        hash: 'same_hash',
        message: 'Commit 1',
        timestamp: DateTime(2024, 1, 1),
        snapshots: [],
      );

      final commit2 = LifeGitCommit(
        hash: 'same_hash',
        message: 'Different message',
        timestamp: DateTime(2024, 6, 1),
        snapshots: [],
      );

      final commit3 = LifeGitCommit(
        hash: 'different_hash',
        message: 'Commit 1',
        timestamp: DateTime(2024, 1, 1),
        snapshots: [],
      );

      expect(commit1, equals(commit2)); // Same hash
      expect(commit1, isNot(equals(commit3))); // Different hash
    });

    test('hashCode is consistent with equality', () {
      final commit1 = LifeGitCommit(
        hash: 'same_hash',
        message: 'Commit 1',
        timestamp: DateTime(2024, 1, 1),
        snapshots: [],
      );

      final commit2 = LifeGitCommit(
        hash: 'same_hash',
        message: 'Commit 2',
        timestamp: DateTime(2024, 6, 1),
        snapshots: [],
      );

      expect(commit1.hashCode, equals(commit2.hashCode));
    });
  });

  group('Content-Addressable Storage', () {
    test('SHA-256 hash is consistent', () {
      final content = utf8.encode('Hello, World!');
      final hash1 = sha256.convert(content).toString();
      final hash2 = sha256.convert(content).toString();

      expect(hash1, equals(hash2));
      expect(hash1.length, 64); // SHA-256 produces 64 hex characters
    });

    test('different content produces different hashes', () {
      final content1 = utf8.encode('Hello, World!');
      final content2 = utf8.encode('Hello, World');

      final hash1 = sha256.convert(content1).toString();
      final hash2 = sha256.convert(content2).toString();

      expect(hash1, isNot(equals(hash2)));
    });

    test('hash is deterministic for bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final hash1 = sha256.convert(bytes).toString();
      final hash2 = sha256.convert(bytes).toString();

      expect(hash1, equals(hash2));
    });
  });

  group('JSON Serialization Round-Trip', () {
    test('FileSnapshot survives round-trip', () {
      final original = FileSnapshot(
        path: 'test/nested/path.md',
        blobHash: 'abc123def456',
        exists: true,
        modifiedAt: DateTime(2024, 6, 15, 10, 30, 45),
      );

      final json = original.toJson();
      final restored = FileSnapshot.fromJson(json);

      expect(restored.path, original.path);
      expect(restored.blobHash, original.blobHash);
      expect(restored.exists, original.exists);
      expect(restored.modifiedAt, original.modifiedAt);
    });

    test('LifeGitCommit survives round-trip', () {
      final original = LifeGitCommit(
        hash: 'commit_hash_123',
        message: 'Test commit with special chars: 日本語 émojis 🎉',
        timestamp: DateTime(2024, 6, 15, 10, 30, 45),
        parentHash: 'parent_hash_456',
        snapshots: [
          FileSnapshot(
            path: 'file1.md',
            blobHash: 'blob1',
            exists: true,
            modifiedAt: DateTime(2024, 6, 15),
          ),
          FileSnapshot(
            path: 'file2.md',
            blobHash: 'blob2',
            exists: false,
            modifiedAt: DateTime(2024, 6, 14),
          ),
        ],
      );

      final json = original.toJson();
      final restored = LifeGitCommit.fromJson(json);

      expect(restored.hash, original.hash);
      expect(restored.message, original.message);
      expect(restored.timestamp, original.timestamp);
      expect(restored.parentHash, original.parentHash);
      expect(restored.snapshots.length, original.snapshots.length);
      expect(restored.snapshots[0].path, original.snapshots[0].path);
      expect(restored.snapshots[1].exists, original.snapshots[1].exists);
    });

    test('Commit with null parentHash survives round-trip', () {
      final original = LifeGitCommit(
        hash: 'first_commit',
        message: 'Initial commit',
        timestamp: DateTime.now(),
        parentHash: null,
        snapshots: [],
      );

      final json = original.toJson();
      final restored = LifeGitCommit.fromJson(json);

      expect(restored.parentHash, isNull);
    });
  });
}
