import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class SquareDrawingPage extends StatefulWidget {
  final String noteName;
  final String? folderId;
  const SquareDrawingPage({super.key, required this.noteName, this.folderId});

  @override
  State<SquareDrawingPage> createState() => _SquareDrawingPageState();
}

class _SquareDrawingPageState extends State<SquareDrawingPage> {
  final List<List<Offset?>> _paths = [];
  List<Offset?>? _currentPath;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.noteName.isNotEmpty ? widget.noteName : 'Square Drawing',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _paths.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              setState(() {
                if (_paths.isNotEmpty) {
                  _paths.removeLast();
                }
              });
            },
          ),
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1.0,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            panEnabled: true,
            scaleEnabled: true,
            child: Container(
              color: Colors.white,
              child: Listener(
                onPointerDown: (PointerDownEvent event) {
                  if (event.kind == PointerDeviceKind.stylus ||
                      event.kind == PointerDeviceKind.mouse) {
                    setState(() {
                      _currentPath = [event.localPosition];
                      _paths.add(_currentPath!);
                    });
                  }
                },
                onPointerMove: (PointerMoveEvent event) {
                  if ((event.kind == PointerDeviceKind.stylus ||
                          event.kind == PointerDeviceKind.mouse) &&
                      _currentPath != null) {
                    setState(() {
                      _currentPath!.add(event.localPosition);
                    });
                  }
                },
                onPointerUp: (PointerUpEvent event) {
                  setState(() {
                    _currentPath = null;
                  });
                },
                child: CustomPaint(
                  painter: _SmoothDrawingPainter(_paths),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmoothDrawingPainter extends CustomPainter {
  final List<List<Offset?>> paths;
  _SmoothDrawingPainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final path in paths) {
      if (path.length < 2) continue;
      final smoothPath = Path();
      for (int i = 0; i < path.length; i++) {
        final point = path[i];
        if (point == null) continue;
        if (i == 0) {
          smoothPath.moveTo(point.dx, point.dy);
        } else {
          final prev = path[i - 1];
          if (prev != null) {
            final mid = Offset(
              (prev.dx + point.dx) / 2,
              (prev.dy + point.dy) / 2,
            );
            smoothPath.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
          }
        }
      }
      canvas.drawPath(smoothPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothDrawingPainter oldDelegate) {
    return oldDelegate.paths != paths;
  }
}
