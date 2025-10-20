import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/platform_input_config.dart';
import '../utils/smart_drawing_gesture_recognizer.dart';

/// Advanced gesture handler with precise control over gesture arena
/// Separates drawing (1 finger) from navigation (2+ fingers, trackpad)
class PreciseCanvasGestureHandler extends StatefulWidget {
  /// Canvas widget to display
  final Widget canvas;

  /// Drawing callbacks
  final void Function(Offset point)? onDrawStart;
  final void Function(Offset point, double pressure)? onDrawUpdate;
  final void Function()? onDrawEnd;

  /// Navigation callbacks
  final void Function(ScaleStartDetails details)? onNavigationStart;
  final void Function(ScaleUpdateDetails details)? onNavigationUpdate;
  final void Function(ScaleEndDetails details)? onNavigationEnd;

  /// Enable/disable drawing
  final bool drawingEnabled;

  /// Enable/disable navigation
  final bool navigationEnabled;

  const PreciseCanvasGestureHandler({
    super.key,
    required this.canvas,
    this.onDrawStart,
    this.onDrawUpdate,
    this.onDrawEnd,
    this.onNavigationStart,
    this.onNavigationUpdate,
    this.onNavigationEnd,
    this.drawingEnabled = true,
    this.navigationEnabled = true,
  });

  @override
  State<PreciseCanvasGestureHandler> createState() =>
      _PreciseCanvasGestureHandlerState();
}

class _PreciseCanvasGestureHandlerState
    extends State<PreciseCanvasGestureHandler> {
  /// Active pointers
  final Set<int> _pointers = {};

  /// Is currently in navigation mode
  bool _isNavigating = false;

  /// Is currently drawing
  bool _isDrawing = false;

  /// Platform configuration
  late GestureConfiguration _gestureConfig;

  @override
  void initState() {
    super.initState();
    _gestureConfig = PlatformInputConfig.getGestureConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: _buildGestureRecognizers(),
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,

        // Trackpad support for Windows/macOS
        onPointerPanZoomStart: _onTrackpadStart,
        onPointerPanZoomUpdate: _onTrackpadUpdate,
        onPointerPanZoomEnd: _onTrackpadEnd,

        child: widget.canvas,
      ),
    );
  }

  /// Build gesture recognizers based on platform
  Map<Type, GestureRecognizerFactory> _buildGestureRecognizers() {
    final recognizers = <Type, GestureRecognizerFactory>{};

    // Drawing gesture (single pointer, not navigating)
    if (widget.drawingEnabled) {
      recognizers[SmartDrawingGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<SmartDrawingGestureRecognizer>(
            () => SmartDrawingGestureRecognizer(
              onDrawStart: _onDrawStartInternal,
              onDrawUpdate: _onDrawUpdateInternal,
              onDrawEnd: _onDrawEndInternal,
              shouldAcceptGesture: _shouldAcceptDrawing,
              supportedDevices: PlatformInputConfig.getDrawingDevices(),
            ),
            (recognizer) {},
          );
    }

    // Scale/Pan gesture (multi-touch or trackpad)
    if (widget.navigationEnabled) {
      recognizers[ScaleGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
            () => ScaleGestureRecognizer(
              supportedDevices: PlatformInputConfig.getNavigationDevices(),
            ),
            (recognizer) {
              recognizer
                ..onStart = _onScaleStart
                ..onUpdate = _onScaleUpdate
                ..onEnd = _onScaleEnd;
            },
          );
    }

    return recognizers;
  }

  /// Check if drawing gesture should be accepted
  bool _shouldAcceptDrawing() {
    // Don't accept drawing during navigation
    if (_isNavigating) return false;

    // Platform-specific checks
    if (_gestureConfig.useSingleFingerDrawing) {
      // Mobile: Only 1 pointer allowed for drawing
      return _pointers.length == 1 && widget.drawingEnabled;
    } else {
      // Desktop: Allow drawing unless explicitly navigating
      return !_isNavigating && widget.drawingEnabled;
    }
  }

  /// Pointer tracking
  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _pointers.add(event.pointer);

      // If 2+ pointers on mobile, switch to navigation
      if (_gestureConfig.useSingleFingerDrawing &&
          _pointers.length >= _gestureConfig.minNavigationPointers) {
        _isNavigating = true;
        if (_isDrawing) {
          // Cancel current drawing
          _onDrawEndInternal();
        }
      }
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _pointers.remove(event.pointer);

      // If back to single pointer, allow drawing again
      if (_pointers.length < _gestureConfig.minNavigationPointers) {
        _isNavigating = false;
      }
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _pointers.remove(event.pointer);
      if (_pointers.isEmpty) {
        _isNavigating = false;
        _isDrawing = false;
      }
    });
  }

  /// Trackpad gesture handling
  void _onTrackpadStart(PointerPanZoomStartEvent event) {
    if (!widget.navigationEnabled) return;

    setState(() {
      _isNavigating = true;
      if (_isDrawing) {
        _onDrawEndInternal();
      }
    });

    // Convert to scale gesture
    widget.onNavigationStart?.call(
      ScaleStartDetails(
        focalPoint: event.position,
        localFocalPoint: event.localPosition,
      ),
    );
  }

  void _onTrackpadUpdate(PointerPanZoomUpdateEvent event) {
    if (!widget.navigationEnabled || !_isNavigating) return;

    // Convert trackpad pan/zoom to scale gesture
    widget.onNavigationUpdate?.call(
      ScaleUpdateDetails(
        focalPoint: event.position,
        localFocalPoint: event.localPosition,
        scale: event.scale,
        horizontalScale: event.scale,
        verticalScale: event.scale,
        rotation: event.rotation,
        focalPointDelta: event.panDelta,
      ),
    );
  }

  void _onTrackpadEnd(PointerPanZoomEndEvent event) {
    if (!widget.navigationEnabled) return;

    setState(() {
      _isNavigating = false;
    });

    widget.onNavigationEnd?.call(ScaleEndDetails());
  }

  /// Drawing gesture callbacks
  void _onDrawStartInternal(Offset point) {
    if (!widget.drawingEnabled || _isNavigating) return;

    setState(() {
      _isDrawing = true;
    });

    widget.onDrawStart?.call(point);
  }

  void _onDrawUpdateInternal(Offset point, double pressure) {
    if (!widget.drawingEnabled || _isNavigating || !_isDrawing) return;

    widget.onDrawUpdate?.call(point, pressure);
  }

  void _onDrawEndInternal() {
    if (!_isDrawing) return;

    setState(() {
      _isDrawing = false;
    });

    widget.onDrawEnd?.call();
  }

  /// Scale gesture callbacks
  void _onScaleStart(ScaleStartDetails details) {
    if (!widget.navigationEnabled) return;

    // Only start navigation if criteria met
    final shouldNavigate = _gestureConfig.useSingleFingerDrawing
        ? _pointers.length >= _gestureConfig.minNavigationPointers
        : true;

    if (shouldNavigate) {
      setState(() {
        _isNavigating = true;
        if (_isDrawing) {
          _onDrawEndInternal();
        }
      });

      widget.onNavigationStart?.call(details);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.navigationEnabled || !_isNavigating) return;

    widget.onNavigationUpdate?.call(details);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (!widget.navigationEnabled) return;

    setState(() {
      _isNavigating = false;
    });

    widget.onNavigationEnd?.call(details);
  }
}
