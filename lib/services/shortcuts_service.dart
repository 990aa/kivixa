import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Enum of all possible actions that can be mapped to a shortcut.
enum ShortcutAction {
  undo,
  redo,
  nextLayer,
  previousLayer,
  toggleLayerVisibility,
  cycleTool,
  recallFavorite1,
  recallFavorite2,
  recallFavorite3,
}

class ShortcutMapping {
  final ShortcutAction action;
  final Set<LogicalKeyboardKey> keys;

  ShortcutMapping({required this.action, required this.keys});

  Map<String, dynamic> toJson() => {
        'action': action.name,
        'keys': keys.map((k) => k.keyId).toList(),
      };

  factory ShortcutMapping.fromJson(Map<String, dynamic> json) {
    return ShortcutMapping(
      action: ShortcutAction.values.firstWhere((e) => e.name == json['action']),
      keys: (json['keys'] as List).map((id) => LogicalKeyboardKey(id)).toSet(),
    );
  }
}

class ShortcutsService {
  static final ShortcutsService _instance = ShortcutsService._internal();
  factory ShortcutsService() => _instance;
  ShortcutsService._internal();

  Map<ShortcutAction, ShortcutMapping> _shortcuts = {};
  bool _isInitialized = false;
  late final File _shortcutsFile;

  Map<ShortcutAction, ShortcutMapping> get shortcuts => _shortcuts;

  Future<void> initialize() async {
    if (_isInitialized) return;
    final appSupportDir = await getApplicationSupportDirectory();
    _shortcutsFile = File(p.join(appSupportDir.path, 'shortcuts.json'));
    await loadShortcuts();
    _isInitialized = true;
  }

  Future<void> loadShortcuts() async {
    if (await _shortcutsFile.exists()) {
      final content = await _shortcutsFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      _shortcuts = {
        for (var mapping in jsonList.map((json) => ShortcutMapping.fromJson(json)))
          mapping.action: mapping
      };
    } else {
      _loadDefaultShortcuts();
    }
  }

  void _loadDefaultShortcuts() {
    _shortcuts = {
      ShortcutAction.undo: ShortcutMapping(
        action: ShortcutAction.undo,
        keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ},
      ),
      ShortcutAction.redo: ShortcutMapping(
        action: ShortcutAction.redo,
        keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyY},
      ),
    };
  }

  Future<void> _persistShortcuts() async {
    final jsonList = _shortcuts.values.map((m) => m.toJson()).toList();
    await _shortcutsFile.writeAsString(jsonEncode(jsonList));
  }

  Future<void> updateShortcut(ShortcutAction action, Set<LogicalKeyboardKey> keys) async {
    _shortcuts[action] = ShortcutMapping(action: action, keys: keys);
    await _persistShortcuts();
  }

  Future<String> exportShortcutsAsJson() async {
    final jsonList = _shortcuts.values.map((m) => m.toJson()).toList();
    return jsonEncode(jsonList);
  }

  Future<void> importShortcutsFromJson(String jsonString) async {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    _shortcuts = {
      for (var mapping in jsonList.map((json) => ShortcutMapping.fromJson(json)))
        mapping.action: mapping
    };
    await _persistShortcuts();
  }
}
