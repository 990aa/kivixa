import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/split_screen/split_screen.dart';

void main() {
  group('ResizableDivider', () {
    testWidgets('renders horizontal split divider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 400,
              child: ResizableDivider(
                direction: SplitDirection.horizontal,
                onDrag: (delta) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ResizableDivider), findsOneWidget);
    });

    testWidgets('renders vertical split divider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 100,
              child: ResizableDivider(
                direction: SplitDirection.vertical,
                onDrag: (delta) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ResizableDivider), findsOneWidget);
    });

    testWidgets('calls onDrag when dragged horizontally', (tester) async {
      double dragDelta = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                height: 400,
                child: ResizableDivider(
                  direction: SplitDirection.horizontal,
                  onDrag: (delta) {
                    dragDelta = delta;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final gesture = find.byType(GestureDetector);
      expect(gesture, findsOneWidget);

      await tester.drag(gesture, const Offset(50, 0));
      await tester.pump();

      expect(dragDelta, isNonZero);
    });

    testWidgets('calls onDrag when dragged vertically', (tester) async {
      double dragDelta = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 100,
                child: ResizableDivider(
                  direction: SplitDirection.vertical,
                  onDrag: (delta) {
                    dragDelta = delta;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(GestureDetector), const Offset(0, 50));
      await tester.pump();

      expect(dragDelta, isNonZero);
    });

    testWidgets('contains MouseRegion for cursor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ResizableDivider(
                direction: SplitDirection.horizontal,
                onDrag: (delta) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MouseRegion), findsWidgets);
    });
  });

  group('SplitScreenToolbar', () {
    testWidgets('shows split toggle button', (tester) async {
      final controller = SplitScreenController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SplitScreenToolbar(controller: controller)),
        ),
      );

      expect(find.byIcon(Icons.vertical_split), findsOneWidget);

      controller.dispose();
    });

    testWidgets('toggles split on button press', (tester) async {
      final controller = SplitScreenController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SplitScreenToolbar(controller: controller)),
        ),
      );

      expect(controller.isSplitEnabled, isFalse);

      await tester.tap(find.text('Split'));
      await tester.pump();

      expect(controller.isSplitEnabled, isTrue);

      controller.dispose();
    });

    testWidgets('shows swap button when split enabled', (tester) async {
      final controller = SplitScreenController();
      controller.enableSplit();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SplitScreenToolbar(controller: controller)),
        ),
      );

      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

      controller.dispose();
    });

    testWidgets('compact mode shows only icon buttons', (tester) async {
      final controller = SplitScreenController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitScreenToolbar(controller: controller, compact: true),
          ),
        ),
      );

      expect(find.byType(IconButton), findsWidgets);
      expect(find.text('Split'), findsNothing);

      controller.dispose();
    });
  });

  group('PaneWrapper', () {
    testWidgets('shows empty state when pane is empty', (tester) async {
      const paneState = PaneState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaneWrapper(
              paneState: paneState,
              isRightPane: false,
              onClose: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Open a file in this pane'), findsOneWidget);
      expect(find.text('Left pane'), findsOneWidget);
    });

    testWidgets('shows right pane label correctly', (tester) async {
      const paneState = PaneState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaneWrapper(
              paneState: paneState,
              isRightPane: true,
              onClose: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Right pane'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      const paneState = PaneState();
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaneWrapper(
              paneState: paneState,
              isRightPane: false,
              onClose: () {},
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PaneWrapper));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders active pane correctly', (tester) async {
      const paneState = PaneState(
        filePath: '/test.md',
        fileType: PaneFileType.markdown,
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 500,
              child: PaneWrapper(
                paneState: paneState,
                isRightPane: false,
                onClose: () {},
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Pane should render without error - we removed the Active indicator
      // but active pane should still be tappable
      expect(find.byType(PaneWrapper), findsOneWidget);
    });
  });

  group('SplitScreenContainer', () {
    testWidgets('shows single pane when split is disabled', (tester) async {
      final controller = SplitScreenController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitScreenContainer(controller: controller),
            ),
          ),
        ),
      );

      expect(find.byType(PaneWrapper), findsOneWidget);

      controller.dispose();
    });

    testWidgets('shows two panes when split is enabled', (tester) async {
      final controller = SplitScreenController();
      controller.enableSplit();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitScreenContainer(controller: controller),
            ),
          ),
        ),
      );

      expect(find.byType(PaneWrapper), findsNWidgets(2));
      expect(find.byType(ResizableDivider), findsOneWidget);

      controller.dispose();
    });

    testWidgets('shows divider between panes', (tester) async {
      final controller = SplitScreenController();
      controller.enableSplit();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitScreenContainer(controller: controller),
            ),
          ),
        ),
      );

      expect(find.byType(ResizableDivider), findsOneWidget);

      controller.dispose();
    });

    testWidgets('showFileBrowserWhenEmpty creates container with parameter', (
      tester,
    ) async {
      final controller = SplitScreenController();
      controller.enableSplit();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: SplitScreenContainer(
                controller: controller,
                showFileBrowserWhenEmpty: false,
              ),
            ),
          ),
        ),
      );

      // Should show empty pane message, not file browser
      expect(find.text('Open a file in this pane'), findsWidgets);

      controller.dispose();
    });

    testWidgets('split mode persists when closePane with keepSplitEnabled', (
      tester,
    ) async {
      final controller = SplitScreenController();
      controller.enableSplit();
      controller.openFile('/test.kvx');
      controller.openFile('/test.md', inRightPane: true);

      // Close right pane with keepSplitEnabled
      controller.closePane(isRightPane: true, keepSplitEnabled: true);

      // Should still be in split mode
      expect(controller.isSplitEnabled, isTrue);
      expect(controller.rightPane.isEmpty, isTrue);

      controller.dispose();
    });
  });
}
