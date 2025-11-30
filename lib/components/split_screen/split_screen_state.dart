import 'package:flutter/foundation.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';

/// Represents the type of file that can be opened in a pane
enum PaneFileType {
  handwritten, // .kvx files
  markdown, // .md files
  textDocument, // .kvtx files
  none, // Empty pane
}

/// Represents a single pane in the split screen
class PaneState {
  final String? filePath;
  final PaneFileType fileType;
  final bool isActive;

  const PaneState({
    this.filePath,
    this.fileType = PaneFileType.none,
    this.isActive = false,
  });

  PaneState copyWith({
    String? filePath,
    PaneFileType? fileType,
    bool? isActive,
  }) {
    return PaneState(
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isEmpty => filePath == null || fileType == PaneFileType.none;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaneState &&
        other.filePath == filePath &&
        other.fileType == fileType &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(filePath, fileType, isActive);
}

/// Determines the file type from a file path based on extension
/// This is a pure function that only checks the file extension
PaneFileType getFileTypeFromPath(String filePath) {
  final lowerPath = filePath.toLowerCase();

  // Check by extension first (pure, no file system access)
  if (lowerPath.endsWith('.kvx') || lowerPath.endsWith(Editor.extension)) {
    return PaneFileType.handwritten;
  } else if (lowerPath.endsWith('.md')) {
    return PaneFileType.markdown;
  } else if (lowerPath.endsWith('.kvtx') ||
      lowerPath.endsWith(TextFileEditor.internalExtension)) {
    return PaneFileType.textDocument;
  }

  return PaneFileType.none;
}

/// Determines the file type by checking if actual files exist
/// This requires FileManager to be initialized
PaneFileType getFileTypeFromPathWithFileCheck(String filePath) {
  // Try pure extension-based check first
  final extensionType = getFileTypeFromPath(filePath);
  if (extensionType != PaneFileType.none) {
    return extensionType;
  }

  // If no extension, check for actual files
  try {
    if (FileManager.doesFileExist('$filePath${Editor.extension}')) {
      return PaneFileType.handwritten;
    } else if (FileManager.doesFileExist('$filePath.md')) {
      return PaneFileType.markdown;
    } else if (FileManager.doesFileExist(
      '$filePath${TextFileEditor.internalExtension}',
    )) {
      return PaneFileType.textDocument;
    }
  } catch (e) {
    // FileManager not initialized, fall back to none
  }

  return PaneFileType.none;
}

/// Direction of the split
enum SplitDirection {
  horizontal, // Side by side
  vertical, // Top and bottom
}

/// Manages the state of the split screen view
class SplitScreenController extends ChangeNotifier {
  SplitScreenController();

  /// Whether split screen mode is enabled
  var _isSplitEnabled = false;
  bool get isSplitEnabled => _isSplitEnabled;

  /// The direction of the split
  var _splitDirection = SplitDirection.horizontal;
  SplitDirection get splitDirection => _splitDirection;

  /// The ratio of the first pane (0.0 to 1.0)
  var _splitRatio = 0.5;
  double get splitRatio => _splitRatio;

  /// State of the left/top pane
  var _leftPane = const PaneState(isActive: true);
  PaneState get leftPane => _leftPane;

  /// State of the right/bottom pane
  var _rightPane = const PaneState();
  PaneState get rightPane => _rightPane;

  /// Minimum pane size ratio
  static const minPaneRatio = 0.2;
  static const maxPaneRatio = 0.8;

  /// Minimum width for split screen to be available
  static const minSplitWidth = 600.0;

  /// Enable split screen mode
  void enableSplit() {
    _isSplitEnabled = true;
    notifyListeners();
  }

  /// Disable split screen mode
  void disableSplit() {
    _isSplitEnabled = false;
    // Keep the active pane's content
    if (_rightPane.isActive && !_rightPane.isEmpty) {
      _leftPane = _rightPane.copyWith(isActive: true);
      _rightPane = const PaneState();
    } else {
      _leftPane = _leftPane.copyWith(isActive: true);
      _rightPane = const PaneState();
    }
    notifyListeners();
  }

  /// Toggle split screen mode
  void toggleSplit() {
    if (_isSplitEnabled) {
      disableSplit();
    } else {
      enableSplit();
    }
  }

  /// Set the split direction
  void setSplitDirection(SplitDirection direction) {
    if (_splitDirection != direction) {
      _splitDirection = direction;
      notifyListeners();
    }
  }

  /// Toggle split direction
  void toggleSplitDirection() {
    _splitDirection = _splitDirection == SplitDirection.horizontal
        ? SplitDirection.vertical
        : SplitDirection.horizontal;
    notifyListeners();
  }

  /// Update the split ratio
  void setSplitRatio(double ratio) {
    final clampedRatio = ratio.clamp(minPaneRatio, maxPaneRatio);
    if (_splitRatio != clampedRatio) {
      _splitRatio = clampedRatio;
      notifyListeners();
    }
  }

  /// Open a file in the specified pane (or the active pane if not specified)
  void openFile(String filePath, {bool? inRightPane}) {
    // Use file check version since file browser returns paths without extensions
    final fileType = getFileTypeFromPathWithFileCheck(filePath);
    final paneState = PaneState(
      filePath: filePath,
      fileType: fileType,
      isActive: true,
    );

    final targetRightPane = inRightPane ?? _rightPane.isActive;

    if (targetRightPane && _isSplitEnabled) {
      _rightPane = paneState;
      _leftPane = _leftPane.copyWith(isActive: false);
    } else {
      _leftPane = paneState;
      _rightPane = _rightPane.copyWith(isActive: false);
    }
    notifyListeners();
  }

  /// Open a file in the inactive pane (for split view)
  void openFileInOtherPane(String filePath) {
    if (!_isSplitEnabled) {
      enableSplit();
    }

    // Use file check version since file browser returns paths without extensions
    final fileType = getFileTypeFromPathWithFileCheck(filePath);
    final paneState = PaneState(
      filePath: filePath,
      fileType: fileType,
      isActive: true,
    );

    if (_leftPane.isActive) {
      _rightPane = paneState;
      _leftPane = _leftPane.copyWith(isActive: false);
    } else {
      _leftPane = paneState;
      _rightPane = _rightPane.copyWith(isActive: false);
    }
    notifyListeners();
  }

  /// Set the active pane
  void setActivePane({required bool isRightPane}) {
    if (isRightPane) {
      _rightPane = _rightPane.copyWith(isActive: true);
      _leftPane = _leftPane.copyWith(isActive: false);
    } else {
      _leftPane = _leftPane.copyWith(isActive: true);
      _rightPane = _rightPane.copyWith(isActive: false);
    }
    notifyListeners();
  }

  /// Close a pane (clears its content but keeps split mode enabled)
  void closePane({required bool isRightPane, bool keepSplitEnabled = false}) {
    if (isRightPane) {
      _rightPane = const PaneState();
      _leftPane = _leftPane.copyWith(isActive: true);
    } else {
      if (!_rightPane.isEmpty) {
        _leftPane = _rightPane.copyWith(isActive: true);
        _rightPane = const PaneState();
      } else {
        _leftPane = const PaneState(isActive: true);
      }
    }

    // If one pane is empty and keepSplitEnabled is false, disable split
    if (!keepSplitEnabled && (_leftPane.isEmpty || _rightPane.isEmpty)) {
      _isSplitEnabled = false;
    }
    notifyListeners();
  }

  /// Swap the contents of the two panes
  void swapPanes() {
    final temp = _leftPane;
    _leftPane = _rightPane;
    _rightPane = temp;
    notifyListeners();
  }

  /// Reset the split ratio to 50/50
  void resetSplitRatio() {
    _splitRatio = 0.5;
    notifyListeners();
  }

  /// Clear all panes
  void clear() {
    _leftPane = const PaneState(isActive: true);
    _rightPane = const PaneState();
    _isSplitEnabled = false;
    notifyListeners();
  }
}
