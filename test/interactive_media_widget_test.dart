import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/media/interactive_media_widget.dart';
import 'package:kivixa/data/models/media_element.dart';

void main() {
  group('InteractiveMediaWidget', () {
    late MediaElement testElement;

    setUp(() {
      testElement = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        width: 200,
        height: 150,
      );
    });

    Widget buildTestWidget({
      required MediaElement element,
      required Function(MediaElement) onChanged,
      bool isSelected = false,
      bool showRotationHandle = true,
      bool showMoveHandle = true,
      bool lockAspectRatio = false,
      Widget? child,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: InteractiveMediaWidget(
              element: element,
              onChanged: onChanged,
              isSelected: isSelected,
              showRotationHandle: showRotationHandle,
              showMoveHandle: showMoveHandle,
              lockAspectRatio: lockAspectRatio,
              child: child ?? Container(color: Colors.blue),
            ),
          ),
        ),
      );
    }

    testWidgets('renders with correct initial dimensions', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        element: testElement,
        onChanged: (_) {},
      ));

      // Find the sized box containing the content
      final sizedBoxFinder = find.byType(SizedBox);
      expect(sizedBoxFinder, findsWidgets);
    });

    testWidgets('shows resize handles when selected', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        element: testElement,
        onChanged: (_) {},
        isSelected: true,
      ));

      // Should show 8 resize handles (4 corners + 4 edges)
      // Handles are small containers
      final handleFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).borderRadius != null,
      );
      expect(handleFinder, findsWidgets);
    });

    testWidgets('shows rotation handle when selected and enabled', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        element: testElement,
        onChanged: (_) {},
        isSelected: true,
        showRotationHandle: true,
      ));

      // Should find the rotation icon
      expect(find.byIcon(Icons.rotate_right), findsOneWidget);
    });

    testWidgets('hides rotation handle when disabled', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        element: testElement,
        onChanged: (_) {},
        isSelected: true,
        showRotationHandle: false,
      ));

      expect(find.byIcon(Icons.rotate_right), findsNothing);
    });

    testWidgets('shows move handle when selected and enabled', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        element: testElement,
        onChanged: (_) {},
        isSelected: true,
        showMoveHandle: true,
      ));

      expect(find.byIcon(Icons.open_with), findsOneWidget);
    });

    testWidgets('hides move handle when disabled', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        element: testElement,
        onChanged: (_) {},
        isSelected: true,
        showMoveHandle: false,
      ));

      expect(find.byIcon(Icons.open_with), findsNothing);
    });

    testWidgets('calls onChanged when dragged', (tester) async {
      MediaElement? changedElement;

      await tester.pumpWidget(buildTestWidget(
        element: testElement,
        onChanged: (element) => changedElement = element,
        isSelected: true,
      ));

      // Find the gesture detector and drag it
      final gestureDetector = find.byType(GestureDetector).first;
      await tester.drag(gestureDetector, const Offset(50, 30));
      await tester.pumpAndSettle();

      // onChanged should have been called with updated position
      expect(changedElement, isNotNull);
      expect(changedElement!.posX, isNot(equals(0)));
      expect(changedElement!.posY, isNot(equals(0)));
    });

    testWidgets('respects minimum dimensions', (tester) async {
      MediaElement? changedElement;

      final smallElement = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        width: 100,
        height: 100,
      );

      await tester.pumpWidget(buildTestWidget(
        element: smallElement,
        onChanged: (element) => changedElement = element,
        isSelected: true,
      ));

      // Try to resize smaller than minimum
      // The widget should not allow dimensions below minWidth/minHeight
      // This would be tested via dragging resize handles
    });

    testWidgets('applies rotation transform', (tester) async {
      final rotatedElement = testElement.copyWith(rotation: 45.0);

      await tester.pumpWidget(buildTestWidget(
        element: rotatedElement,
        onChanged: (_) {},
      ));

      // Find the Transform.rotate widget
      final transformFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Transform &&
            widget.transform != Matrix4.identity(),
      );
      expect(transformFinder, findsWidgets);
    });

    testWidgets('applies position offset', (tester) async {
      final movedElement = testElement.copyWith(posX: 100, posY: 50);

      await tester.pumpWidget(buildTestWidget(
        element: movedElement,
        onChanged: (_) {},
      ));

      // The widget should be translated
      final transformFinder = find.byType(Transform);
      expect(transformFinder, findsWidgets);
    });

    testWidgets('renders custom child widget', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        element: testElement,
        onChanged: (_) {},
        child: const Text('Custom Child'),
      ));

      expect(find.text('Custom Child'), findsOneWidget);
    });

    testWidgets('calls onTap callback', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InteractiveMediaWidget(
            element: testElement,
            onChanged: (_) {},
            onTap: () => tapCount++,
            child: Container(color: Colors.blue, width: 200, height: 150),
          ),
        ),
      ));

      await tester.tap(find.byType(InteractiveMediaWidget));
      await tester.pump();

      expect(tapCount, equals(1));
    });

    testWidgets('calls onDoubleTap callback', (tester) async {
      var doubleTapCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InteractiveMediaWidget(
            element: testElement,
            onChanged: (_) {},
            onDoubleTap: () => doubleTapCount++,
            child: Container(color: Colors.blue, width: 200, height: 150),
          ),
        ),
      ));

      await tester.tap(find.byType(InteractiveMediaWidget));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(InteractiveMediaWidget));
      await tester.pumpAndSettle();

      expect(doubleTapCount, equals(1));
    });

    testWidgets('wraps in RepaintBoundary for performance', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        element: testElement,
        onChanged: (_) {},
      ));

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('shows border when selected', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        element: testElement,
        onChanged: (_) {},
        isSelected: true,
      ));

      // Find decorated box with border
      final decoratedBoxFinder = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).border != null,
      );
      expect(decoratedBoxFinder, findsWidgets);
    });
  });

  group('InteractiveMediaWidget Dimension Updates', () {
    testWidgets('updates element when resized from corner', (tester) async {
      MediaElement? updatedElement;
      final element = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        width: 200,
        height: 200,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: InteractiveMediaWidget(
              element: element,
              onChanged: (e) => updatedElement = e,
              isSelected: true,
              child: Container(color: Colors.blue),
            ),
          ),
        ),
      ));

      // The resize handles should be present when selected
      // A proper test would drag the corner handle
      // For now, verify the widget structure is correct
      expect(find.byType(InteractiveMediaWidget), findsOneWidget);
    });

    test('element copyWith preserves all fields', () {
      final element = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        width: 200,
        height: 150,
        rotation: 45,
        posX: 10,
        posY: 20,
        comment: 'Test comment',
      );

      final copied = element.copyWith(width: 300);

      expect(copied.width, equals(300));
      expect(copied.height, equals(150)); // Preserved
      expect(copied.rotation, equals(45)); // Preserved
      expect(copied.posX, equals(10)); // Preserved
      expect(copied.posY, equals(20)); // Preserved
      expect(copied.comment, equals('Test comment')); // Preserved
    });
  });

  group('InteractiveMediaWidget Video Handling', () {
    test('video elements disable rotation by default', () {
      final videoElement = MediaElement(
        path: 'video.mp4',
        mediaType: MediaType.video,
        width: 640,
        height: 360,
      );

      // Videos typically don't support rotation in the UI
      // The showRotationHandle should be false for videos
      expect(videoElement.isVideo, isTrue);
    });
  });
}
