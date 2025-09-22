import 'package:flutter/material.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double distance;
  final double blur;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.color = const Color(0xFFF0F0F0),
    this.distance = 4.0,
    this.blur = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withAlpha((255 * 0.7).round()),
            offset: Offset(-distance, -distance),
            blurRadius: blur,
          ),
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.15).round()),
            offset: Offset(distance, distance),
            blurRadius: blur,
          ),
        ],
      ),
      child: child,
    );
  }
}
