import 'dart:async';
import 'dart:convert';

import '../data/repository.dart';

class SplitScreenState {
  final String layout;
  final int? pane1DocumentId;
  final int? pane2DocumentId;
  final bool isSwapped;
  final bool isEdgeClosed;

  SplitScreenState({
    this.layout = 'horizontal',
    this.pane1DocumentId,
    this.pane2DocumentId,
    this.isSwapped = false,
    this.isEdgeClosed = false,
  });

  SplitScreenState copyWith({
    String? layout,
    int? pane1DocumentId,
    int? pane2DocumentId,
    bool? isSwapped,
    bool? isEdgeClosed,
  }) {
    return SplitScreenState(
      layout: layout ?? this.layout,
      pane1DocumentId: pane1DocumentId ?? this.pane1DocumentId,
      pane2DocumentId: pane2DocumentId ?? this.pane2DocumentId,
      isSwapped: isSwapped ?? this.isSwapped,
      isEdgeClosed: isEdgeClosed ?? this.isEdgeClosed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'layout': layout,
      'pane1DocumentId': pane1DocumentId,
      'pane2DocumentId': pane2DocumentId,
      'isSwapped': isSwapped,
      'isEdgeClosed': isEdgeClosed,
    };
  }

  static SplitScreenState fromMap(Map<String, dynamic> map) {
    return SplitScreenState(
      layout: map['layout'],
      pane1DocumentId: map['pane1DocumentId'],
      pane2DocumentId: map['pane2DocumentId'],
      isSwapped: map['isSwapped'],
      isEdgeClosed: map['isEdgeClosed'],
    );
  }
}

class SplitScreenPersistence {
  final Repository _repo;
  final String _userId; // Assuming we have a user ID

  SplitScreenState _state = SplitScreenState();

  final _stateController = StreamController<SplitScreenState>.broadcast();
  Stream<SplitScreenState> get stateStream => _stateController.stream;

  SplitScreenPersistence(this._repo, this._userId);

  Future<void> loadState(int documentId) async {
    final settings = await _repo.listUserSettings(userId: _userId);
    final setting = settings.firstWhere((s) => s['key'] == 'split_screen_state_$documentId', orElse: () => {});
    if (setting.isNotEmpty) {
      _state = SplitScreenState.fromMap(jsonDecode(setting['value']));
      _stateController.add(_state);
    }
  }

  Future<void> _saveState(int documentId) async {
    await _repo.updateUserSetting(_userId, 'split_screen_state_$documentId', {'value': jsonEncode(_state.toMap())});
    _stateController.add(_state);
  }

  Future<void> setLayout(int documentId, String layout) async {
    _state = _state.copyWith(layout: layout);
    await _saveState(documentId);
  }

  Future<void> setPaneDocument(int documentId, int pane, int paneDocumentId) async {
    if (pane == 1) {
      _state = _state.copyWith(pane1DocumentId: paneDocumentId);
    } else {
      _state = _state.copyWith(pane2DocumentId: paneDocumentId);
    }
    await _saveState(documentId);
  }

  Future<void> toggleSwap(int documentId) async {
    _state = _state.copyWith(isSwapped: !_state.isSwapped);
    await _saveState(documentId);
  }

  Future<void> toggleEdgeClose(int documentId) async {
    _state = _state.copyWith(isEdgeClosed: !_state.isEdgeClosed);
    await _saveState(documentId);
  }

  void dispose() {
    _stateController.close();
  }
}