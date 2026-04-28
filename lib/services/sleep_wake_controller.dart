// Sleep/Wake Controller
//
// Aggressively puts inactive components to sleep, disposing their heavy
// resources (timers, streams, decoders, animation controllers), while
// serialising lightweight state so they can resume instantly on wake.
//
// Exclusion zone: NEVER apply to Handwriting Canvas or its sub-widgets.
// The canvas keeps strokes in memory to avoid any re-render lag.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_lifecycle_manager.dart';

// ────────────────────────────────────────────────────────────────────────────
// Serialisable snapshot of component state
// ────────────────────────────────────────────────────────────────────────────

/// Lightweight key→value map that a component saves before sleeping and
/// restores after waking.  All values must be JSON-compatible primitives.
typedef SleepState = Map<String, Object?>;

// ────────────────────────────────────────────────────────────────────────────
// SleepWakeController
// ────────────────────────────────────────────────────────────────────────────

/// Controls the sleep/wake lifecycle of a single UI component.
///
/// Usage (inside a [State]):
/// ```dart
/// late final SleepWakeController _swc;
///
/// @override
/// void initState() {
///   super.initState();
///   _swc = SleepWakeController(
///     componentId: 'knowledge_graph',
///     onSleep: _onSleep,
///     onWake: _onWake,
///   )..attach();
/// }
///
/// @override
/// void dispose() {
///   _swc.detach();
///   super.dispose();
/// }
/// ```
class SleepWakeController {
  SleepWakeController({
    required this.componentId,
    required this.onSleep,
    required this.onWake,
    this.idleGracePeriod = const Duration(seconds: 30),
  });

  /// Stable, human-readable identifier for this component (used for logging).
  final String componentId;

  /// Called when the component must release heavy resources.
  /// Return a [SleepState] snapshot; it will be passed back in [onWake].
  final Future<SleepState> Function() onSleep;

  /// Called when the component should rebuild from the saved [SleepState].
  /// Must complete before the next frame to avoid visible stutter.
  final Future<void> Function(SleepState state) onWake;

  /// Extra idle time granted to this specific component before sleeping,
  /// on top of the global [AppLifecycleManager.idleTimeout].
  final Duration idleGracePeriod;

  bool _asleep = false;
  bool get isAsleep => _asleep;

  SleepState _savedState = {};
  Timer? _graceTimer;

  void attach() {
    AppLifecycleManager.instance.registerSection(componentId, _onLifecycle);
    AppLifecycleManager.instance.activateSection(componentId);
  }

  void detach() {
    _graceTimer?.cancel();
    AppLifecycleManager.instance.deactivateSection(componentId);
    AppLifecycleManager.instance.unregisterSection(componentId);
  }

  // Called by AppLifecycleManager when app/idle state changes.
  void _onLifecycle(bool isActive) {
    if (isActive) {
      _cancelGrace();
      if (_asleep) _wake();
    } else {
      // Start a grace timer — don't sleep immediately, give the component
      // a chance to stay alive across brief interruptions (e.g. notification
      // shade pulled down for 2 s).
      _graceTimer?.cancel();
      _graceTimer = Timer(idleGracePeriod, _sleep);
    }
  }

  Future<void> _sleep() async {
    if (_asleep) return;
    try {
      _savedState = await onSleep();
      _asleep = true;
      debugPrint('💤 [$componentId] slept — saved ${_savedState.length} keys');
    } catch (e) {
      debugPrint('⚠️  [$componentId] sleep error: $e');
    }
  }

  Future<void> _wake() async {
    if (!_asleep) return;
    _asleep = false;
    try {
      await onWake(_savedState);
      debugPrint('☀️  [$componentId] woke — restored ${_savedState.length} keys');
    } catch (e) {
      debugPrint('⚠️  [$componentId] wake error: $e');
    }
  }

  void _cancelGrace() {
    _graceTimer?.cancel();
    _graceTimer = null;
  }

  /// Notify the manager that the user is interacting with this component
  /// (resets the global idle timer).
  void notifyActivity() => AppLifecycleManager.instance.onUserActivity();
}

// ────────────────────────────────────────────────────────────────────────────
// SleepAwareWidget  — convenience StatefulWidget base
// ────────────────────────────────────────────────────────────────────────────

/// Mixin for [State] subclasses that want automatic sleep/wake management.
///
/// ⚠️  DO NOT use on any Handwriting Canvas widget or sub-widget.
///
/// Implementing classes must provide:
/// - [sleepComponentId]  — unique component name
/// - [captureState]      — snapshot to [SleepState] before sleeping
/// - [restoreState]      — rebuild from [SleepState] on wake
///
/// Optionally override [sleepGracePeriod] to customise the per-component delay.
mixin SleepAwareMixin<T extends StatefulWidget> on State<T> {
  late final SleepWakeController _swc;

  String get sleepComponentId;
  Duration get sleepGracePeriod => const Duration(seconds: 30);

  /// Snapshot component state before sleeping.
  /// Keep this fast — it runs on the UI thread just before resources are freed.
  Future<SleepState> captureState();

  /// Restore component from snapshot.
  /// Must complete synchronously enough to avoid jank on wake.
  Future<void> restoreState(SleepState state);

  /// Called right before the component is put to sleep.
  /// Override to cancel timers, close streams, free textures, etc.
  Future<void> onSleep(SleepState state) async {}

  /// Called right after the component wakes.
  /// Override to restart timers, re-subscribe to streams, etc.
  Future<void> onWake(SleepState state) async {}

  @override
  void initState() {
    super.initState();
    _swc = SleepWakeController(
      componentId: sleepComponentId,
      idleGracePeriod: sleepGracePeriod,
      onSleep: () async {
        final state = await captureState();
        await onSleep(state);
        return state;
      },
      onWake: (state) async {
        await restoreState(state);
        await onWake(state);
        if (mounted) setState(() {});
      },
    )..attach();
  }

  @override
  void dispose() {
    _swc.detach();
    super.dispose();
  }

  bool get isAsleep => _swc.isAsleep;

  void notifyUserActivity() => _swc.notifyActivity();
}
