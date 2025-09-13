import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

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
          child: _buildContent(context),
        );
    }

    return ElevatedButton(
      style: style,
      onPressed: _handlePressed,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onPrimary = colorScheme.onPrimary;

    if (widget.isLoading) {
      return Shimmer.fromColors(
        baseColor: onPrimary.withOpacity(0.5),
        highlightColor: onPrimary.withOpacity(0.9),
        child: widget.child,
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
