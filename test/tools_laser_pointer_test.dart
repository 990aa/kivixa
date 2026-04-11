import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/editor/page.dart';
import 'package:kivixa/data/tools/laser_pointer.dart';
import 'package:kivixa/data/tools/pen.dart';

void main() {
  group('Laser fade', () {
    final laserPointer = LaserPointer.currentLaserPointer;
    const strokePointDelays = [
      Duration.zero,
      Duration(milliseconds: 37),
      Duration(milliseconds: 21),
      Duration(milliseconds: 52),
    ];
    final page = EditorPage();

    setUp(() {
      var cursorPos = const Offset(200, 200);
      laserPointer.onDragStart(cursorPos, page, 0);
      for (final delay in strokePointDelays.skip(1)) {
        cursorPos += const Offset(15, 15);
        laserPointer.onDragUpdate(cursorPos, elapsed: delay);
      }
    });

    test('matches drawn speed', () {
      fakeAsync((async) {
        expect(laserPointer.strokePointDelays, strokePointDelays);
        final stroke = Pen.currentStroke as LaserStroke;
        expect(stroke.length, strokePointDelays.length);

        var redraws = 0;
        var deletions = 0;

        LaserPointer.isDrawing = false;

        LaserPointer.fadeOutStroke(
          stroke: stroke,
          strokePointDelays: strokePointDelays,
          redrawPage: () => redraws++,
          deleteStroke: (_) => deletions++,
        );

        async.elapse(LaserPointer.fadeOutDelay);

        for (final delay in strokePointDelays) {
          async.elapse(delay);
        }

        expect(redraws, 4);
        expect(deletions, 1);
      });
    });

    test('reduces point count', () {
      fakeAsync((async) {
        final stroke = Pen.currentStroke as LaserStroke;
        final initialLength = stroke.length;

        LaserPointer.isDrawing = false;

        LaserPointer.fadeOutStroke(
          stroke: stroke,
          strokePointDelays: strokePointDelays,
          redrawPage: () {},
          deleteStroke: (_) {
            expect(
              stroke.length,
              lessThanOrEqualTo(1),
              reason: 'Stroke should only be deleted at end',
            );
          },
        );

        async.elapse(LaserPointer.fadeOutDelay);

        for (int i = 0; i < strokePointDelays.length; i++) {
          async.elapse(strokePointDelays[i]);
          if (i < strokePointDelays.length - 1) {
             expect(stroke.length, initialLength - (i + 1));
          }
        }
      });
    });

    test('produces valid strokes', () {
      fakeAsync((async) {
        final stroke = Pen.currentStroke as LaserStroke;
        expect(stroke.points, isNotEmpty);

        LaserPointer.isDrawing = false;

        LaserPointer.fadeOutStroke(
          stroke: stroke,
          strokePointDelays: strokePointDelays,
          redrawPage: () {
            expect(stroke.points, isNotEmpty);
            expect(() => stroke.lowQualityPath, returnsNormally);
          },
          deleteStroke: (stroke) {},
        );

        async.elapse(LaserPointer.fadeOutDelay);
        for (final delay in strokePointDelays) {
          async.elapse(delay);
        }
      });
    });

    test('pauses fade out when isDrawing is true', () {
      fakeAsync((async) {
        final stroke = Pen.currentStroke as LaserStroke;

        var redraws = 0;
        var deletions = 0;

        LaserPointer.isDrawing = false;

        LaserPointer.fadeOutStroke(
          stroke: stroke,
          strokePointDelays: strokePointDelays,
          redrawPage: () => redraws++,
          deleteStroke: (_) => deletions++,
        );

        // Advance initial delay
        async.elapse(LaserPointer.fadeOutDelay);

        // Flush microtasks or elapse zero to ensure the Duration.zero timer has fired
        async.elapse(Duration.zero);

        // First delay is Duration.zero, so the first point is popped immediately after fadeOutDelay
        expect(redraws, 1);

        // Before advancing the delay for the *second* point (strokePointDelays[1]),
        // we set isDrawing to true.
        // The delay for the second point is 37ms. Let's advance 37ms.
        // It will pop the second point, redraw, and then check `if (isDrawing)`.
        LaserPointer.isDrawing = true;

        async.elapse(strokePointDelays[1]);

        // Redraws should now be 2, because we elapsed enough time for the second point to pop
        expect(redraws, 2);

        // Now the code is inside the `while (isDrawing)` loop, waiting `waitTime` (100ms) repeatedly.
        // If we elapse 500ms, it should stay stuck there, not popping any more points.
        async.elapse(const Duration(milliseconds: 500));

        // No new redraws or deletions
        expect(redraws, 2);
        expect(deletions, 0);

        // User stops drawing
        LaserPointer.isDrawing = false;

        // Wait 100ms for the while loop condition to be checked
        async.elapse(const Duration(milliseconds: 100));

        // It then waits `fadeOutDelay - waitTime` (1.9 seconds).
        async.elapse(LaserPointer.fadeOutDelay - const Duration(milliseconds: 100));

        // Now it's out of the isDrawing block. Let's advance the rest of the delays.
        for (final delay in strokePointDelays.skip(2)) {
          async.elapse(delay);
        }

        // All points popped and deleted
        expect(redraws, 4);
        expect(deletions, 1);
      });
    });
  });
}
