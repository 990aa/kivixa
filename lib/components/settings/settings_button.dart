import 'package:flutter/material.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;
    final disabledColor = theme.disabledColor;

    return InkWell(
      onTap: onPressed,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: Icon(
            icon,
            key: ValueKey(icon),
            color: isEnabled ? null : disabledColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            color: isEnabled ? null : disabledColor,
          ),
        ),
        subtitle: Text(
          subtitle ?? '',
          style: TextStyle(
            fontSize: 13,
            color: isEnabled ? null : disabledColor,
          ),
        ),
      ),
    );
  }
}
