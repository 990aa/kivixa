// ObjectBox Store Manager
//
// Initializes and manages the ObjectBox store for vector search.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kivixa/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';

/// Manages the ObjectBox store instance
class ObjectBoxStore {
  static ObjectBoxStore? _instance;
  late final Store store;

  ObjectBoxStore._();

  /// Get the singleton instance
  static ObjectBoxStore get instance {
    _instance ??= ObjectBoxStore._();
    return _instance!;
  }

  var _isInitialized = false;

  /// Whether the store is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the ObjectBox store
  Future<void> initialize() async {
    if (_isInitialized) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${docsDir.path}/objectbox');

    // ignore: avoid_slow_async_io
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    store = await openStore(directory: dbDir.path);

    _isInitialized = true;
    debugPrint('ObjectBox store initialized at: ${dbDir.path}');
  }

  /// Close the store
  void close() {
    if (!_isInitialized) return;

    store.close();
    _isInitialized = false;
    debugPrint('ObjectBox store closed');
  }
}
