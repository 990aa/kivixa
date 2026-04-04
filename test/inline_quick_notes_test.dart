import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/quick_notes/inline_quick_notes.dart';
import 'package:kivixa/components/quick_notes/quick_note_canvas.dart';
import 'package:kivixa/services/quick_notes/quick_notes_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    QuickNotesService.instance.resetForTests();
  });

  tearDown(() {
    QuickNotesService.instance.resetForTests();
  });

  Future<void> pumpInlineQuickNotes(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InlineQuickNotes())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quick Notes'));
    await tester.pumpAndSettle();
  }

  group('InlineQuickNotes editing', () {
    testWidgets('opens a saved text note in text editor and updates it', (
      tester,
    ) async {
      await pumpInlineQuickNotes(tester);

      await tester.tap(find.text('Add Note'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'first quick note');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('first quick note'), findsOneWidget);

      await tester.tap(find.text('first quick note'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'first quick note');

      await tester.enterText(find.byType(TextField), 'updated quick note');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('updated quick note'), findsOneWidget);
      expect(
        QuickNotesService.instance.activeNotes.first.content,
        'updated quick note',
      );
    });

    testWidgets(
      'opens a saved handwritten note in drawing editor and updates it',
      (tester) async {
        await pumpInlineQuickNotes(tester);

        await tester.tap(find.text('Add Note'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Draw'));
        await tester.pumpAndSettle();

        final canvas = find.byType(QuickNoteCanvas).first;
        final firstGesture = await tester.startGesture(
          tester.getCenter(canvas),
        );
        await firstGesture.moveBy(const Offset(24, 16));
        await firstGesture.up();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final initialData =
            QuickNotesService.instance.activeNotes.first.handwrittenData;
        expect(initialData, isNotNull);

        await tester.tap(find.byType(QuickNoteHandwritingPreview).first);
        await tester.pumpAndSettle();

        expect(find.text('Editing handwritten note'), findsOneWidget);

        final secondCanvas = find.byType(QuickNoteCanvas).first;
        final secondGesture = await tester.startGesture(
          tester.getCenter(secondCanvas),
        );
        await secondGesture.moveBy(const Offset(-20, 12));
        await secondGesture.up();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Update'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        final updatedData =
            QuickNotesService.instance.activeNotes.first.handwrittenData;
        expect(updatedData, isNotNull);
        expect(updatedData, isNot(equals(initialData)));
      },
    );
  });
}
