import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphismToolbar extends StatefulWidget {
  const GlassmorphismToolbar({super.key});

  @override
  State<GlassmorphismToolbar> createState() => _GlassmorphismToolbarState();
}

class _GlassmorphismToolbarState extends State<GlassmorphismToolbar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isExpanded ? 200 : 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: _isExpanded
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(icon: const Icon(Icons.color_lens), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.brush), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                      ],
                    )
                  : const Icon(Icons.palette),
            ),
          ),
        ),
      ),
    );
  }
}
