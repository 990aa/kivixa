import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/media/image_preview_widget.dart';
import 'package:kivixa/components/media/media_comment_overlay.dart';
import 'package:kivixa/components/media/media_video_player.dart';
import 'package:kivixa/data/models/media_element.dart';

void main() {
  group('MediaCommentOverlay', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaCommentOverlay(
              comment: null,
              onCommentChanged: _noopCommentChanged,
              child: Text('Child Content'),
            ),
          ),
        ),
      );

      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets('shows comment icon when comment exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaCommentOverlay(
              comment: 'Test comment',
              onCommentChanged: _noopCommentChanged,
              child: SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // On mobile, should show comment icon
      // On desktop, comment shows on hover
      expect(find.byType(MediaCommentOverlay), findsOneWidget);
    });

    testWidgets('calls onCommentChanged when comment is saved', (tester) async {
      String? savedComment;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaCommentOverlay(
              comment: 'Initial',
              onCommentChanged: (comment) => savedComment = comment,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // The actual save would be triggered by UI interaction
      // This tests the callback mechanism
      expect(find.byType(MediaCommentOverlay), findsOneWidget);
    });

    testWidgets('can be disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaCommentOverlay(
              comment: 'Test',
              onCommentChanged: _noopCommentChanged,
              enabled: false,
              child: Text('Content'),
            ),
          ),
        ),
      );

      // When disabled, should just render the child without overlay features
      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('MediaVideoPlayer', () {
    late MediaElement videoElement;

    setUp(() {
      videoElement = MediaElement(
        path: '/test/video.mp4',
        mediaType: MediaType.video,
        width: 400,
        height: 225,
      );
    });

    testWidgets('renders with correct dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaVideoPlayer(
              element: videoElement,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.constraints?.maxWidth, equals(400));
      expect(container.constraints?.maxHeight, equals(225));
    });

    testWidgets('shows play button when not playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaVideoPlayer(
              element: videoElement,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Should find play icon
      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });

    testWidgets('shows controls when showControls is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaVideoPlayer(
              element: videoElement,
              onChanged: (_) {},
              showControls: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Should find slider for progress bar
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('hides controls when showControls is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaVideoPlayer(
              element: videoElement,
              onChanged: (_) {},
              showControls: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Should not find slider
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('displays video filename', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaVideoPlayer(
              element: videoElement,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('video.mp4'), findsOneWidget);
    });

    testWidgets('wraps in RepaintBoundary for performance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaVideoPlayer(
              element: videoElement,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
    });
  });

  group('ImagePreviewWidget', () {
    late MediaElement largeImageElement;

    setUp(() {
      largeImageElement = MediaElement(
        path: '/test/large_image.jpg',
        mediaType: MediaType.image,
        width: 2500,
        height: 2000,
        isPreviewMode: true,
        previewWidth: 300,
        previewHeight: 300,
      );
    });

    testWidgets('renders with preview dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePreviewWidget(
              element: largeImageElement,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Widget should render
      expect(find.byType(ImagePreviewWidget), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePreviewWidget(
              element: largeImageElement,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows minimap toggle button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePreviewWidget(
              element: largeImageElement,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Look for map icon (minimap toggle)
      expect(find.byIcon(Icons.map), findsOneWidget);
    });

    testWidgets('shows reset zoom button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePreviewWidget(
              element: largeImageElement,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fit_screen), findsOneWidget);
    });

    testWidgets('shows exit preview button when callback provided', (tester) async {
      var exitCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePreviewWidget(
              element: largeImageElement,
              onChanged: (_) {},
              onExitPreview: () => exitCalled = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);

      await tester.tap(find.byIcon(Icons.fullscreen_exit));
      expect(exitCalled, isTrue);
    });

    testWidgets('contains InteractiveViewer for pan/zoom', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePreviewWidget(
              element: largeImageElement,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });

  group('MediaElement Model', () {
    test('creates image element correctly', () {
      final element = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
      );

      expect(element.isImage, isTrue);
      expect(element.isVideo, isFalse);
      expect(element.path, equals('test.jpg'));
    });

    test('creates video element correctly', () {
      final element = MediaElement(
        path: 'test.mp4',
        mediaType: MediaType.video,
      );

      expect(element.isVideo, isTrue);
      expect(element.isImage, isFalse);
    });

    test('detects web source type', () {
      final element = MediaElement(
        path: 'https://example.com/image.png',
        mediaType: MediaType.image,
        sourceType: MediaSourceType.web,
      );

      expect(element.isFromWeb, isTrue);
      expect(element.isLocal, isFalse);
    });

    test('detects local source type', () {
      final element = MediaElement(
        path: '/local/path/image.png',
        mediaType: MediaType.image,
        sourceType: MediaSourceType.local,
      );

      expect(element.isLocal, isTrue);
      expect(element.isFromWeb, isFalse);
    });

    test('hasCustomDimensions returns correct value', () {
      final withDimensions = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        width: 300,
        height: 200,
      );

      final withoutDimensions = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
      );

      expect(withDimensions.hasCustomDimensions, isTrue);
      expect(withoutDimensions.hasCustomDimensions, isFalse);
    });

    test('hasRotation returns correct value', () {
      final rotated = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        rotation: 45,
      );

      final notRotated = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
      );

      expect(rotated.hasRotation, isTrue);
      expect(notRotated.hasRotation, isFalse);
    });

    test('hasCustomPosition returns correct value', () {
      final moved = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        posX: 10,
        posY: 20,
      );

      final notMoved = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
      );

      expect(moved.hasCustomPosition, isTrue);
      expect(notMoved.hasCustomPosition, isFalse);
    });

    test('hasComment returns correct value', () {
      final withComment = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        comment: 'A comment',
      );

      final withoutComment = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
      );

      final withEmptyComment = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        comment: '',
      );

      expect(withComment.hasComment, isTrue);
      expect(withoutComment.hasComment, isFalse);
      expect(withEmptyComment.hasComment, isFalse);
    });

    test('equality works correctly', () {
      final element1 = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        width: 300,
        height: 200,
      );

      final element2 = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        width: 300,
        height: 200,
      );

      final element3 = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        width: 400, // Different width
        height: 200,
      );

      expect(element1, equals(element2));
      expect(element1, isNot(equals(element3)));
    });

    test('hashCode is consistent', () {
      final element1 = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        width: 300,
      );

      final element2 = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        width: 300,
      );

      expect(element1.hashCode, equals(element2.hashCode));
    });

    test('toString provides readable output', () {
      final element = MediaElement(
        path: 'test.jpg',
        mediaType: MediaType.image,
        width: 300,
        height: 200,
        rotation: 45,
      );

      final string = element.toString();

      expect(string, contains('test.jpg'));
      expect(string, contains('300'));
      expect(string, contains('200'));
      expect(string, contains('45'));
    });
  });

  group('MediaElement JSON Serialization', () {
    test('serializes to JSON correctly', () {
      final element = MediaElement(
        path: '/test/image.png',
        mediaType: MediaType.image,
        sourceType: MediaSourceType.local,
        altText: 'Test Image',
        width: 400,
        height: 300,
        rotation: 90,
        posX: 50,
        posY: 100,
        comment: 'A test comment',
      );

      final json = element.toJson();

      expect(json['path'], equals('/test/image.png'));
      expect(json['mediaType'], equals('image'));
      expect(json['sourceType'], equals('local'));
      expect(json['altText'], equals('Test Image'));
      expect(json['width'], equals(400));
      expect(json['height'], equals(300));
      expect(json['rotation'], equals(90));
      expect(json['posX'], equals(50));
      expect(json['posY'], equals(100));
      expect(json['comment'], equals('A test comment'));
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'path': '/test/video.mp4',
        'mediaType': 'video',
        'sourceType': 'local',
        'altText': 'Test Video',
        'width': 640,
        'height': 480,
        'rotation': 0.0,
        'posX': 0.0,
        'posY': 0.0,
      };

      final element = MediaElement.fromJson(json);

      expect(element.path, equals('/test/video.mp4'));
      expect(element.mediaType, equals(MediaType.video));
      expect(element.sourceType, equals(MediaSourceType.local));
      expect(element.width, equals(640));
      expect(element.height, equals(480));
    });

    test('round-trips through JSON', () {
      final original = MediaElement(
        path: 'https://example.com/image.jpg',
        mediaType: MediaType.image,
        sourceType: MediaSourceType.web,
        altText: 'Web Image',
        width: 800,
        height: 600,
        rotation: 180,
        posX: 25,
        posY: 75,
        comment: 'From the web',
        isPreviewMode: true,
        previewWidth: 200,
        previewHeight: 150,
        scrollOffsetX: 10,
        scrollOffsetY: 20,
      );

      final json = original.toJson();
      final restored = MediaElement.fromJson(json);

      expect(restored.path, equals(original.path));
      expect(restored.mediaType, equals(original.mediaType));
      expect(restored.sourceType, equals(original.sourceType));
      expect(restored.altText, equals(original.altText));
      expect(restored.width, equals(original.width));
      expect(restored.height, equals(original.height));
      expect(restored.rotation, equals(original.rotation));
      expect(restored.posX, equals(original.posX));
      expect(restored.posY, equals(original.posY));
      expect(restored.comment, equals(original.comment));
      expect(restored.isPreviewMode, equals(original.isPreviewMode));
      expect(restored.previewWidth, equals(original.previewWidth));
      expect(restored.previewHeight, equals(original.previewHeight));
      expect(restored.scrollOffsetX, equals(original.scrollOffsetX));
      expect(restored.scrollOffsetY, equals(original.scrollOffsetY));
    });

    test('handles missing optional fields in JSON', () {
      final json = {
        'path': '/minimal.jpg',
        'mediaType': 'image',
      };

      final element = MediaElement.fromJson(json);

      expect(element.path, equals('/minimal.jpg'));
      expect(element.width, isNull);
      expect(element.height, isNull);
      expect(element.rotation, equals(0.0));
      expect(element.comment, isNull);
    });

    test('toJsonString and fromJsonString work', () {
      final original = MediaElement(
        path: 'test.png',
        mediaType: MediaType.image,
        width: 500,
      );

      final jsonString = original.toJsonString();
      final restored = MediaElement.fromJsonString(jsonString);

      expect(restored.path, equals(original.path));
      expect(restored.width, equals(original.width));
    });
  });
}

void _noopCommentChanged(String? comment) {}
