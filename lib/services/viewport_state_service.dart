import 'package:flutter/animation.dart';

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
    final viewportState = settings.firstWhere(
      (s) => s['key'] == 'viewportState_$documentId_$page',
      orElse: () => null,
    );

    if (viewportState != null) {
      final state = ViewportState.fromJson(viewportState['value']);
      _viewportStates.putIfAbsent(documentId, () => {})[page] = state;
      return state;
    }

    return null;
  }

  /// Saves the viewport state for a given document and page.
  Future<void> saveViewportState(String documentId, int page, ViewportState state) async {
    _viewportStates.putIfAbsent(documentId, () => {})[page] = state;

    await _repository.updateUserSetting(
      'global',
      'viewportState_$documentId_$page',
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

