// App Lifecycle Manager
//
// Manages app-wide lifecycle events, idle detection, and memory optimization.
// Helps prevent RAM bloat during long-running sessions on Windows and Android.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

/// Callback type for section state changes
typedef SectionStateCallback = void Function(bool isActive);

/// Manages app lifecycle, idle detection, and section-based resource management.
///
/// Features:
/// - Detects app foreground/background state via WidgetsBindingObserver
/// - Tracks user activity and triggers idle callbacks after inactivity
/// - Allows sections to register for pause/resume notifications
/// - Platform-specific optimizations for Windows and Android
class AppLifecycleManager with WidgetsBindingObserver {
  AppLifecycleManager._();

  static final _instance = AppLifecycleManager._();
  static AppLifecycleManager get instance => _instance;

  var _initialized = false;

  // App lifecycle state
  AppLifecycleState _appState = AppLifecycleState.resumed;
  AppLifecycleState get appState => _appState;
  bool get isAppActive =>
      _appState == AppLifecycleState.resumed ||
      _appState == AppLifecycleState.inactive;
  bool get isAppInBackground =>
      _appState == AppLifecycleState.paused ||
      _appState == AppLifecycleState.detached;

  // Idle detection
  Timer? _idleTimer;
  var _isIdle = false;
  bool get isIdle => _isIdle;

  /// Duration of inactivity before triggering idle mode
  var idleTimeout = const Duration(minutes: 5);

  // Section management
  final _activeSections = <String>{};
  final _sectionCallbacks = <String, SectionStateCallback>{};

  // Event streams for app-wide state changes
  final _appStateController = StreamController<AppLifecycleState>.broadcast();
  final _idleStateController = StreamController<bool>.broadcast();

  /// Stream of app lifecycle state changes
  Stream<AppLifecycleState> get appStateStream => _appStateController.stream;

  /// Stream of idle state changes (true = idle, false = active)
  Stream<bool> get idleStateStream => _idleStateController.stream;

  // Listeners for global pause/resume
  final _pauseListeners = <VoidCallback>[];
  final _resumeListeners = <VoidCallback>[];

  /// Initialize the lifecycle manager
  void initialize() {
    if (_initialized) return;

    WidgetsBinding.instance.addObserver(this);
    _resetIdleTimer();
    _initialized = true;

    debugPrint('AppLifecycleManager initialized');
  }

  /// Dispose the lifecycle manager
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    _appStateController.close();
    _idleStateController.close();
    _initialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previousState = _appState;
    _appState = state;
    _appStateController.add(state);

    debugPrint('App lifecycle changed: $previousState -> $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        _onAppResumed();
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call overlay)
        break;
      case AppLifecycleState.paused:
        // App went to background
        _onAppPaused();
      case AppLifecycleState.detached:
        // App is detached (being terminated)
        _onAppPaused();
      case AppLifecycleState.hidden:
        // App is hidden but not paused
        break;
    }
  }

  void _onAppResumed() {
    _resetIdleTimer();

    // Notify all pause listeners to resume
    for (final callback in _resumeListeners) {
      callback();
    }

    // Resume all active sections
    for (final section in _activeSections) {
      _sectionCallbacks[section]?.call(true);
    }
  }

  void _onAppPaused() {
    _idleTimer?.cancel();

    // Notify all pause listeners
    for (final callback in _pauseListeners) {
      callback();
    }

    // Pause all sections
    for (final section in _activeSections) {
      _sectionCallbacks[section]?.call(false);
    }

    // Trigger garbage collection hint on Android
    if (Platform.isAndroid) {
      _triggerGarbageCollectionHint();
    }
  }

  /// Register a callback for when the app is paused (goes to background)
  void addPauseListener(VoidCallback callback) {
    _pauseListeners.add(callback);
  }

  /// Remove a pause listener
  void removePauseListener(VoidCallback callback) {
    _pauseListeners.remove(callback);
  }

  /// Register a callback for when the app is resumed (comes to foreground)
  void addResumeListener(VoidCallback callback) {
    _resumeListeners.add(callback);
  }

  /// Remove a resume listener
  void removeResumeListener(VoidCallback callback) {
    _resumeListeners.remove(callback);
  }

  // ==================== Idle Detection ====================

  /// Call this whenever user interacts with the app
  void onUserActivity() {
    if (_isIdle) {
      _isIdle = false;
      _idleStateController.add(false);
      debugPrint('User activity detected - exiting idle mode');

      // Resume sections when coming out of idle
      for (final section in _activeSections) {
        _sectionCallbacks[section]?.call(true);
      }
    }
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, _onIdleTimeout);
  }

  void _onIdleTimeout() {
    if (!isAppActive) return; // Don't trigger if app is already paused

    _isIdle = true;
    _idleStateController.add(true);
    debugPrint('Idle timeout - entering idle mode');

    // Pause all sections during idle
    for (final section in _activeSections) {
      _sectionCallbacks[section]?.call(false);
    }

    // Trigger memory cleanup
    _triggerGarbageCollectionHint();
  }

  // ==================== Section Management ====================

  /// Register a section with a callback for state changes
  ///
  /// The callback will be called with `true` when the section should be active
  /// and `false` when it should pause (idle mode, app background, etc.)
  void registerSection(String sectionId, SectionStateCallback callback) {
    _sectionCallbacks[sectionId] = callback;
  }

  /// Unregister a section
  void unregisterSection(String sectionId) {
    _sectionCallbacks.remove(sectionId);
    _activeSections.remove(sectionId);
  }

  /// Mark a section as active (user is viewing it)
  void activateSection(String sectionId) {
    _activeSections.add(sectionId);
    onUserActivity();

    // Notify the section it's now active (if not idle/paused)
    if (isAppActive && !_isIdle) {
      _sectionCallbacks[sectionId]?.call(true);
    }
  }

  /// Mark a section as inactive (user navigated away)
  void deactivateSection(String sectionId) {
    _activeSections.remove(sectionId);

    // Notify the section to pause and dispose resources
    _sectionCallbacks[sectionId]?.call(false);
  }

  /// Check if a section is currently active
  bool isSectionActive(String sectionId) {
    return _activeSections.contains(sectionId) && isAppActive && !_isIdle;
  }

  // ==================== Memory Management ====================

  /// Hint to the runtime that it's a good time for garbage collection
  void _triggerGarbageCollectionHint() {
    // Flutter doesn't expose direct GC control, but we can help by:
    // 1. Clearing image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    debugPrint('Triggered memory cleanup hint');
  }

  /// Manually trigger memory cleanup (call sparingly)
  void triggerMemoryCleanup() {
    _triggerGarbageCollectionHint();
  }
}

/// Mixin for StatefulWidgets that need lifecycle-aware behavior
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with LifecycleAwareMixin {
///   @override
///   String get sectionId => 'my_widget';
///
///   @override
///   void onSectionActivated() {
///     // Initialize resources, start timers
///   }
///
///   @override
///   void onSectionDeactivated() {
///     // Dispose resources, stop timers
///   }
/// }
/// ```
mixin LifecycleAwareMixin<T extends StatefulWidget> on State<T> {
  /// Unique identifier for this section
  String get sectionId;

  /// Called when the section becomes active
  void onSectionActivated() {}

  /// Called when the section should pause (idle, background, navigated away)
  void onSectionDeactivated() {}

  var _isCurrentlyActive = false;

  @override
  void initState() {
    super.initState();
    AppLifecycleManager.instance.registerSection(sectionId, _onStateChange);
    AppLifecycleManager.instance.activateSection(sectionId);
  }

  @override
  void dispose() {
    AppLifecycleManager.instance.deactivateSection(sectionId);
    AppLifecycleManager.instance.unregisterSection(sectionId);
    super.dispose();
  }

  void _onStateChange(bool isActive) {
    if (isActive == _isCurrentlyActive) return;
    _isCurrentlyActive = isActive;

    if (isActive) {
      onSectionActivated();
    } else {
      onSectionDeactivated();
    }
  }

  /// Call this when user interacts with the widget
  void notifyUserActivity() {
    AppLifecycleManager.instance.onUserActivity();
  }
}

/// Widget that wraps content and reports user activity
class ActivityDetector extends StatelessWidget {
  const ActivityDetector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => AppLifecycleManager.instance.onUserActivity(),
      onPointerMove: (_) => AppLifecycleManager.instance.onUserActivity(),
      onPointerSignal: (_) => AppLifecycleManager.instance.onUserActivity(),
      child: child,
    );
  }
}
