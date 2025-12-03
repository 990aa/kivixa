// Overlay Controller Tests
//
// Tests for the OverlayController state management and persistence.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  group('OverlayController', () {
    late OverlayController controller;

    setUp(() {
      controller = OverlayController.instance;
      // Manually reset state without triggering save
      controller
        ..updateHubPosition(const Offset(0.95, 0.5))
        ..setHubScale(1.0)
        ..setHubOpacity(0.7);
      if (controller.hubMenuExpanded) controller.toggleHubMenu();
      if (controller.assistantOpen) controller.closeAssistant();
      if (controller.browserOpen) controller.closeBrowser();
    });

    group('Hub Position', () {
      test('default position is near right edge, middle height', () {
        expect(controller.hubPosition.dx, closeTo(0.95, 0.01));
        expect(controller.hubPosition.dy, closeTo(0.5, 0.01));
      });

      test('updateHubPosition clamps values to 0-1 range', () {
        controller.updateHubPosition(const Offset(-0.5, 1.5));
        expect(controller.hubPosition.dx, 0.0);
        expect(controller.hubPosition.dy, 1.0);

        controller.updateHubPosition(const Offset(2.0, -1.0));
        expect(controller.hubPosition.dx, 1.0);
        expect(controller.hubPosition.dy, 0.0);
      });

      test('updateHubPosition accepts valid values', () {
        controller.updateHubPosition(const Offset(0.3, 0.7));
        expect(controller.hubPosition.dx, 0.3);
        expect(controller.hubPosition.dy, 0.7);
      });
    });

    group('Hub Scale', () {
      test('default scale is 1.0', () {
        expect(controller.hubScale, 1.0);
      });

      test('setHubScale clamps to 0.5-1.5 range', () {
        controller.setHubScale(0.2);
        expect(controller.hubScale, 0.5);

        controller.setHubScale(2.0);
        expect(controller.hubScale, 1.5);

        controller.setHubScale(1.2);
        expect(controller.hubScale, 1.2);
      });
    });

    group('Hub Opacity', () {
      test('default opacity is 0.7', () {
        expect(controller.hubOpacity, 0.7);
      });

      test('setHubOpacity clamps to 0.3-1.0 range', () {
        controller.setHubOpacity(0.1);
        expect(controller.hubOpacity, 0.3);

        controller.setHubOpacity(1.5);
        expect(controller.hubOpacity, 1.0);

        controller.setHubOpacity(0.5);
        expect(controller.hubOpacity, 0.5);
      });
    });

    group('Hub Menu', () {
      test('menu starts collapsed', () {
        expect(controller.hubMenuExpanded, false);
      });

      test('toggleHubMenu expands and collapses', () {
        controller.toggleHubMenu();
        expect(controller.hubMenuExpanded, true);

        controller.toggleHubMenu();
        expect(controller.hubMenuExpanded, false);
      });

      test('collapseHubMenu only collapses when expanded', () {
        expect(controller.hubMenuExpanded, false);
        controller
            .collapseHubMenu(); // Should not notify when already collapsed
        expect(controller.hubMenuExpanded, false);

        controller.toggleHubMenu();
        expect(controller.hubMenuExpanded, true);

        controller.collapseHubMenu();
        expect(controller.hubMenuExpanded, false);
      });
    });

    group('AI Assistant Window', () {
      test('assistant window starts closed', () {
        expect(controller.assistantOpen, false);
      });

      test('openAssistant opens the window and collapses menu', () {
        controller.toggleHubMenu(); // Expand menu first
        expect(controller.hubMenuExpanded, true);

        controller.openAssistant();
        expect(controller.assistantOpen, true);
        expect(controller.hubMenuExpanded, false); // Menu should collapse
      });

      test('closeAssistant closes the window', () {
        controller.openAssistant();
        expect(controller.assistantOpen, true);

        controller.closeAssistant();
        expect(controller.assistantOpen, false);
      });

      test('toggleAssistant toggles the window state', () {
        controller.toggleAssistant();
        expect(controller.assistantOpen, true);

        controller.toggleAssistant();
        expect(controller.assistantOpen, false);
      });

      test('updateAssistantRect updates the window rectangle', () {
        const newRect = Rect.fromLTWH(200, 200, 500, 600);
        controller.updateAssistantRect(newRect);
        expect(controller.assistantWindowRect, newRect);
      });

      test('moveAssistant translates the window', () {
        final originalRect = controller.assistantWindowRect;
        controller.moveAssistant(const Offset(50, 30));

        expect(controller.assistantWindowRect.left, originalRect.left + 50);
        expect(controller.assistantWindowRect.top, originalRect.top + 30);
      });

      test('resizeAssistant enforces minimum dimensions', () {
        controller.resizeAssistant(const Rect.fromLTWH(100, 100, 100, 100));

        expect(controller.assistantWindowRect.width, greaterThanOrEqualTo(300));
        expect(
          controller.assistantWindowRect.height,
          greaterThanOrEqualTo(400),
        );
      });
    });

    group('Browser Window', () {
      test('browser window starts closed', () {
        expect(controller.browserOpen, false);
      });

      test('openBrowser opens the window', () {
        controller.openBrowser();
        expect(controller.browserOpen, true);
      });

      test('closeBrowser closes the window', () {
        controller.openBrowser();
        controller.closeBrowser();
        expect(controller.browserOpen, false);
      });

      test('toggleBrowser toggles the window state', () {
        controller.toggleBrowser();
        expect(controller.browserOpen, true);

        controller.toggleBrowser();
        expect(controller.browserOpen, false);
      });
    });

    group('Generic Tool Windows', () {
      test('tool windows start closed', () {
        expect(controller.isToolWindowOpen('test_tool'), false);
        expect(controller.getToolWindowRect('test_tool'), isNull);
      });

      test('openToolWindow creates and opens a tool window', () {
        controller.openToolWindow('test_tool');
        expect(controller.isToolWindowOpen('test_tool'), true);
        expect(controller.getToolWindowRect('test_tool'), isNotNull);
      });

      test('closeToolWindow closes but preserves the window rect', () {
        const initialRect = Rect.fromLTWH(100, 100, 400, 400);
        controller.openToolWindow('test_tool', initialRect: initialRect);

        controller.closeToolWindow('test_tool');
        expect(controller.isToolWindowOpen('test_tool'), false);
        expect(controller.getToolWindowRect('test_tool'), initialRect);
      });

      test('updateToolWindowRect updates position and size', () {
        controller.openToolWindow('test_tool');

        const newRect = Rect.fromLTWH(300, 300, 600, 500);
        controller.updateToolWindowRect('test_tool', newRect);
        expect(controller.getToolWindowRect('test_tool'), newRect);
      });
    });

    group('Bounds Clamping', () {
      test('clampToScreen keeps window visible on screen', () {
        const screenSize = Size(1920, 1080);

        // Window fully off-screen to the right
        const offRight = Rect.fromLTWH(2000, 100, 400, 300);
        final clampedRight = controller.clampToScreen(offRight, screenSize);
        expect(clampedRight.left, lessThanOrEqualTo(screenSize.width - 50));

        // Window fully off-screen to the bottom
        const offBottom = Rect.fromLTWH(100, 1200, 400, 300);
        final clampedBottom = controller.clampToScreen(offBottom, screenSize);
        expect(clampedBottom.top, lessThanOrEqualTo(screenSize.height - 50));
      });

      test('clampToScreen prevents negative positions', () {
        const screenSize = Size(1920, 1080);

        const negativePos = Rect.fromLTWH(-100, -50, 400, 300);
        final clamped = controller.clampToScreen(negativePos, screenSize);
        expect(clamped.left, greaterThanOrEqualTo(0));
        expect(clamped.top, greaterThanOrEqualTo(0));
      });
    });
    group('Reset', () {
      test('reset restores all defaults', () async {
        // Modify all state
        controller.updateHubPosition(const Offset(0.2, 0.3));
        controller.setHubScale(1.3);
        controller.setHubOpacity(0.9);
        controller.toggleHubMenu();
        controller.openAssistant();
        controller.openBrowser();
        controller.openToolWindow('test');

        // Reset
        controller.reset();

        // Allow debounced save to complete
        await Future.delayed(const Duration(milliseconds: 600));

        // Verify defaults
        expect(controller.hubPosition.dx, closeTo(0.95, 0.01));
        expect(controller.hubPosition.dy, closeTo(0.5, 0.01));
        expect(controller.hubScale, 1.0);
        expect(controller.hubOpacity, 0.7);
        expect(controller.hubMenuExpanded, false);
        expect(controller.assistantOpen, false);
        expect(controller.browserOpen, false);
        expect(controller.isToolWindowOpen('test'), false);
        expect(controller.autoReopenWindows, true);
      });
    });

    group('Tool Registration', () {
      test('registerDefaultTools adds AI, browser, and knowledge graph', () {
        controller.registerDefaultTools();
        final tools = controller.registeredTools;

        expect(tools.length, 3);
        expect(tools.any((t) => t.id == 'assistant'), true);
        expect(tools.any((t) => t.id == 'browser'), true);
        expect(tools.any((t) => t.id == 'knowledge_graph'), true);
      });

      test('registerTool adds custom tools', () {
        controller.registerTool(
          OverlayTool(
            id: 'custom_tool',
            icon: Icons.star,
            label: 'Custom Tool',
            onTap: () {},
          ),
        );

        expect(
          controller.registeredTools.any((t) => t.id == 'custom_tool'),
          true,
        );
      });

      test('unregisterTool removes tools', () {
        controller.registerDefaultTools();
        expect(
          controller.registeredTools.any((t) => t.id == 'assistant'),
          true,
        );

        controller.unregisterTool('assistant');
        expect(
          controller.registeredTools.any((t) => t.id == 'assistant'),
          false,
        );
      });

      test('tool isActive callback works correctly', () {
        controller.registerDefaultTools();
        final assistantTool = controller.registeredTools.firstWhere(
          (t) => t.id == 'assistant',
        );

        expect(assistantTool.active, false);
        controller.openAssistant();
        expect(assistantTool.active, true);
      });
    });

    group('Auto-Reopen Windows', () {
      test('autoReopenWindows defaults to true', () {
        expect(controller.autoReopenWindows, true);
      });

      test('setAutoReopenWindows updates the setting', () {
        controller.setAutoReopenWindows(false);
        expect(controller.autoReopenWindows, false);

        controller.setAutoReopenWindows(true);
        expect(controller.autoReopenWindows, true);
      });
    });

    group('Debounced Save', () {
      test('cancelPendingSave cancels scheduled saves', () async {
        // Make a change that schedules a save
        controller.updateHubPosition(const Offset(0.5, 0.5));

        // Cancel the pending save
        controller.cancelPendingSave();

        // Wait for potential save
        await Future.delayed(const Duration(milliseconds: 600));

        // No exception means success (testMode prevents actual save)
      });

      test('forceSave completes immediately', () async {
        controller.updateHubPosition(const Offset(0.5, 0.5));
        await controller.forceSave();
        // Should complete without delay
      });
    });

    group('ChangeNotifier', () {
      test('notifies listeners on state changes', () {
        var notificationCount = 0;
        controller.addListener(() => notificationCount++);

        controller.updateHubPosition(const Offset(0.5, 0.5));
        expect(notificationCount, 1);

        controller.setHubScale(1.2);
        expect(notificationCount, 2);

        controller.toggleHubMenu();
        expect(notificationCount, 3);

        controller.openAssistant();
        expect(notificationCount, 5); // +2: opens assistant and collapses menu
      });
    });
  });
}
