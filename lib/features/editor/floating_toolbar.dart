import 'package:flutter/material.dart';

class _Tool {
  const _Tool({required this.icon, required this.name});
  final IconData icon;
  final String name;
}

class FloatingToolbar extends StatefulWidget {
  const FloatingToolbar({super.key});

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _offset = const Offset(16, 100);
  int _selectedToolIndex = 0;

  final List<_Tool> _tools = const [
    _Tool(icon: Icons.edit, name: 'Pen'),
    _Tool(icon: Icons.brush, name: 'Brush'),
    _Tool(icon: Icons.color_lens, name: 'Color'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
      // _simulation was removed
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          children: List.generate(_tools.length, (index) {
            final tool = _tools[index];
            return IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  tool.icon,
                  key: ValueKey(tool.name),
                  color: _selectedToolIndex == index
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedToolIndex = index;
                });
              },
            );
          }),
        ),
      ),
    );
  }
}