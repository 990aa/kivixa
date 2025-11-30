import 'package:flutter/material.dart';
import 'package:kivixa/components/split_screen/split_screen_state.dart';

/// A service that provides the split screen controller to the widget tree
class SplitScreenService extends InheritedNotifier<SplitScreenController> {
  const SplitScreenService({
    super.key,
    required SplitScreenController controller,
    required super.child,
  }) : super(notifier: controller);

  static SplitScreenController of(BuildContext context) {
    final service = context.dependOnInheritedWidgetOfExactType<SplitScreenService>();
    if (service == null) {
      throw FlutterError(
        'SplitScreenService.of() called with a context that does not contain a SplitScreenService.\n'
        'No SplitScreenService ancestor could be found starting from the context that was passed to SplitScreenService.of().\n'
        'The context used was: $context',
      );
    }
    return service.notifier!;
  }

  static SplitScreenController? maybeOf(BuildContext context) {
    final service = context.dependOnInheritedWidgetOfExactType<SplitScreenService>();
    return service?.notifier;
  }
}

/// A widget that provides a split screen controller to its descendants
class SplitScreenProvider extends StatefulWidget {
  const SplitScreenProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SplitScreenProvider> createState() => _SplitScreenProviderState();
}

class _SplitScreenProviderState extends State<SplitScreenProvider> {
  late final SplitScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SplitScreenController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SplitScreenService(
      controller: _controller,
      child: widget.child,
    );
  }
}
