import 'package:flutter/material.dart';
import 'package:kivixa/components/overlay/assistant_window.dart';
import 'package:kivixa/components/overlay/browser_window.dart';
import 'package:kivixa/components/overlay/floating_calculator.dart';
import 'package:kivixa/components/overlay/floating_clock.dart';
import 'package:kivixa/components/overlay/floating_hub.dart';
import 'package:kivixa/components/quick_notes/floating_quick_notes.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';
import 'package:kivixa/services/quick_notes/quick_notes_service.dart';

/// The main global overlay widget that provides floating tools.
///
/// This widget wraps the app content and provides:
/// - A floating hub icon for quick access to tools
/// - A floating AI assistant window
/// - A floating browser window
/// - Support for additional tool windows
///
/// Usage:
/// ```dart
/// GlobalOverlay(
///   child: MyApp(),
/// )
/// ```
class GlobalOverlay extends StatefulWidget {
  const GlobalOverlay({super.key, required this.child});

  /// The main app content.
  final Widget child;

  @override
  State<GlobalOverlay> createState() => _GlobalOverlayState();
}

class _GlobalOverlayState extends State<GlobalOverlay> {
  var _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    stows.floatingHubEnabled.addListener(_onSettingsChanged);
    stows.floatingHubSize.addListener(_onSettingsChanged);
    stows.floatingHubTransparency.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    stows.floatingHubEnabled.removeListener(_onSettingsChanged);
    stows.floatingHubSize.removeListener(_onSettingsChanged);
    stows.floatingHubTransparency.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initialize() async {
    await OverlayController.instance.initialize();
    await QuickNotesService.instance.initialize();
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show content without overlay until initialized
    if (!_initialized) {
      return widget.child;
    }

    // If floating hub is disabled, don't show the overlay
    if (!stows.floatingHubEnabled.value) {
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          const AssistantWindow(),
          const BrowserWindow(),
          const _ClockWindowWrapper(),
          const _QuickNotesWindowWrapper(),
          const _CalculatorWindowWrapper(),
        ],
      );
    }

    // Apply size and transparency settings to the controller
    final controller = OverlayController.instance;
    final sizeValue = stows.floatingHubSize.value;
    final transparencyValue = stows.floatingHubTransparency.value;

    // Map size preference to scale (0.75, 1.0, 1.25)
    final scale = switch (sizeValue) {
      0 => 0.75,
      1 => 1.0,
      _ => 1.25,
    };

    // Map transparency preference to opacity (0.4, 0.7, 1.0)
    final opacity = switch (transparencyValue) {
      0 => 0.4,
      1 => 0.7,
      _ => 1.0,
    };

    // Update controller if values changed
    if (controller.hubScale != scale) {
      controller.setHubScale(scale);
    }
    if (controller.hubOpacity != opacity) {
      controller.setHubOpacity(opacity);
    }

    return FloatingHubOverlay(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main app content
          widget.child,

          // Floating windows
          const AssistantWindow(),
          const BrowserWindow(),
          const _ClockWindowWrapper(),
          const _QuickNotesWindowWrapper(),
          const _CalculatorWindowWrapper(),
        ],
      ),
    );
  }
}

/// Wrapper for the clock window that handles visibility
class _ClockWindowWrapper extends StatefulWidget {
  const _ClockWindowWrapper();

  @override
  State<_ClockWindowWrapper> createState() => _ClockWindowWrapperState();
}

class _ClockWindowWrapperState extends State<_ClockWindowWrapper> {
  @override
  void initState() {
    super.initState();
    OverlayController.instance.addListener(_onOverlayChanged);
  }

  void _onOverlayChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    OverlayController.instance.removeListener(_onOverlayChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = OverlayController.instance;

    if (!controller.isToolWindowOpen('clock')) {
      return const SizedBox.shrink();
    }

    return const FloatingClockWindow();
  }
}

/// A wrapper for the global overlay that provides access to the controller.
///
/// Use this to access the overlay controller from anywhere in the widget tree.
class GlobalOverlayScope extends InheritedWidget {
  const GlobalOverlayScope({super.key, required super.child});

  static OverlayController of(BuildContext context) {
    return OverlayController.instance;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

/// Wrapper for the quick notes window that handles visibility and positioning
class _QuickNotesWindowWrapper extends StatefulWidget {
  const _QuickNotesWindowWrapper();

  @override
  State<_QuickNotesWindowWrapper> createState() =>
      _QuickNotesWindowWrapperState();
}

class _QuickNotesWindowWrapperState extends State<_QuickNotesWindowWrapper> {
  var _position = const Offset(100, 100);

  @override
  void initState() {
    super.initState();
    OverlayController.instance.addListener(_onOverlayChanged);
  }

  void _onOverlayChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    OverlayController.instance.removeListener(_onOverlayChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = OverlayController.instance;

    if (!controller.isToolWindowOpen('quick_notes')) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        child: FloatingQuickNotes(
          onClose: () => controller.closeToolWindow('quick_notes'),
        ),
      ),
    );
  }
}

/// Wrapper for the calculator window that handles visibility
class _CalculatorWindowWrapper extends StatefulWidget {
  const _CalculatorWindowWrapper();

  @override
  State<_CalculatorWindowWrapper> createState() =>
      _CalculatorWindowWrapperState();
}

class _CalculatorWindowWrapperState extends State<_CalculatorWindowWrapper> {
  @override
  void initState() {
    super.initState();
    OverlayController.instance.addListener(_onOverlayChanged);
  }

  void _onOverlayChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    OverlayController.instance.removeListener(_onOverlayChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = OverlayController.instance;

    if (!controller.isToolWindowOpen('calculator')) {
      return const SizedBox.shrink();
    }

    return const FloatingCalculatorWindow();
  }
}
