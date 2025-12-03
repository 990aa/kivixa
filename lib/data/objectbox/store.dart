// ObjectBox Store Manager
//
// Initializes and manages the ObjectBox store for vector search.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Generated file - run `dart run build_runner build` to generate
// import 'package:kivixa/objectbox.g.dart';

/// Manages the ObjectBox store instance
class ObjectBoxStore {
  static ObjectBoxStore? _instance;
  // late final Store store;

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

    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    // TODO: Uncomment when objectbox.g.dart is generated
    // store = await openStore(directory: dbDir.path);

    _isInitialized = true;
    debugPrint('ObjectBox store initialized at: ${dbDir.path}');
  }

  /// Close the store
  void close() {
    if (!_isInitialized) return;

    // store.close();
    _isInitialized = false;
    debugPrint('ObjectBox store closed');
  }
}
