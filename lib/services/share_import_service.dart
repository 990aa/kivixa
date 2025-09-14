// Copyright 2025 Kivixa. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: unused_import

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/services/import_manager.dart';
import 'package:kivixa/platform/storage_paths.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:uri_to_file/uri_to_file.dart';

final _log = Logger('ShareImportService');

/// Handles incoming share intents from Android, copies the shared file into the
/// app's assets directory, and then passes it to the [ImportManager] for
/// processing. The source URI is recorded for traceability.
class ShareImportService {
  final ImportManager _importManager;
  final StoragePaths _storagePaths; // This field might be unused now
  static const _channel = MethodChannel('com.kivixa.share/intent');

  ShareImportService(this._importManager, this._storagePaths) {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(_handleMethod);
    }
  }

  Future<void> _handleMethod(MethodCall call) async {
    if (call.method == 'handleShare') {
      final uri = call.arguments as String?;
      if (uri != null) {
        await handleSharedUri(Uri.parse(uri));
      }
    }
  }

  /// Handles a shared URI by copying it to a local directory and importing it.
  Future<void> handleSharedUri(Uri uri) async {
    _log.info('Handling shared URI: $uri');
    try {
      final originalFile = await toFile(uri);
      final fileName = p.basename(originalFile.path);
      // Corrected the call to the static method
      final destinationDir = await StoragePaths.getAssetsOriginalDir();
      final destinationFile = File(p.join(destinationDir.path, fileName));

      // Ensure the destination directory exists.
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      // Copy the file.
      await originalFile.copy(destinationFile.path);
      _log.info('Copied shared file to: ${destinationFile.path}');

      // Invoke the import manager.
      // Removed sourceUri: uri, as it's not a defined parameter in ImportManager.importFile
      await _importManager.importFile(
        destinationFile.path, // Changed to pass the path string
      );
      _log.info('Successfully imported file from URI: $uri');
    } catch (e, st) {
      _log.severe('Failed to handle shared URI: $uri', e, st);
      // Optionally, show a user-facing error message.
    }
  }
}
