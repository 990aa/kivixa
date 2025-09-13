import 'package:flutter/material.dart';

class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  double _dividerPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            Row(
              children: [
                SizedBox(
                  width: width * _dividerPosition,
                  child: const Center(child: Text('Left Pane')),
                ),
                SizedBox(
                  width: width * (1 - _dividerPosition),
                  child: const Center(child: Text('Right Pane')),
                ),
              ],
            ),
            Positioned(
              left: width * _dividerPosition - 2,
              child: Draggable(
                axis: Axis.horizontal,
                feedback: Container(
                  width: 4,
                  height: constraints.maxHeight,
                  color: Colors.blue.withOpacity(0.5),
                ),
                childWhenDragging: Container(),
                onDragUpdate: (details) {
                  setState(() {
                    _dividerPosition = (details.globalPosition.dx / width).clamp(0.1, 0.9);
                  });
                },
                child: Container(
                  width: 4,
                  height: constraints.maxHeight,
                  color: Colors.blue,
                  cursor: SystemMouseCursors.resizeLeftRight,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
