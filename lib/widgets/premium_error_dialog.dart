import 'package:flutter/material.dart';

class PremiumErrorDialog extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const PremiumErrorDialog({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Something went wrong'),
      content: Text(error),
      actions: [
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
