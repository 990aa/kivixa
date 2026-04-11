import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/overlay/global_overlay.dart';
import 'package:kivixa/components/overlay/floating_window.dart';
import 'package:kivixa/components/quick_notes/floating_quick_notes.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';
import 'package:kivixa/services/quick_notes/quick_notes_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OverlayController controller;

  Future<void> pumpOverlay(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlobalOverlay(
          child: Scaffold(body: SizedBox.expand(child: ColoredBox(color: Colors.white))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(() {
    FlavorConfig.setup();
    OverlayController.testMode = true;
  });

  tearDownAll(() {
    OverlayController.testMode = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    QuickNotesService.instance.resetForTests();
    controller = OverlayController.instance;
    controller.reset();
    stows.floatingHubEnabled.value = false;
  });

  tearDown(() {
    QuickNotesService.instance.resetForTests();
    controller.reset();
    stows.floatingHubEnabled.value = stows.floatingHubEnabled.defaultValue;
  });

  testWidgets('quick notes window uses resizable container in overlay', (
    tester,
  ) async {
    controller.openToolWindow(
      'quick_notes',
      initialRect: const Rect.fromLTWH(120, 120, 360, 420),
    );

    await pumpOverlay(tester);

    expect(find.byType(FloatingQuickNotes), findsOneWidget);
    expect(find.byType(ResizableWindowContainer), findsOneWidget);
  });

  testWidgets('quick notes drag and resize update persisted window rect', (
    tester,
  ) async {
    controller.openToolWindow(
      'quick_notes',
      initialRect: const Rect.fromLTWH(100, 100, 360, 420),
    );

    await pumpOverlay(tester);

    final initialRect = controller.getToolWindowRect('quick_notes');
    expect(initialRect, isNotNull);

    await tester.drag(find.text('Quick Notes').first, const Offset(44, 28));
    await tester.pumpAndSettle();

    final draggedRect = controller.getToolWindowRect('quick_notes');
    expect(draggedRect, isNotNull);
    expect(draggedRect!.left, greaterThan(initialRect!.left));
    expect(draggedRect.top, greaterThan(initialRect.top));

    final quickNotesFinder = find.byType(FloatingQuickNotes);
    final topLeft = tester.getTopLeft(quickNotesFinder);
    final size = tester.getSize(quickNotesFinder);
    final resizeStart = Offset(
      topLeft.dx + size.width + 2,
      topLeft.dy + (size.height / 2),
    );

    final resizeGesture = await tester.startGesture(resizeStart);
    await resizeGesture.moveBy(const Offset(36, 0));
    await resizeGesture.up();
    await tester.pumpAndSettle();

    final resizedRect = controller.getToolWindowRect('quick_notes');
    expect(resizedRect, isNotNull);
    expect(resizedRect!.width, greaterThan(draggedRect.width));
  });
}
