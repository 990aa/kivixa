import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class FloatingToolbar extends StatefulWidget {
  const FloatingToolbar({super.key});

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late SpringSimulation _simulation;
  Offset _offset = const Offset(16, 100);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _simulation = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 100, damping: 10),
      0,
      1,
      0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runAnimation(Offset target) {
    _controller.animateWith(_simulation);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: Draggable(
        feedback: _buildToolbar(),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            final dx = details.offset.dx.clamp(0.0, size.width - 200);
            final dy = details.offset.dy.clamp(0.0, size.height - 50);
            _offset = Offset(dx, dy);
          });
        },
        child: _buildToolbar(),
      ),
    );
  }

  Widget _buildToolbar() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
            IconButton(icon: const Icon(Icons.brush), onPressed: () {}),
            IconButton(icon: const Icon(Icons.color_lens), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
