import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Shows a premium dialog with a backdrop blur effect and a spring animation.
///
/// The dialog can be dismissed with a gesture.
Future<T?> showPremiumDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10 * animation.value, sigmaY: 10 * animation.value),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.1, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const SpringCurve(),
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );
    },
  );
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
