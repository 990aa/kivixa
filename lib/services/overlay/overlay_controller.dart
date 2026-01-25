import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a tool that can be shown in the hub menu.
class OverlayTool {
  const OverlayTool({
    required this.id,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive,
  });

  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool Function()? isActive;

  bool get active => isActive?.call() ?? false;
}

/// Controller for the global overlay system.
///
/// Manages floating hub position, tool windows, and their persistence across sessions.
/// Uses ChangeNotifier pattern for reactive UI updates.
class OverlayController extends ChangeNotifier {
  OverlayController._();

  static final _instance = OverlayController._();

  /// Singleton instance of the overlay controller.
  static OverlayController get instance => _instance;

  // ============================================================
  // Configuration
  // ============================================================

  /// Debounce duration for persistence writes (200-500ms recommended).
  static const _debounceDuration = Duration(milliseconds: 300);

  /// Whether to auto-reopen windows on app launch.
  var _autoReopenWindows = true;

  // ============================================================
  // State fields
  // ============================================================

  /// Position of the floating hub icon (normalized 0-1 for responsive positioning).
  var _hubPosition = const Offset(0.95, 0.5);

  /// Scale factor of the hub icon (0.5 - 1.5).
  var _hubScale = 1.0;

  /// Opacity of the hub icon when idle (0.3 - 1.0).
  var _hubOpacity = 0.7;

  /// Whether the hub menu is expanded to show tools.
  var _hubMenuExpanded = false;

  /// Whether the AI assistant window is open.
  var _assistantOpen = false;

  /// Rectangle defining the AI assistant window position and size.
  var _assistantWindowRect = const Rect.fromLTWH(100, 100, 400, 500);

  /// Whether the browser window is open.
  var _browserOpen = false;

  /// Rectangle defining the browser window position and size.
  var _browserWindowRect = const Rect.fromLTWH(200, 100, 600, 500);

  /// Map of custom tool window states.
  final Map<String, _ToolWindowState> _toolWindows = {};

  /// Registered overlay tools for the hub menu.
  final List<OverlayTool> _registeredTools = [];

  /// Whether the overlay system is initialized.
  var _initialized = false;

  /// Debounce timer for persistence.
  Timer? _saveTimer;

  // ============================================================
  // Getters
  // ============================================================

  Offset get hubPosition => _hubPosition;
  double get hubScale => _hubScale;
  double get hubOpacity => _hubOpacity;
  bool get hubMenuExpanded => _hubMenuExpanded;
  bool get assistantOpen => _assistantOpen;
  Rect get assistantWindowRect => _assistantWindowRect;
  bool get browserOpen => _browserOpen;
  Rect get browserWindowRect => _browserWindowRect;
  bool get initialized => _initialized;
  bool get autoReopenWindows => _autoReopenWindows;
  List<OverlayTool> get registeredTools => List.unmodifiable(_registeredTools);

  // ============================================================
  // Initialization
  // ============================================================

  /// Initialize the overlay controller and load persisted state.
  Future<void> initialize() async {
    if (_initialized) return;
    await loadState();
    _initialized = true;
  }

  /// Set whether windows should auto-reopen on app launch.
  void setAutoReopenWindows(bool value) {
    _autoReopenWindows = value;
    _scheduleSave();
  }

  // ============================================================
  // Tool Registration
  // ============================================================

  /// Register a tool to be shown in the hub menu.
  void registerTool(OverlayTool tool) {
    // Remove existing tool with same id
    _registeredTools.removeWhere((t) => t.id == tool.id);
    _registeredTools.add(tool);
    notifyListeners();
  }

  /// Unregister a tool from the hub menu.
  void unregisterTool(String toolId) {
    _registeredTools.removeWhere((t) => t.id == toolId);
    notifyListeners();
  }

  /// Get all registered tools.
  List<OverlayTool> getTools() => List.unmodifiable(_registeredTools);

  /// Register the default built-in tools.
  void registerDefaultTools() {
    registerTool(
      OverlayTool(
        id: 'assistant',
        icon: Icons.smart_toy_rounded,
        label: 'AI Assistant',
        onTap: toggleAssistant,
        isActive: () => assistantOpen,
      ),
    );
    registerTool(
      OverlayTool(
        id: 'browser',
        icon: Icons.language_rounded,
        label: 'Browser',
        onTap: toggleBrowser,
        isActive: () => browserOpen,
      ),
    );
    registerTool(
      OverlayTool(
        id: 'clock',
        icon: Icons.timer_rounded,
        label: 'Productivity Timer',
        onTap: () => isToolWindowOpen('clock')
            ? closeToolWindow('clock')
            : openToolWindow('clock'),
        isActive: () => isToolWindowOpen('clock'),
      ),
    );
    registerTool(
      OverlayTool(
        id: 'quick_notes',
        icon: Icons.sticky_note_2_rounded,
        label: 'Quick Notes',
        onTap: () => isToolWindowOpen('quick_notes')
            ? closeToolWindow('quick_notes')
            : openToolWindow('quick_notes'),
        isActive: () => isToolWindowOpen('quick_notes'),
      ),
    );
    registerTool(
      OverlayTool(
        id: 'calculator',
        icon: Icons.calculate_rounded,
        label: 'Calculator',
        onTap: () => isToolWindowOpen('calculator')
            ? closeToolWindow('calculator')
            : openToolWindow('calculator'),
        isActive: () => isToolWindowOpen('calculator'),
      ),
    );
  }

  // ============================================================
  // Hub controls
  // ============================================================

  /// Update the hub position (normalized coordinates 0-1).
  void updateHubPosition(Offset position) {
    _hubPosition = Offset(
      position.dx.clamp(0.0, 1.0),
      position.dy.clamp(0.0, 1.0),
    );
    notifyListeners();
    _scheduleSave();
  }

  /// Set the hub scale factor.
  void setHubScale(double scale) {
    _hubScale = scale.clamp(0.5, 1.5);
    notifyListeners();
    _scheduleSave();
  }

  /// Set the hub idle opacity.
  void setHubOpacity(double opacity) {
    _hubOpacity = opacity.clamp(0.3, 1.0);
    notifyListeners();
    _scheduleSave();
  }

  /// Toggle the hub menu expansion.
  void toggleHubMenu() {
    _hubMenuExpanded = !_hubMenuExpanded;
    notifyListeners();
    // Don't persist menu state - always start collapsed
  }

  /// Collapse the hub menu.
  void collapseHubMenu() {
    if (_hubMenuExpanded) {
      _hubMenuExpanded = false;
      notifyListeners();
    }
  }

  // ============================================================
  // AI Assistant window controls
  // ============================================================

  /// Open the AI assistant window.
  void openAssistant() {
    _assistantOpen = true;
    collapseHubMenu();
    notifyListeners();
    _scheduleSave();
  }

  /// Close the AI assistant window.
  void closeAssistant() {
    _assistantOpen = false;
    notifyListeners();
    _scheduleSave();
  }

  /// Toggle the AI assistant window.
  void toggleAssistant() {
    if (_assistantOpen) {
      closeAssistant();
    } else {
      openAssistant();
    }
  }

  /// Update the AI assistant window rectangle.
  void updateAssistantRect(Rect rect) {
    _assistantWindowRect = rect;
    notifyListeners();
    _scheduleSave();
  }

  /// Move the AI assistant window.
  void moveAssistant(Offset delta) {
    _assistantWindowRect = _assistantWindowRect.translate(delta.dx, delta.dy);
    notifyListeners();
    _scheduleSave();
  }

  /// Resize the AI assistant window.
  void resizeAssistant(Rect newRect) {
    // Ensure minimum size
    final width = newRect.width.clamp(300.0, double.infinity);
    final height = newRect.height.clamp(400.0, double.infinity);
    _assistantWindowRect = Rect.fromLTWH(
      newRect.left,
      newRect.top,
      width,
      height,
    );
    notifyListeners();
    _scheduleSave();
  }

  // ============================================================
  // Browser window controls
  // ============================================================

  /// Open the browser window.
  void openBrowser() {
    _browserOpen = true;
    collapseHubMenu();
    notifyListeners();
    _scheduleSave();
  }

  /// Close the browser window.
  void closeBrowser() {
    _browserOpen = false;
    notifyListeners();
    _scheduleSave();
  }

  /// Toggle the browser window.
  void toggleBrowser() {
    if (_browserOpen) {
      closeBrowser();
    } else {
      openBrowser();
    }
  }

  /// Update the browser window rectangle.
  void updateBrowserRect(Rect rect) {
    _browserWindowRect = rect;
    notifyListeners();
    _scheduleSave();
  }

  // ============================================================
  // Generic tool window controls
  // ============================================================

  /// Check if a tool window is open.
  bool isToolWindowOpen(String toolId) {
    return _toolWindows[toolId]?.isOpen ?? false;
  }

  /// Get a tool window's rectangle.
  Rect? getToolWindowRect(String toolId) {
    return _toolWindows[toolId]?.rect;
  }

  /// Open or create a tool window.
  void openToolWindow(String toolId, {Rect? initialRect}) {
    _toolWindows[toolId] = _ToolWindowState(
      isOpen: true,
      rect:
          initialRect ??
          _toolWindows[toolId]?.rect ??
          const Rect.fromLTWH(150, 150, 400, 400),
    );
    collapseHubMenu();
    notifyListeners();
    _scheduleSave();
  }

  /// Close a tool window.
  void closeToolWindow(String toolId) {
    final state = _toolWindows[toolId];
    if (state != null) {
      _toolWindows[toolId] = _ToolWindowState(isOpen: false, rect: state.rect);
      notifyListeners();
      _scheduleSave();
    }
  }

  /// Update a tool window's rectangle.
  void updateToolWindowRect(String toolId, Rect rect) {
    final state = _toolWindows[toolId];
    if (state != null) {
      _toolWindows[toolId] = _ToolWindowState(isOpen: state.isOpen, rect: rect);
      notifyListeners();
      _scheduleSave();
    }
  }

  // ============================================================
  // Bounds clamping
  // ============================================================

  /// Clamp a window rectangle to stay within screen bounds.
  Rect clampToScreen(Rect rect, Size screenSize) {
    const margin = 50.0; // Minimum visible area

    double left = rect.left;
    double top = rect.top;
    final double right = rect.right;
    final double bottom = rect.bottom;

    // Ensure window is at least partially visible
    if (left > screenSize.width - margin) {
      left = screenSize.width - margin;
    }
    if (top > screenSize.height - margin) {
      top = screenSize.height - margin;
    }
    if (right < margin) {
      left = margin - rect.width;
    }
    if (bottom < margin) {
      top = margin - rect.height;
    }

    // Prevent going above/left of screen
    if (left < 0) left = 0;
    if (top < 0) top = 0;

    return Rect.fromLTWH(left, top, rect.width, rect.height);
  }

  // ============================================================
  // Persistence
  // ============================================================

  static const _prefsKey = 'overlay_state';

  /// Set to true in tests to disable SharedPreferences calls
  static var testMode = false;

  /// Schedule a debounced save operation.
  /// Uses a timer to avoid excessive writes when dragging.
  void _scheduleSave() {
    if (testMode) return;

    // Cancel existing timer
    _saveTimer?.cancel();

    // Schedule new save
    _saveTimer = Timer(_debounceDuration, () {
      saveState();
    });
  }

  /// Force an immediate save, cancelling any pending debounced save.
  Future<void> forceSave() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    await saveState();
  }

  /// Save state to shared preferences.
  Future<void> saveState() async {
    if (testMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'hubPosition': {'dx': _hubPosition.dx, 'dy': _hubPosition.dy},
        'hubScale': _hubScale,
        'hubOpacity': _hubOpacity,
        'autoReopenWindows': _autoReopenWindows,
        'assistantOpen': _assistantOpen,
        'assistantWindowRect': _rectToJson(_assistantWindowRect),
        'browserOpen': _browserOpen,
        'browserWindowRect': _rectToJson(_browserWindowRect),
        'toolWindows': _toolWindows.map(
          (key, value) => MapEntry(key, {
            'isOpen': value.isOpen,
            'rect': _rectToJson(value.rect),
          }),
        ),
      };
      await prefs.setString(_prefsKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to save overlay state: $e');
    }
  }

  /// Load state from shared preferences.
  Future<void> loadState() async {
    if (testMode) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString == null) {
      // No saved state, register default tools
      registerDefaultTools();
      return;
    }

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Load hub position
      if (data['hubPosition'] is Map) {
        final pos = data['hubPosition'] as Map<String, dynamic>;
        _hubPosition = Offset(
          (pos['dx'] as num?)?.toDouble() ?? 0.95,
          (pos['dy'] as num?)?.toDouble() ?? 0.5,
        );
      }

      // Load hub settings
      _hubScale = (data['hubScale'] as num?)?.toDouble() ?? 1.0;
      _hubOpacity = (data['hubOpacity'] as num?)?.toDouble() ?? 0.7;
      _autoReopenWindows = data['autoReopenWindows'] as bool? ?? true;

      // Load window rects (always restore position/size)
      if (data['assistantWindowRect'] is Map) {
        _assistantWindowRect = _rectFromJson(
          data['assistantWindowRect'] as Map<String, dynamic>,
        );
      }

      if (data['browserWindowRect'] is Map) {
        _browserWindowRect = _rectFromJson(
          data['browserWindowRect'] as Map<String, dynamic>,
        );
      }

      // Conditionally restore open states based on autoReopenWindows
      if (_autoReopenWindows) {
        _assistantOpen = data['assistantOpen'] as bool? ?? false;
        _browserOpen = data['browserOpen'] as bool? ?? false;
      }

      // Load tool windows
      if (data['toolWindows'] is Map) {
        final windows = data['toolWindows'] as Map<String, dynamic>;
        _toolWindows.clear();
        windows.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _toolWindows[key] = _ToolWindowState(
              isOpen: _autoReopenWindows
                  ? (value['isOpen'] as bool? ?? false)
                  : false,
              rect: value['rect'] is Map
                  ? _rectFromJson(value['rect'] as Map<String, dynamic>)
                  : const Rect.fromLTWH(150, 150, 400, 400),
            );
          }
        });
      }

      // Register default tools
      registerDefaultTools();

      notifyListeners();
    } catch (e) {
      // Ignore corrupted state, register default tools
      debugPrint('Failed to load overlay state: $e');
      registerDefaultTools();
    }
  }

  Map<String, dynamic> _rectToJson(Rect rect) {
    return {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }

  Rect _rectFromJson(Map<String, dynamic> json) {
    return Rect.fromLTWH(
      (json['left'] as num?)?.toDouble() ?? 0,
      (json['top'] as num?)?.toDouble() ?? 0,
      (json['width'] as num?)?.toDouble() ?? 400,
      (json['height'] as num?)?.toDouble() ?? 400,
    );
  }

  /// Reset all overlay state to defaults.
  void reset() {
    _saveTimer?.cancel();
    _hubPosition = const Offset(0.95, 0.5);
    _hubScale = 1.0;
    _hubOpacity = 0.7;
    _hubMenuExpanded = false;
    _assistantOpen = false;
    _assistantWindowRect = const Rect.fromLTWH(100, 100, 400, 500);
    _browserOpen = false;
    _browserWindowRect = const Rect.fromLTWH(200, 100, 600, 500);
    _toolWindows.clear();
    _autoReopenWindows = true;
    notifyListeners();
    _scheduleSave();
  }

  /// Cancel any pending save operations.
  void cancelPendingSave() {
    _saveTimer?.cancel();
    _saveTimer = null;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

/// Internal state for a tool window.
class _ToolWindowState {
  const _ToolWindowState({required this.isOpen, required this.rect});

  final bool isOpen;
  final Rect rect;
}
