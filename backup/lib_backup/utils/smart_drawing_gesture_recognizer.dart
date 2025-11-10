import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Callback for drawing start
typedef DrawStartCallback = void Function(Offset point);

/// Callback for drawing update
typedef DrawUpdateCallback = void Function(Offset point, double pressure);

/// Callback for drawing end
typedef DrawEndCallback = void Function();

/// Smart gesture recognizer that only accepts drawing gestures
/// Rejects multi-touch and navigation gestures
class SmartDrawingGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Callback when drawing starts
  final DrawStartCallback? onDrawStart;

  /// Callback when drawing updates
  final DrawUpdateCallback? onDrawUpdate;

  /// Callback when drawing ends
  final DrawEndCallback? onDrawEnd;

  /// Function to check if gesture should be accepted
  final bool Function()? shouldAcceptGesture;

  /// Minimum movement to start drawing (prevents accidental taps)
  final double dragStartBehavior;

  /// Current pointer ID
  int? _pointer;

  /// Initial pointer position
  Offset? _initialPosition;

  /// Has drawing started
  var _hasStarted = false;

  SmartDrawingGestureRecognizer({
    this.onDrawStart,
    this.onDrawUpdate,
    this.onDrawEnd,
    this.shouldAcceptGesture,
    this.dragStartBehavior = 2.0,
    super.debugOwner,
    super.supportedDevices,
  });

  @override
  void addAllowedPointer(PointerDownEvent event) {
    // Check if we should accept this gesture
    if (shouldAcceptGesture != null && !shouldAcceptGesture!()) {
      return;
    }

    // Only accept if we don't have an active pointer
    if (_pointer != null) {
      return;
    }

    // Store pointer and initial position
    _pointer = event.pointer;
    _initialPosition = event.localPosition;
    _hasStarted = false;

    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;

    if (event is PointerMoveEvent) {
      if (!_hasStarted && _initialPosition != null) {
        // Check if moved enough to start drawing
        final distance = (event.localPosition - _initialPosition!).distance;
        if (distance >= dragStartBehavior) {
          _hasStarted = true;
          onDrawStart?.call(_initialPosition!);
        }
      }

      if (_hasStarted) {
        onDrawUpdate?.call(event.localPosition, event.pressure);
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_hasStarted) {
        onDrawEnd?.call();
      }
      // Stop tracking before resetting to avoid null pointer
      if (_pointer != null) {
        stopTrackingPointer(_pointer!);
      }
      _reset();
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _reset();
  }

  void _reset() {
    _pointer = null;
    _initialPosition = null;
    _hasStarted = false;
  }

  @override
  String get debugDescription => 'smart_drawing';

  @override
  void dispose() {
    _reset();
    super.dispose();
  }
}

/// Factory for creating SmartDrawingGestureRecognizer
class SmartDrawingGestureRecognizerFactory
    extends GestureRecognizerFactory<SmartDrawingGestureRecognizer> {
  final DrawStartCallback? onDrawStart;
  final DrawUpdateCallback? onDrawUpdate;
  final DrawEndCallback? onDrawEnd;
  final bool Function()? shouldAcceptGesture;
  final Set<PointerDeviceKind>? supportedDevices;

  const SmartDrawingGestureRecognizerFactory({
    this.onDrawStart,
    this.onDrawUpdate,
    this.onDrawEnd,
    this.shouldAcceptGesture,
    this.supportedDevices,
  });

  @override
  SmartDrawingGestureRecognizer constructor() {
    return SmartDrawingGestureRecognizer(
      onDrawStart: onDrawStart,
      onDrawUpdate: onDrawUpdate,
      onDrawEnd: onDrawEnd,
      shouldAcceptGesture: shouldAcceptGesture,
      supportedDevices: supportedDevices,
    );
  }

  @override
  void initializer(SmartDrawingGestureRecognizer instance) {
    // No additional initialization needed
  }
}
