import 'package:flutter/material.dart';

class EmptyStateAnimated extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateAnimated({
    super.key,
    required this.message,
    this.icon = Icons.inbox,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.blueAccent),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
