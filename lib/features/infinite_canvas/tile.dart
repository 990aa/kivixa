import 'package:flutter/material.dart';

class Tile extends StatefulWidget {
  const Tile({
    super.key,
    required this.size,
    required this.x,
    required this.y,
  });

  final double size;
  final int x;
  final int y;

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.x * widget.size,
      top: widget.y * widget.size,
      width: widget.size,
      height: widget.size,
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Center(
            child: Text('${widget.x}, ${widget.y}'),
          ),
        ),
      ),
    );
  }
}
