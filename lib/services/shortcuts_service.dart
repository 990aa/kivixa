import 'dart:convert';
import 'package:flutter/services.dart';

/// Enum of all possible actions that can be mapped to a shortcut.
enum ShortcutAction {
  undo,
  redo,
  nextLayer,
  previousLayer,
  toggleLayerVisibility,
  cycleToolForward,
  cycleToolBackward,
  recallFavorite1,
  recallFavorite2,
  recallFavorite3,
}

/// Represents a keyboard shortcut combination.
class AppShortcut {
  final LogicalKeyboardKey trigger;
  final bool ctrl;
  final bool alt;
  final bool shift;

  AppShortcut(this.trigger, {this.ctrl = false, this.alt = false, this.shift = false});

  /// Creates a unique key for use in a Map.
  String get mapKey => '${trigger.keyId}:${ctrl ? 1:0}:${alt ? 1:0}:${shift ? 1:0}';

  Map<String, dynamic> toJson() => {
    'trigger': trigger.keyId,
    'ctrl': ctrl,
    'alt': alt,
    'shift': shift,
  };

  factory AppShortcut.fromJson(Map<String, dynamic> json) {
    return AppShortcut(
      LogicalKeyboardKey(json['trigger']),
      ctrl: json['ctrl'] ?? false,
      alt: json['alt'] ?? false,
      shift: json['shift'] ?? false,
    );
  }
}

/// Manages keyboard shortcuts for desktop and tablet.
class ShortcutsService {
  Map<String, ShortcutAction> _shortcuts = {};

  ShortcutsService() {
    _loadDefaultShortcuts();
  }

  /// The current map of shortcuts.
  Map<String, ShortcutAction> get shortcuts => Map.unmodifiable(_shortcuts);

  void _loadDefaultShortcuts() {
    _shortcuts = {
      AppShortcut(LogicalKeyboardKey.keyZ, ctrl: true).mapKey: ShortcutAction.undo,
      AppShortcut(LogicalKeyboardKey.keyY, ctrl: true).mapKey: ShortcutAction.redo,
      AppShortcut(LogicalKeyboardKey.pageUp, ctrl: true).mapKey: ShortcutAction.nextLayer,
      AppShortcut(LogicalKeyboardKey.pageDown, ctrl: true).mapKey: ShortcutAction.previousLayer,
      AppShortcut(LogicalKeyboardKey.keyT, ctrl: true).mapKey: ShortcutAction.cycleToolForward,
    };
  }

  /// Updates a shortcut for a given action.
  void setShortcut(ShortcutAction action, AppShortcut shortcut) {
    // Remove any existing shortcut for this action
    _shortcuts.removeWhere((key, value) => value == action);
    _shortcuts[shortcut.mapKey] = action;
    // In a real app, this would be persisted.
  }

  /// Exports the current shortcuts to a JSON string.
  String exportShortcutsAsJson() {
    final data = _shortcuts.entries.map((entry) {
      // This is a bit complex because the key is a stringified AppShortcut
      final shortcutParts = entry.key.split(':');
      final triggerId = int.parse(shortcutParts[0]);
      final ctrl = shortcutParts[1] == '1';
      final alt = shortcutParts[2] == '1';
      final shift = shortcutParts[3] == '1';

      return {
        'action': entry.value.name,
        'shortcut': AppShortcut(LogicalKeyboardKey(triggerId), ctrl: ctrl, alt: alt, shift: shift).toJson(),
      };
    }).toList();

    return jsonEncode(data);
  }

  /// Imports shortcuts from a JSON string, overwriting existing shortcuts.
  void importShortcutsFromJson(String jsonString) {
    final List<dynamic> data = jsonDecode(jsonString);
    final newShortcuts = <String, ShortcutAction>{};

    for (final item in data) {
      final action = ShortcutAction.values.firstWhere((e) => e.name == item['action']);
      final shortcut = AppShortcut.fromJson(item['shortcut']);
      newShortcuts[shortcut.mapKey] = action;
    }

    _shortcuts = newShortcuts;
    // In a real app, this would be persisted.
  }

  /// Returns the action associated with a given key event, or null if none.
  ///
  /// This would be called by the UI layer when a key event is received.
  /// No global hooks are used by this service itself.
  ShortcutAction? getActionForEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return null;

    final shortcut = AppShortcut(
      event.logicalKey,
      ctrl: event.isControlPressed,
      alt: event.isAltPressed,
      shift: event.isShiftPressed,
    );

    return _shortcuts[shortcut.mapKey];
  }
}