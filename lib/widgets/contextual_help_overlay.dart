import 'package:flutter/material.dart';

class ContextualHelpOverlay extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ContextualHelpOverlay({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onDismiss ?? () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black.withAlpha(102),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Center(
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 400),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26), // Changed from withOpacity(0.1)
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                    child: const Text('Got it!'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
