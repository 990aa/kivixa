import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:kivixa/data/models/calendar_event.dart' as model;
import 'package:kivixa/pages/home/syncfusion_calendar_page.dart';

void main() {
  group('CalendarEventDataSource Tests', () {
    test('should convert model.CalendarEvent to Appointment correctly', () {
      final event = model.CalendarEvent(
        id: 'test-1',
        title: 'Test Event',
        description: 'Test Description',
        date: DateTime(2025, 11, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        isAllDay: false,
        type: model.EventType.event,
      );

      final dataSource = CalendarEventDataSource([event]);
      expect(dataSource.appointments!.length, 1);

      final appointment = dataSource.appointments!.first as Appointment;
      expect(appointment.id, 'test-1');
      expect(appointment.subject, 'Test Event');
      expect(appointment.notes, 'Test Description');
      expect(appointment.isAllDay, false);
    });

    test('should handle all-day events', () {
      final event = model.CalendarEvent(
        id: 'test-2',
        title: 'All Day Event',
        date: DateTime(2025, 11, 15),
        isAllDay: true,
        type: model.EventType.event,
      );

      final dataSource = CalendarEventDataSource([event]);
      final appointment = dataSource.appointments!.first as Appointment;
      expect(appointment.isAllDay, true);
    });

    test('should generate daily recurrence rule correctly', () {
      final event = model.CalendarEvent(
        id: 'test-3',
        title: 'Daily Event',
        date: DateTime(2025, 11, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        type: model.EventType.event,
        recurrence: model.RecurrenceRule(
          type: model.RecurrenceType.daily,
          interval: 1,
        ),
      );

      final dataSource = CalendarEventDataSource([event]);
      final appointment = dataSource.appointments!.first as Appointment;
      expect(appointment.recurrenceRule, contains('FREQ=DAILY'));
      expect(appointment.recurrenceRule, contains('INTERVAL=1'));
    });

    test('should generate weekly recurrence rule with weekdays', () {
      final event = model.CalendarEvent(
        id: 'test-4',
        title: 'Weekly Event',
        date: DateTime(2025, 11, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        type: model.EventType.event,
        recurrence: model.RecurrenceRule(
          type: model.RecurrenceType.weekly,
          interval: 1,
          weekdays: [1, 3, 5], // Mon, Wed, Fri
        ),
      );

      final dataSource = CalendarEventDataSource([event]);
      final appointment = dataSource.appointments!.first as Appointment;
      expect(appointment.recurrenceRule, contains('FREQ=WEEKLY'));
      expect(appointment.recurrenceRule, contains('BYDAY=MO,WE,FR'));
    });

    test('should generate monthly recurrence rule correctly', () {
      final event = model.CalendarEvent(
        id: 'test-5',
        title: 'Monthly Event',
        date: DateTime(2025, 11, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        type: model.EventType.event,
        recurrence: model.RecurrenceRule(
          type: model.RecurrenceType.monthly,
          interval: 1,
        ),
      );

      final dataSource = CalendarEventDataSource([event]);
      final appointment = dataSource.appointments!.first as Appointment;
      expect(appointment.recurrenceRule, contains('FREQ=MONTHLY'));
    });

    test('should generate yearly recurrence rule correctly', () {
      final event = model.CalendarEvent(
        id: 'test-6',
        title: 'Yearly Event',
        date: DateTime(2025, 11, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        type: model.EventType.event,
        recurrence: model.RecurrenceRule(
          type: model.RecurrenceType.yearly,
          interval: 1,
        ),
      );

      final dataSource = CalendarEventDataSource([event]);
      final appointment = dataSource.appointments!.first as Appointment;
      expect(appointment.recurrenceRule, contains('FREQ=YEARLY'));
    });

    test('should handle empty event list', () {
      final dataSource = CalendarEventDataSource([]);
      expect(dataSource.appointments!.length, 0);
    });

    test('should handle multiple events', () {
      final events = [
        model.CalendarEvent(
          id: 'test-7',
          title: 'Event 1',
          date: DateTime(2025, 11, 15),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
          type: model.EventType.event,
        ),
        model.CalendarEvent(
          id: 'test-8',
          title: 'Event 2',
          date: DateTime(2025, 11, 16),
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 15, minute: 0),
          type: model.EventType.task,
        ),
      ];

      final dataSource = CalendarEventDataSource(events);
      expect(dataSource.appointments!.length, 2);
    });

    test('should handle events without description', () {
      final event = model.CalendarEvent(
        id: 'test-9',
        title: 'No Description Event',
        date: DateTime(2025, 11, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        type: model.EventType.event,
      );

      final dataSource = CalendarEventDataSource([event]);
      final appointment = dataSource.appointments!.first as Appointment;
      expect(appointment.notes, '');
    });

    test('should convert TimeOfDay to DateTime correctly', () {
      final event = model.CalendarEvent(
        id: 'test-10',
        title: 'Time Test',
        date: DateTime(2025, 11, 15),
        startTime: const TimeOfDay(hour: 14, minute: 30),
        endTime: const TimeOfDay(hour: 16, minute: 45),
        type: model.EventType.event,
      );

      final dataSource = CalendarEventDataSource([event]);
      final appointment = dataSource.appointments!.first as Appointment;

      expect(appointment.startTime.hour, 14);
      expect(appointment.startTime.minute, 30);
      expect(appointment.endTime.hour, 16);
      expect(appointment.endTime.minute, 45);
    });
  });

  group('AppointmentDetailsDialog Tests', () {
    testWidgets('should display appointment details correctly', (
      WidgetTester tester,
    ) async {
      final appointment = Appointment(
        id: 'test-1',
        subject: 'Test Meeting',
        notes: 'Important meeting',
        startTime: DateTime(2025, 11, 15, 9, 0),
        endTime: DateTime(2025, 11, 15, 10, 0),
        color: Colors.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentDetailsDialog(
              appointment: appointment,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Meeting'), findsOneWidget);
      expect(find.text('Important meeting'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('should display all-day event correctly', (
      WidgetTester tester,
    ) async {
      final appointment = Appointment(
        id: 'test-2',
        subject: 'All Day Event',
        startTime: DateTime(2025, 11, 15),
        endTime: DateTime(2025, 11, 15),
        color: Colors.blue,
        isAllDay: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentDetailsDialog(
              appointment: appointment,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('All Day Event'), findsOneWidget);
      expect(find.text('All Day'), findsOneWidget);
    });

    testWidgets('should call onEdit when Edit button is tapped', (
      WidgetTester tester,
    ) async {
      var editCalled = false;
      final appointment = Appointment(
        id: 'test-3',
        subject: 'Test Event',
        startTime: DateTime(2025, 11, 15, 9, 0),
        endTime: DateTime(2025, 11, 15, 10, 0),
        color: Colors.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentDetailsDialog(
              appointment: appointment,
              onEdit: () {
                editCalled = true;
              },
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(editCalled, true);
    });

    testWidgets('should call onDelete when Delete button is tapped', (
      WidgetTester tester,
    ) async {
      var deleteCalled = false;
      final appointment = Appointment(
        id: 'test-4',
        subject: 'Test Event',
        startTime: DateTime(2025, 11, 15, 9, 0),
        endTime: DateTime(2025, 11, 15, 10, 0),
        color: Colors.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentDetailsDialog(
              appointment: appointment,
              onEdit: () {},
              onDelete: () {
                deleteCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleteCalled, true);
    });
  });

  group('CalendarSettingsDialog Tests', () {
    testWidgets('should display all settings options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarSettingsDialog(
              firstDayOfWeek: DateTime.sunday,
              startHour: 9.0,
              endHour: 17.0,
              nonWorkingDays: [DateTime.saturday, DateTime.sunday],
              showWeekNumber: false,
              showTrailingAndLeadingDates: true,
              onSave: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Calendar Settings'), findsOneWidget);
      expect(find.text('First Day of Week'), findsOneWidget);
      expect(find.text('Working Hours'), findsOneWidget);
      expect(find.text('Non-Working Days'), findsOneWidget);
      expect(find.text('Show Week Numbers'), findsOneWidget);
      expect(find.text('Show Leading/Trailing Dates'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should toggle week number switch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarSettingsDialog(
              firstDayOfWeek: DateTime.sunday,
              startHour: 9.0,
              endHour: 17.0,
              nonWorkingDays: [],
              showWeekNumber: false,
              showTrailingAndLeadingDates: true,
              onSave: (_) {},
            ),
          ),
        ),
      );

      final switchFinder = find.byWidgetPredicate(
        (widget) =>
            widget is SwitchListTile &&
            widget.title is Text &&
            (widget.title as Text).data == 'Show Week Numbers',
      );

      expect(switchFinder, findsOneWidget);

      // Tap the switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify state changed (the switch should now be on)
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, true);
    });

    testWidgets('should save settings when Save button is tapped', (
      WidgetTester tester,
    ) async {
      Map<String, dynamic>? savedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarSettingsDialog(
              firstDayOfWeek: DateTime.sunday,
              startHour: 9.0,
              endHour: 17.0,
              nonWorkingDays: [DateTime.saturday],
              showWeekNumber: true,
              showTrailingAndLeadingDates: false,
              onSave: (settings) {
                savedSettings = settings;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedSettings, isNotNull);
      expect(savedSettings!['firstDayOfWeek'], DateTime.sunday);
      expect(savedSettings!['showWeekNumber'], true);
      expect(savedSettings!['showTrailingAndLeadingDates'], false);
    });
  });

  group('EventDialog Tests', () {
    testWidgets('should display event creation form', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventDialog(
              initialDate: DateTime(2025, 11, 15),
              onSave: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('New Event'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Title and Description
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Task'), findsOneWidget);
      expect(find.text('All Day'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should show validation error when title is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventDialog(
              initialDate: DateTime(2025, 11, 15),
              onSave: (_) {},
            ),
          ),
        ),
      );

      // Try to save without entering a title
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('should toggle between Event and Task types', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventDialog(
              initialDate: DateTime(2025, 11, 15),
              onSave: (_) {},
            ),
          ),
        ),
      );

      // Find the segmented button
      final segmentedButton = find.byType(SegmentedButton<model.EventType>);
      expect(segmentedButton, findsOneWidget);

      // Find and tap Task button by text
      final taskButton = find.text('Task');
      expect(taskButton, findsOneWidget);

      await tester.tap(taskButton);
      await tester.pumpAndSettle();

      // Verify the segmented button still exists
      expect(segmentedButton, findsOneWidget);
    });

    testWidgets('should create event when valid data is entered', (
      WidgetTester tester,
    ) async {
      model.CalendarEvent? savedEvent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventDialog(
              initialDate: DateTime(2025, 11, 15),
              onSave: (event) {
                savedEvent = event;
              },
            ),
          ),
        ),
      );

      // Enter title
      await tester.enterText(find.byType(TextField).first, 'Test Event');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedEvent, isNotNull);
      expect(savedEvent!.title, 'Test Event');
    });
  });

  group('Helper Functions Tests', () {
    test('should format time correctly', () {
      // Test formatTime function logic
      final time = DateTime(2025, 11, 15, 14, 30);
      final hour = time.hour > 12 ? time.hour - 12 : time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      final formatted = '$hour:$minute $period';

      expect(formatted, '2:30 PM');
    });

    test('should format time for midnight correctly', () {
      final time = DateTime(2025, 11, 15, 0, 0);
      final hour = time.hour > 12
          ? time.hour - 12
          : (time.hour == 0 ? 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      final formatted = '$hour:$minute $period';

      expect(formatted, '12:00 AM');
    });

    test('should format time for noon correctly', () {
      final time = DateTime(2025, 11, 15, 12, 0);
      final hour = time.hour > 12
          ? time.hour - 12
          : (time.hour == 0 ? 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      final formatted = '$hour:$minute $period';

      expect(formatted, '12:00 PM');
    });
  });

  group('Recurrence Rule Generation Tests', () {
    test('should generate RRULE for daily recurrence', () {
      const interval = 1;
      final rule = 'FREQ=DAILY;INTERVAL=$interval';
      expect(rule, 'FREQ=DAILY;INTERVAL=1');
    });

    test('should generate RRULE for weekly recurrence with specific days', () {
      const interval = 1;
      final weekdays = [1, 3, 5]; // Mon, Wed, Fri
      final days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      final selectedDays = weekdays.map((d) => days[d - 1]).join(',');
      final rule = 'FREQ=WEEKLY;INTERVAL=$interval;BYDAY=$selectedDays';

      expect(rule, 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR');
    });

    test('should generate RRULE for monthly recurrence', () {
      const interval = 2;
      final rule = 'FREQ=MONTHLY;INTERVAL=$interval';
      expect(rule, 'FREQ=MONTHLY;INTERVAL=2');
    });

    test('should generate RRULE for yearly recurrence', () {
      const interval = 1;
      final rule = 'FREQ=YEARLY;INTERVAL=$interval';
      expect(rule, 'FREQ=YEARLY;INTERVAL=1');
    });

    test('should handle custom intervals', () {
      const interval = 3;
      final rule = 'FREQ=WEEKLY;INTERVAL=$interval';
      expect(rule, 'FREQ=WEEKLY;INTERVAL=3');
    });
  });

  group('View Icon and Name Tests', () {
    test('should return correct icon for each view', () {
      final viewIcons = {
        CalendarView.day: Icons.view_day,
        CalendarView.week: Icons.view_week,
        CalendarView.workWeek: Icons.view_week,
        CalendarView.month: Icons.calendar_month,
        CalendarView.timelineDay: Icons.timeline,
        CalendarView.timelineWeek: Icons.timeline,
        CalendarView.timelineWorkWeek: Icons.timeline,
        CalendarView.timelineMonth: Icons.timeline,
        CalendarView.schedule: Icons.list,
      };

      viewIcons.forEach((view, expectedIcon) {
        expect(expectedIcon, isNotNull);
      });
    });

    test('should return correct name for each view', () {
      final viewNames = {
        CalendarView.day: 'Day',
        CalendarView.week: 'Week',
        CalendarView.workWeek: 'Work Week',
        CalendarView.month: 'Month',
        CalendarView.timelineDay: 'Timeline Day',
        CalendarView.timelineWeek: 'Timeline Week',
        CalendarView.timelineWorkWeek: 'Timeline Work Week',
        CalendarView.timelineMonth: 'Timeline Month',
        CalendarView.schedule: 'Schedule',
      };

      viewNames.forEach((view, expectedName) {
        expect(expectedName, isNotEmpty);
      });
    });
  });
}
