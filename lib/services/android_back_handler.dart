// Android Back Button Handler
//
// Implements double-tap-to-exit behavior for Android.
// Single back press shows a toast and navigates back.
// Double back press within 2 seconds exits the app.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to handle Android back button behavior
///
/// On Android:
/// - First back press: shows a snackbar and navigates back if possible
/// - Second back press within 2 seconds: exits the app
///
/// On other platforms: default behavior
class AndroidBackHandler {
  static final _instance = AndroidBackHandler._internal();
  factory AndroidBackHandler() => _instance;
  AndroidBackHandler._internal();

  DateTime? _lastBackPressTime;
  static const _exitTimeout = Duration(seconds: 2);

  /// Handle back button press
  /// Returns true if the app should exit, false otherwise
  bool handleBackPress(BuildContext context) {
    if (!Platform.isAndroid) {
      return true; // Let system handle on non-Android
    }

    final now = DateTime.now();
    final navigator = Navigator.of(context, rootNavigator: true);

    // Check if we can pop (go back)
    if (navigator.canPop()) {
      navigator.pop();
      return false;
    }

    // Can't go back - check for double tap to exit
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > _exitTimeout) {
      _lastBackPressTime = now;
      _showExitSnackbar(context);
      return false;
    }

    // Double tap detected - exit app
    _lastBackPressTime = null;
    return true;
  }

  void _showExitSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Press back again to exit'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Reset the back press timer (call when navigating to a new page)
  void reset() {
    _lastBackPressTime = null;
  }

  /// Check if double-tap exit should trigger (for testing purposes)
  /// Returns true if the second press is within the timeout window
  @visibleForTesting
  bool shouldExitApp() {
    final now = DateTime.now();

    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > _exitTimeout) {
      _lastBackPressTime = now;
      return false;
    }

    // Double tap detected
    _lastBackPressTime = null;
    return true;
  }
}

/// Widget that wraps content with Android double-tap-to-exit behavior
class AndroidBackButtonHandler extends StatelessWidget {
  const AndroidBackButtonHandler({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return child;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final handler = AndroidBackHandler();
        final shouldExit = handler.handleBackPress(context);

        if (shouldExit) {
          // Exit the app
          SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
