import 'package:flutter/material.dart';

Future<T?> showCustomMenu<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<PopupMenuEntry<T>> items,
  double elevation = 8.0,
}) {
  return Navigator.of(context).push(_PopupMenuRoute<T>(
    position: position,
    items: items,
    elevation: elevation,
    theme: Theme.of(context),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  ));
}

class _PopupMenuRoute<T> extends PopupRoute<T> {
  _PopupMenuRoute({
    required this.position,
    required this.items,
    required this.elevation,
    required this.theme,
    required this.barrierLabel,
  });

  final RelativeRect position;
  final List<PopupMenuEntry<T>> items;
  final double elevation;
  final ThemeData theme;

  @override
  final String barrierLabel;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Builder(
      builder: (BuildContext context) {
        return CustomSingleChildLayout(
          delegate: _PopupMenuRouteLayout(position),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: elevation),
            duration: transitionDuration,
            builder: (context, value, child) {
              return Material(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: value,
                child: child,
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 120,
              ),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: items,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PopupMenuRouteLayout extends SingleChildLayoutDelegate {
  _PopupMenuRouteLayout(this.position);

  final RelativeRect position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double x = position.left;
    if (x + childSize.width > size.width) {
      x = size.width - childSize.width;
    }
    double y = position.top;
    if (y + childSize.height > size.height) {
      y = size.height - childSize.height;
    }
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopupMenuRouteLayout oldDelegate) {
    return position != oldDelegate.position;
  }
}
