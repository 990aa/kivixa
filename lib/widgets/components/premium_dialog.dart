import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Shows a premium dialog with a backdrop blur effect and a spring animation.
///
/// The dialog can be dismissed with a gesture.
Future<T?> showPremiumDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Size? dialogSize,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.tight(dialogSize ?? const Size(300, 400)),
          child: builder(context),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10 * animation.value, sigmaY: 10 * animation.value),
        child: PremiumDialogWrapper(
          animation: animation,
          child: child,
        ),
      );
    },
  );
}

class PremiumDialogWrapper extends StatefulWidget {
  const PremiumDialogWrapper({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  State<PremiumDialogWrapper> createState() => _PremiumDialogWrapperState();
}

class _PremiumDialogWrapperState extends State<PremiumDialogWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final progress = details.primaryDelta! / context.size!.height;
        _controller.value += progress;
      },
      onVerticalDragEnd: (details) {
        if (_controller.value > 0.5) {
          _controller.forward().then((_) => Navigator.of(context).pop());
        } else {
          _controller.reverse();
        }
      },
      child: SlideTransition(
        position: _offsetAnimation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.1, end: 1.0).animate(
            CurvedAnimation(
              parent: widget.animation,
              curve: const SpringCurve(),
            ),
          ),
          child: FadeTransition(
            opacity: widget.animation,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A custom curve that uses a spring simulation.
class SpringCurve extends Curve {
  const SpringCurve({
    this.damping = 20,
    this.stiffness = 180,
    this.mass = 1.0,
    this.velocity = 0.0,
  });

  final double damping;
  final double stiffness;
  final double mass;
  final double velocity;

  @override
  double transformInternal(double t) {
    final simulation = SpringSimulation(
      SpringDescription(
        damping: damping,
        stiffness: stiffness,
        mass: mass,
      ),
      1, // end
      0, // start
      velocity,
    );
    return simulation.x(t) * -1 + 1;
  }
}
