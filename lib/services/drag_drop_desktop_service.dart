// Copyright 2025 Kivixa. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/widgets.dart'; // Added this import
import 'package_files/desktop_drop.dart';
import 'package:kivixa/services/import_manager.dart';
import 'package:logging/logging.dart';
import 'package:cross_file/cross_file.dart';

final _log = Logger('DragDropDesktopService');

/// A data-only callback to report the status of a drag-and-drop import.
/// The UI can use this to display toasts or other notifications.
typedef DragDropStatusCallback = void Function(DragDropStatus status);

/// The status of a drag-and-drop import operation.
class DragDropStatus {
  final String message;
  final bool isError;

  DragDropStatus(this.message, {this.isError = false});
}

/// Handles files dragged into the app window on desktop platforms (Windows, macOS, Linux).
/// It uses the [ImportManager] to import the files and provides a status callback.
class DragDropDesktopService {
  final ImportManager _importManager;
  final DragDropStatusCallback onStatus;

  DragDropDesktopService(this._importManager, {required this.onStatus}) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _setup();
    }
  }

  void _setup() {
    // This is a conceptual setup. An actual implementation would need a
    // plugin like `desktop_drop` and an appropriate widget in the UI tree
    // to act as the drop target.
    _log.info('Drag and drop service initialized for desktop.');
  }

  /// This method would be called by the drop target widget when files are dropped.
  Future<void> onFilesDropped(List<XFile> files) async {
    _log.info('Files dropped: ${files.length}');
    for (final file in files) {
      try {
        final f = File(file.path);
        await _importManager.importFile(f.path);
        onStatus(DragDropStatus('Successfully imported ${file.name}'));
      } catch (e, st) {
        _log.severe('Failed to import dropped file: ${file.path}', e, st);
        onStatus(DragDropStatus('Failed to import ${file.name}', isError: true));
      }
    }
  }

  /// Call this method from the root widget of your app.
  Widget buildDropTarget({required Widget child}) {
    return DropTarget(
      onDragDone: (detail) async {
        await onFilesDropped(detail.files);
      },
      child: child,
    );
  }
}
