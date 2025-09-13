
import 'dart:async';

import 'settings_service.dart';

// Defines the orientation of the split layout.
enum SplitOrientation { horizontal, vertical }

// Represents the state of the split layout.
class SplitLayoutState {
  final SplitOrientation orientation;
  final double dividerPosition;
  final int? leftDocumentId;
  final int? rightDocumentId;

  SplitLayoutState({
    this.orientation = SplitOrientation.horizontal,
    this.dividerPosition = 0.5,
    this.leftDocumentId,
    this.rightDocumentId,
  });

  SplitLayoutState.fromJson(Map<String, dynamic> json)
      : orientation = SplitOrientation.values[json['orientation'] ?? 0],
        dividerPosition = json['dividerPosition'] ?? 0.5,
        leftDocumentId = json['leftDocumentId'],
        rightDocumentId = json['rightDocumentId'];

  Map<String, dynamic> toJson() => {
        'orientation': orientation.index,
        'dividerPosition': dividerPosition,
        'leftDocumentId': leftDocumentId,
        'rightDocumentId': rightDocumentId,
      };
}

// Manages the state of the split view layout.
class SplitLayoutService {
  final SettingsService _settings;
  static const _key = 'split_layout_state';

  SplitLayoutService(this._settings);

  // Retrieves the last saved split layout state.
  Future<SplitLayoutState> get() async {
    final json = await _settings.get<Map<String, dynamic>>(_key);
    if (json != null) {
      return SplitLayoutState.fromJson(json);
    }
    return SplitLayoutState();
  }

  // Persists the split layout state.
  Future<void> set(SplitLayoutState state) async {
    _settings.set(_key, state.toJson());
  }
}
