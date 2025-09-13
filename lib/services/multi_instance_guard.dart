import 'dart:async';
import 'package:uuid/uuid.dart';

import '../data/repository.dart';

class DocumentLockedException implements Exception {
  final String message;
  DocumentLockedException(this.message);
}

class MultiInstanceGuard {
  final Repository _repo;
  final String _instanceId = Uuid().v4();
  static const _lockTimeout = Duration(seconds: 30);

  MultiInstanceGuard(this._repo);

  Future<void> acquireLock(int documentId) async {
    final existingLock = await _repo.getDocumentLock(documentId);

    if (existingLock != null) {
      final lockTime = DateTime.fromMillisecondsSinceEpoch(existingLock['timestamp']);
      if (DateTime.now().difference(lockTime) < _lockTimeout) {
        if (existingLock['instance_id'] != _instanceId) {
          throw DocumentLockedException('Document is locked by another instance.');
        }
      } else {
        // Lock has expired, so we can acquire it.
        await _repo.deleteDocumentLock(documentId);
      }
    }

    await _repo.createDocumentLock({
      'document_id': documentId,
      'instance_id': _instanceId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> releaseLock(int documentId) async {
    final existingLock = await _repo.getDocumentLock(documentId);
    if (existingLock != null && existingLock['instance_id'] == _instanceId) {
      await _repo.deleteDocumentLock(documentId);
    }
  }

  Future<bool> checkLock(int documentId) async {
    final existingLock = await _repo.getDocumentLock(documentId);
    if (existingLock != null) {
      final lockTime = DateTime.fromMillisecondsSinceEpoch(existingLock['timestamp']);
      if (DateTime.now().difference(lockTime) < _lockTimeout) {
        return true;
      }
    }
    return false;
  }
}