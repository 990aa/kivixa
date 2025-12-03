// Floating Hub Widget Tests
//
// Tests for the floating hub overlay widget.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/overlay/floating_hub.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Enable test mode to skip SharedPreferences calls
  setUpAll(() {
    OverlayController.testMode = true;
  });

  tearDownAll(() {
    OverlayController.testMode = false;
  });

  group('FloatingHubOverlay', () {
    late OverlayController controller;

    setUp(() {
      controller = OverlayController.instance;
      // Reset state manually without triggering SharedPreferences
      controller.updateHubPosition(const Offset(0.95, 0.5));
      if (controller.hubMenuExpanded) controller.collapseHubMenu();
      if (controller.assistantOpen) controller.closeAssistant();
      if (controller.browserOpen) controller.closeBrowser();
    });

    Widget createTestWidget({Widget? child}) {
      return MaterialApp(
        home: Scaffold(
          body: FloatingHubOverlay(
            child: child ?? const Center(child: Text('Test Content')),
          ),
        ),
      );
    }

    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const Text('Hello World')),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders floating hub icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The hub icon should be visible (apps_rounded or close_rounded)
      expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
    });

    testWidgets('tap on hub toggles menu', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially menu should be collapsed
      expect(controller.hubMenuExpanded, false);

      // Find and tap the hub
      final hubFinder = find.byIcon(Icons.apps_rounded);
      expect(hubFinder, findsOneWidget);
      await tester.tap(hubFinder);
      await tester.pumpAndSettle();

      // Menu should be expanded
      expect(controller.hubMenuExpanded, true);

      // Icon should change to close
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('expanded menu shows tool buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand menu
      controller.toggleHubMenu();
      await tester.pumpAndSettle();

      // Should show AI, Browser, and Knowledge Graph icons
      expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.language_rounded), findsOneWidget);
      expect(find.byIcon(Icons.hub_rounded), findsOneWidget);
    });

    testWidgets('tapping AI button opens assistant', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand menu
      controller.toggleHubMenu();
      await tester.pumpAndSettle();

      // Initially assistant should be closed
      expect(controller.assistantOpen, false);

      // Find and tap AI button
      final aiFinder = find.byIcon(Icons.smart_toy_rounded);
      expect(aiFinder, findsOneWidget);
      await tester.tap(aiFinder);
      await tester.pumpAndSettle();

      // Assistant should be open
      expect(controller.assistantOpen, true);
    });

    testWidgets('tapping browser button opens browser', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand menu
      controller.toggleHubMenu();
      await tester.pumpAndSettle();

      // Initially browser should be closed
      expect(controller.browserOpen, false);

      // Find and tap browser button
      final browserFinder = find.byIcon(Icons.language_rounded);
      expect(browserFinder, findsOneWidget);
      await tester.tap(browserFinder);
      await tester.pumpAndSettle();

      // Browser should be open
      expect(controller.browserOpen, true);
    });

    testWidgets('tap catcher closes menu when expanded', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand menu
      controller.toggleHubMenu();
      await tester.pumpAndSettle();
      expect(controller.hubMenuExpanded, true);

      // Tap outside the hub (on the content area)
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();

      // Menu should be collapsed
      expect(controller.hubMenuExpanded, false);
    });
  });

  group('HoverAnimationBuilder', () {
    testWidgets('builds with animation', (tester) async {
      late AnimationController animController;

      await tester.pumpWidget(
        MaterialApp(
          home: _AnimationTestWidget(
            onControllerCreated: (c) => animController = c,
          ),
        ),
      );

      // Initially opacity should be 0
      var opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.0);

      // Animate forward
      animController.forward();
      await tester.pumpAndSettle();

      // Opacity should be 1
      opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });
  });
}

class _AnimationTestWidget extends StatefulWidget {
  const _AnimationTestWidget({required this.onControllerCreated});

  final ValueChanged<AnimationController> onControllerCreated;

  @override
  State<_AnimationTestWidget> createState() => _AnimationTestWidgetState();
}

class _AnimationTestWidgetState extends State<_AnimationTestWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    widget.onControllerCreated(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HoverAnimationBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(opacity: _controller.value, child: const Text('Test'));
      },
    );
  }
}
