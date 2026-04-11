import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/quick_notes/floating_quick_notes.dart';
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

  testWidgets('floating quick notes can expand beyond old max constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 620,
              height: 560,
              child: FloatingQuickNotes(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(FloatingQuickNotes));
    expect(size.width, closeTo(620, 0.01));
    expect(size.height, closeTo(560, 0.01));
  });
}
