import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/calendar_storage.dart';
import 'package:kivixa/pages/home/syncfusion_calendar_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('EventDialog displays with wider constraints',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const EventDialog(
                      initialDate: null,
                      event: null,
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Find the ConstrainedBox with the dialog
    final constrainedBox = tester.widget<ConstrainedBox>(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(ConstrainedBox),
      ).first,
    );

    expect(constrainedBox.constraints.maxWidth, 600);
    expect(constrainedBox.constraints.minWidth, 500);
  });

  testWidgets('EventDialog has title field', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: null,
            event: null,
          ),
        ),
      ),
    );

    expect(
      find.widgetWithText(TextField, 'Event title'),
      findsOneWidget,
    );
  });

  testWidgets('EventDialog has date picker', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: DateTime(2024, 6, 15),
            event: null,
          ),
        ),
      ),
    );

    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Jun 15, 2024'), findsOneWidget);
  });

  testWidgets('EventDialog has start and end time pickers',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: DateTime(2024, 6, 15, 10, 30),
            event: null,
          ),
        ),
      ),
    );

    expect(find.text('Start Time'), findsOneWidget);
    expect(find.text('End Time'), findsOneWidget);
    expect(find.text('10:30 AM'), findsOneWidget);
    expect(find.text('11:30 AM'), findsOneWidget);
  });

  testWidgets('EventDialog has meeting link field',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: null,
            event: null,
          ),
        ),
      ),
    );

    final meetingLinkField = find.widgetWithText(TextField, 'Meeting Link (optional)');
    expect(meetingLinkField, findsOneWidget);

    final textField = tester.widget<TextField>(meetingLinkField);
    expect(textField.keyboardType, TextInputType.url);
  });

  testWidgets('EventDialog defaults to clicked date',
      (WidgetTester tester) async {
    final testDate = DateTime(2024, 12, 25, 14, 30);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: testDate,
            event: null,
          ),
        ),
      ),
    );

    // Check date display
    expect(find.text('Dec 25, 2024'), findsOneWidget);

    // Check time display (should be 2:30 PM and 3:30 PM)
    expect(find.textContaining('2:30 PM'), findsOneWidget);
    expect(find.textContaining('3:30 PM'), findsOneWidget);
  });

  testWidgets('EventDialog has Save button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: null,
            event: null,
          ),
        ),
      ),
    );

    final saveButton = find.widgetWithText(FilledButton, 'Save');
    expect(saveButton, findsOneWidget);
  });

  testWidgets('EventDialog has Cancel button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: null,
            event: null,
          ),
        ),
      ),
    );

    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
  });

  testWidgets('EventDialog has task toggle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: null,
            event: null,
          ),
        ),
      ),
    );

    expect(find.text('Is Task'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('Can enter text in title field', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: null,
            event: null,
          ),
        ),
      ),
    );

    final titleField = find.widgetWithText(TextField, 'Event title');
    await tester.enterText(titleField, 'Test Event');
    await tester.pump();

    expect(find.text('Test Event'), findsOneWidget);
  });

  testWidgets('Can enter meeting link', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: null,
            event: null,
          ),
        ),
      ),
    );

    final meetingLinkField = find.widgetWithText(TextField, 'Meeting Link (optional)');
    await tester.enterText(meetingLinkField, 'https://meet.example.com/abc123');
    await tester.pump();

    expect(find.text('https://meet.example.com/abc123'), findsOneWidget);
  });

  testWidgets('EventDialog loads existing event data',
      (WidgetTester tester) async {
    final existingEvent = Appointment(
      id: 'test-123',
      subject: 'Existing Event',
      startTime: DateTime(2024, 6, 15, 10, 0),
      endTime: DateTime(2024, 6, 15, 11, 0),
      notes: 'Test notes',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: null,
            event: existingEvent,
          ),
        ),
      ),
    );

    expect(find.text('Existing Event'), findsOneWidget);
    expect(find.text('Jun 15, 2024'), findsOneWidget);
    expect(find.text('10:00 AM'), findsOneWidget);
    expect(find.text('11:00 AM'), findsOneWidget);
  });

  testWidgets('Cancel button closes dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const EventDialog(
                      initialDate: null,
                      event: null,
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(EventDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(EventDialog), findsNothing);
  });

  testWidgets('Save button requires title', (WidgetTester tester) async {
    bool savedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const EventDialog(
                      initialDate: null,
                      event: null,
                    ),
                  ).then((_) {
                    savedCalled = true;
                  });
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Try to save without title
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Dialog should still be open (save validation failed)
    expect(find.byType(EventDialog), findsOneWidget);
    expect(savedCalled, false);
  });

  testWidgets('Task toggle changes state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: null,
            event: null,
          ),
        ),
      ),
    );

    final switchWidget = find.byType(Switch);
    final switchBefore = tester.widget<Switch>(switchWidget);

    expect(switchBefore.value, false);

    await tester.tap(switchWidget);
    await tester.pump();

    final switchAfter = tester.widget<Switch>(switchWidget);
    expect(switchAfter.value, true);
  });

  testWidgets('Time pickers open when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: DateTime(2024, 6, 15, 10, 0),
            event: null,
          ),
        ),
      ),
    );

    // Tap on start time
    await tester.tap(find.text('Start Time'));
    await tester.pumpAndSettle();

    // Time picker should appear
    expect(find.byType(TimePickerDialog), findsOneWidget);
  });

  testWidgets('Date picker opens when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventDialog(
            initialDate: DateTime(2024, 6, 15),
            event: null,
          ),
        ),
      ),
    );

    // Tap on date
    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();

    // Date picker should appear
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
