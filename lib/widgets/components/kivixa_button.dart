import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum KivixaButtonType {
  primary,
  secondary,
  outlined,
  text,
  floating,
}

class KivixaButton extends StatefulWidget {
  const KivixaButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.buttonType = KivixaButtonType.primary,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final KivixaButtonType buttonType;
  final bool isLoading;

  @override
  State<KivixaButton> createState() => _KivixaButtonState();
}

class _KivixaButtonState extends State<KivixaButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ButtonStyle style;
    Widget content = widget.child;

    switch (widget.buttonType) {
      case KivixaButtonType.primary:
        style = ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
        ).copyWith(
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) return 8.0;
              return 2.0;
            },
          ),
        );
        break;
      case KivixaButtonType.secondary:
        style = ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          elevation: 2,
        ).copyWith(
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) return 8.0;
              return 2.0;
            },
          ),
        );
        break;
      case KivixaButtonType.outlined:
        style = OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
        );
        break;
      case KivixaButtonType.text:
        style = TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
        );
        break;
      case KivixaButtonType.floating:
        return FloatingActionButton(
          onPressed: _handlePressed,
          elevation: 6,
          highlightElevation: 12,
          child: _buildContent(),
        );
    }

    return ElevatedButton(
      style: style,
      onPressed: _handlePressed,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white, // This should be themed
        ),
      );
    }
    return widget.child;
  }

  void _handlePressed() {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }
}
