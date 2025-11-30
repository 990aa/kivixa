import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/split_screen/split_screen_state.dart';

void main() {
  group('getFileTypeFromPath', () {
    test('returns handwritten for .kvx files', () {
      expect(getFileTypeFromPath('/test.kvx'), PaneFileType.handwritten);
      expect(getFileTypeFromPath('/folder/note.kvx'), PaneFileType.handwritten);
    });

    test('returns markdown for .md files', () {
      expect(getFileTypeFromPath('/test.md'), PaneFileType.markdown);
      expect(getFileTypeFromPath('/folder/note.md'), PaneFileType.markdown);
    });

    test('returns textDocument for .kvtx files', () {
      expect(getFileTypeFromPath('/test.kvtx'), PaneFileType.textDocument);
      expect(
        getFileTypeFromPath('/folder/doc.kvtx'),
        PaneFileType.textDocument,
      );
    });
  });

  group('PaneState', () {
    test('default constructor creates state with given values', () {
      const state = PaneState(
        filePath: '/test.kvx',
        fileType: PaneFileType.handwritten,
        isActive: true,
      );
      expect(state.isEmpty, isFalse);
      expect(state.filePath, '/test.kvx');
      expect(state.fileType, PaneFileType.handwritten);
      expect(state.isActive, isTrue);
    });

    test('empty state has no file and is inactive', () {
      const state = PaneState();
      expect(state.isEmpty, isTrue);
      expect(state.filePath, isNull);
      expect(state.fileType, PaneFileType.none);
      expect(state.isActive, isFalse);
    });

    test('PaneState with file path is not empty', () {
      const state = PaneState(
        filePath: '/test.kvx',
        fileType: PaneFileType.handwritten,
        isActive: false,
      );
      expect(state.isEmpty, isFalse);
      expect(state.filePath, '/test.kvx');
      expect(state.fileType, PaneFileType.handwritten);
    });

    test('copyWith creates new instance with updated values', () {
      const state = PaneState(
        filePath: '/test.kvx',
        fileType: PaneFileType.handwritten,
        isActive: false,
      );

      final newState = state.copyWith(isActive: true);
      expect(newState.isActive, isTrue);
      expect(newState.filePath, '/test.kvx');
    });

    test('equality works correctly', () {
      const state1 = PaneState(
        filePath: '/test.kvx',
        fileType: PaneFileType.handwritten,
        isActive: true,
      );
      const state2 = PaneState(
        filePath: '/test.kvx',
        fileType: PaneFileType.handwritten,
        isActive: true,
      );
      const state3 = PaneState(
        filePath: '/other.kvx',
        fileType: PaneFileType.handwritten,
        isActive: true,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });

  group('SplitScreenController', () {
    late SplitScreenController controller;

    setUp(() {
      controller = SplitScreenController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is not split with default ratio', () {
      expect(controller.isSplitEnabled, isFalse);
      expect(controller.splitRatio, 0.5);
      expect(controller.splitDirection, SplitDirection.horizontal);
    });

    test('initial panes are empty with left pane active', () {
      expect(controller.leftPane.isEmpty, isTrue);
      expect(controller.rightPane.isEmpty, isTrue);
      expect(controller.leftPane.isActive, isTrue);
      expect(controller.rightPane.isActive, isFalse);
    });

    test('enableSplit sets isSplitEnabled to true', () {
      expect(controller.isSplitEnabled, isFalse);
      controller.enableSplit();
      expect(controller.isSplitEnabled, isTrue);
    });

    test('disableSplit sets isSplitEnabled to false', () {
      controller.enableSplit();
      expect(controller.isSplitEnabled, isTrue);
      controller.disableSplit();
      expect(controller.isSplitEnabled, isFalse);
    });

    test('toggleSplit toggles split state', () {
      expect(controller.isSplitEnabled, isFalse);
      controller.toggleSplit();
      expect(controller.isSplitEnabled, isTrue);
      controller.toggleSplit();
      expect(controller.isSplitEnabled, isFalse);
    });

    test('setSplitDirection changes direction', () {
      expect(controller.splitDirection, SplitDirection.horizontal);
      controller.setSplitDirection(SplitDirection.vertical);
      expect(controller.splitDirection, SplitDirection.vertical);
    });

    test('toggleSplitDirection toggles between horizontal and vertical', () {
      expect(controller.splitDirection, SplitDirection.horizontal);
      controller.toggleSplitDirection();
      expect(controller.splitDirection, SplitDirection.vertical);
      controller.toggleSplitDirection();
      expect(controller.splitDirection, SplitDirection.horizontal);
    });

    test('setSplitRatio clamps value between min and max', () {
      controller.setSplitRatio(0.7);
      expect(controller.splitRatio, 0.7);

      controller.setSplitRatio(0.1); // Below min (0.2)
      expect(controller.splitRatio, 0.2);

      controller.setSplitRatio(0.9); // Above max (0.8)
      expect(controller.splitRatio, 0.8);
    });

    test('openFile opens file in left pane by default', () {
      controller.openFile('/test.kvx');
      expect(controller.leftPane.filePath, '/test.kvx');
      expect(controller.leftPane.isActive, isTrue);
    });

    test('openFile can open file in right pane when split enabled', () {
      controller.enableSplit();
      controller.openFile('/test.md', inRightPane: true);
      expect(controller.rightPane.filePath, '/test.md');
      expect(controller.rightPane.isActive, isTrue);
      expect(controller.leftPane.isActive, isFalse);
    });

    test('openFileInOtherPane opens in opposite pane', () {
      controller.openFile('/left.kvx'); // Opens in left pane
      controller.openFileInOtherPane('/right.md');

      expect(controller.leftPane.filePath, '/left.kvx');
      expect(controller.rightPane.filePath, '/right.md');
      expect(controller.isSplitEnabled, isTrue);
    });

    test('openFileInOtherPane enables split if not already enabled', () {
      expect(controller.isSplitEnabled, isFalse);
      controller.openFile('/left.kvx');
      controller.openFileInOtherPane('/right.md');
      expect(controller.isSplitEnabled, isTrue);
    });

    test('setActivePane switches active pane', () {
      controller.enableSplit();
      controller.openFile('/left.kvx');
      controller.openFile('/right.md', inRightPane: true);

      controller.setActivePane(isRightPane: false);
      expect(controller.leftPane.isActive, isTrue);
      expect(controller.rightPane.isActive, isFalse);

      controller.setActivePane(isRightPane: true);
      expect(controller.leftPane.isActive, isFalse);
      expect(controller.rightPane.isActive, isTrue);
    });

    test('closePane clears the specified pane', () {
      controller.enableSplit();
      controller.openFile('/left.kvx');
      controller.openFile('/right.md', inRightPane: true);

      controller.closePane(isRightPane: true);
      expect(controller.rightPane.isEmpty, isTrue);
      expect(controller.leftPane.filePath, '/left.kvx');
    });

    test('closePane disables split when only one pane has content', () {
      controller.enableSplit();
      controller.openFile('/left.kvx');
      controller.openFile('/right.md', inRightPane: true);

      controller.closePane(isRightPane: true);
      expect(controller.isSplitEnabled, isFalse);
    });

    test('closePane with keepSplitEnabled keeps split mode active', () {
      controller.enableSplit();
      controller.openFile('/left.kvx');
      controller.openFile('/right.md', inRightPane: true);

      controller.closePane(isRightPane: true, keepSplitEnabled: true);
      expect(controller.isSplitEnabled, isTrue);
      expect(controller.rightPane.isEmpty, isTrue);
      expect(controller.leftPane.filePath, '/left.kvx');
    });

    test('closePane with keepSplitEnabled false disables split', () {
      controller.enableSplit();
      controller.openFile('/left.kvx');
      controller.openFile('/right.md', inRightPane: true);

      controller.closePane(isRightPane: true, keepSplitEnabled: false);
      expect(controller.isSplitEnabled, isFalse);
    });

    test('closePane left pane with keepSplitEnabled keeps split mode', () {
      controller.enableSplit();
      controller.openFile('/left.kvx');
      controller.openFile('/right.md', inRightPane: true);

      controller.closePane(isRightPane: false, keepSplitEnabled: true);
      expect(controller.isSplitEnabled, isTrue);
      // When closing left pane with content in right, right moves to left
      expect(controller.leftPane.filePath, '/right.md');
      expect(controller.rightPane.isEmpty, isTrue);
    });

    test('swapPanes exchanges pane contents', () {
      controller.enableSplit();
      controller.openFile('/left.kvx');
      controller.openFile('/right.md', inRightPane: true);

      controller.swapPanes();

      expect(controller.leftPane.filePath, '/right.md');
      expect(controller.rightPane.filePath, '/left.kvx');
    });

    test('resetSplitRatio resets to 0.5', () {
      controller.setSplitRatio(0.7);
      expect(controller.splitRatio, 0.7);

      controller.resetSplitRatio();
      expect(controller.splitRatio, 0.5);
    });

    test('clear resets all state', () {
      controller.enableSplit();
      controller.openFile('/test.kvx');
      controller.openFileInOtherPane('/test.md');
      controller.setSplitRatio(0.7);

      controller.clear();

      expect(controller.isSplitEnabled, isFalse);
      expect(controller.leftPane.isEmpty, isTrue);
      expect(controller.rightPane.isEmpty, isTrue);
      expect(controller.leftPane.isActive, isTrue);
    });

    test('controller notifies listeners on state change', () {
      var notifyCount = 0; // Mutable counter for notifications
      controller.addListener(() => notifyCount++);

      controller.enableSplit();
      expect(notifyCount, 1);

      controller.openFile('/test.kvx');
      expect(notifyCount, 2);

      controller.setSplitRatio(0.6);
      expect(notifyCount, 3);
    });
  });

  group('SplitDirection', () {
    test('horizontal direction is the default', () {
      final controller = SplitScreenController();
      expect(controller.splitDirection, SplitDirection.horizontal);
      controller.dispose();
    });

    test('can switch to vertical direction', () {
      final controller = SplitScreenController();
      controller.setSplitDirection(SplitDirection.vertical);
      expect(controller.splitDirection, SplitDirection.vertical);
      controller.dispose();
    });
  });

  group('Split ratio constraints', () {
    test('minPaneRatio is 0.2', () {
      expect(SplitScreenController.minPaneRatio, 0.2);
    });

    test('maxPaneRatio is 0.8', () {
      expect(SplitScreenController.maxPaneRatio, 0.8);
    });

    test('minSplitWidth is 600', () {
      expect(SplitScreenController.minSplitWidth, 600.0);
    });
  });
}
