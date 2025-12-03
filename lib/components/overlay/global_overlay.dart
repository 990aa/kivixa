import 'package:flutter/material.dart';
import 'package:kivixa/components/overlay/assistant_window.dart';
import 'package:kivixa/components/overlay/browser_window.dart';
import 'package:kivixa/components/overlay/floating_hub.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

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
  }

  Future<void> _initialize() async {
    await OverlayController.instance.initialize();
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

    return FloatingHubOverlay(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main app content
          widget.child,

          // Floating windows
          const AssistantWindow(),
          const BrowserWindow(),
        ],
      ),
    );
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
