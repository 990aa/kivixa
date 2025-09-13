import 'package:flutter/animation.dart';
import 'package:collection/collection.dart'; // Added import

import '../data/repository.dart';

class ViewportStateService {
  final Repository _repository;

  ViewportStateService(this._repository);

  /// Inertial animation policy for a balanced feel.
  static const balanced = 'balanced';

  /// Inertial animation policy for a more responsive feel.
  static const responsive = 'responsive';

  /// Stores the scroll/zoom values for each document and page.
  final Map<String, Map<int, ViewportState>> _viewportStates = {};

  /// Restores the viewport state for a given document and page.
  Future<ViewportState?> restoreViewportState(String documentId, int page) async {
    if (_viewportStates.containsKey(documentId) && _viewportStates[documentId]!.containsKey(page)) {
      return _viewportStates[documentId]![page];
    }

    final settings = await _repository.listUserSettings(userId: 'global');
    // Changed to use firstWhereOrNull and removed orElse
    final viewportState = settings.firstWhereOrNull(
      (s) => s['key'] == 'viewportState_${documentId}_$page',
    );

    if (viewportState != null) {
      // viewportState['value'] needs to be cast to Map<String, dynamic>
      // if it's not already guaranteed by the type from listUserSettings.
      // Assuming listUserSettings returns List<Map<String, dynamic>> where 'value' is Map<String, dynamic>.
      // If 'value' can be other types, a more robust check or cast is needed.
      final dynamic value = viewportState['value'];
      if (value is Map<String, dynamic>) {
        final state = ViewportState.fromJson(value);
        _viewportStates.putIfAbsent(documentId, () => {})[page] = state;
        return state;
      } else {
        // Handle cases where 'value' is not a Map<String, dynamic> or is null
        // This might involve logging an error or returning null
        print('ViewportStateService: viewportState["value"] is not a Map<String, dynamic> or is null. Value: $value');
        return null;
      }
    }

    return null;
  }

  /// Saves the viewport state for a given document and page.
  Future<void> saveViewportState(String documentId, int page, ViewportState state) async {
    _viewportStates.putIfAbsent(documentId, () => {})[page] = state;

    await _repository.updateUserSetting(
      'global',
      'viewportState_$documentId_$page', // Corrected the typo here
      {'value': state.toJson()},
    );
  }
}

class ViewportState {
  final double scroll;
  final double zoom;

  ViewportState(this.scroll, this.zoom);

  factory ViewportState.fromJson(Map<String, dynamic> json) {
    return ViewportState(json['scroll'], json['zoom']);
  }

  Map<String, dynamic> toJson() {
    return {
      'scroll': scroll,
      'zoom': zoom,
    };
  }
}

