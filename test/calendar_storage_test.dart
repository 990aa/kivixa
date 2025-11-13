import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/calendar_storage.dart';
import 'package:kivixa/data/models/calendar_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CalendarStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loadEvents should return empty list when no events exist', () async {
      final events = await CalendarStorage.loadEvents();
      expect(events, isEmpty);
    });

    test('saveEvents should persist events to SharedPreferences', () async {
      final events = [
        CalendarEvent(
          id: 'event-1',
          title: 'Event 1',
          description: 'Description 1',
          date: DateTime(2025, 1, 15),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
          isAllDay: false,
          type: EventType.event,
          meetingLink: null,
        ),
        CalendarEvent(
          id: 'event-2',
          title: 'Event 2',
          description: null,
          date: DateTime(2025, 1, 16),
          startTime: null,
          endTime: null,
          isAllDay: true,
          type: EventType.task,
          meetingLink: null,
        ),
      ];

      await CalendarStorage.saveEvents(events);
      final loaded = await CalendarStorage.loadEvents();

      expect(loaded.length, 2);
      expect(loaded[0].id, 'event-1');
      expect(loaded[1].id, 'event-2');
    });

    test('addEvent should add new event to existing events', () async {
      final event1 = CalendarEvent(
        id: 'event-1',
        title: 'Event 1',
        description: null,
        date: DateTime(2025, 1, 15),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
      );

      await CalendarStorage.addEvent(event1);
      var events = await CalendarStorage.loadEvents();
      expect(events.length, 1);
      expect(events[0].id, 'event-1');

      final event2 = CalendarEvent(
        id: 'event-2',
        title: 'Event 2',
        description: null,
        date: DateTime(2025, 1, 16),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.task,
        meetingLink: null,
      );

      await CalendarStorage.addEvent(event2);
      events = await CalendarStorage.loadEvents();
      expect(events.length, 2);
      expect(events[1].id, 'event-2');
    });

    test('updateEvent should update existing event', () async {
      final original = CalendarEvent(
        id: 'event-1',
        title: 'Original Title',
        description: 'Original Description',
        date: DateTime(2025, 1, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        isAllDay: false,
        type: EventType.event,
        meetingLink: null,
      );

      await CalendarStorage.addEvent(original);

      final updated = original.copyWith(
        title: 'Updated Title',
        description: 'Updated Description',
      );

      await CalendarStorage.updateEvent(updated);
      final events = await CalendarStorage.loadEvents();

      expect(events.length, 1);
      expect(events[0].id, 'event-1');
      expect(events[0].title, 'Updated Title');
      expect(events[0].description, 'Updated Description');
    });

    test('deleteEvent should remove event by id', () async {
      final event1 = CalendarEvent(
        id: 'event-1',
        title: 'Event 1',
        description: null,
        date: DateTime(2025, 1, 15),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
      );

      final event2 = CalendarEvent(
        id: 'event-2',
        title: 'Event 2',
        description: null,
        date: DateTime(2025, 1, 16),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.task,
        meetingLink: null,
      );

      await CalendarStorage.addEvent(event1);
      await CalendarStorage.addEvent(event2);

      await CalendarStorage.deleteEvent('event-1');
      final events = await CalendarStorage.loadEvents();

      expect(events.length, 1);
      expect(events[0].id, 'event-2');
    });

    test(
      'getEventsForDate should return only events on specific date',
      () async {
        final date1 = DateTime(2025, 1, 15);
        final date2 = DateTime(2025, 1, 16);

        final event1 = CalendarEvent(
          id: 'event-1',
          title: 'Event on 15th',
          description: null,
          date: date1,
          startTime: null,
          endTime: null,
          isAllDay: true,
          type: EventType.event,
          meetingLink: null,
        );

        final event2 = CalendarEvent(
          id: 'event-2',
          title: 'Event on 16th',
          description: null,
          date: date2,
          startTime: null,
          endTime: null,
          isAllDay: true,
          type: EventType.task,
          meetingLink: null,
        );

        final event3 = CalendarEvent(
          id: 'event-3',
          title: 'Another event on 15th',
          description: null,
          date: date1,
          startTime: null,
          endTime: null,
          isAllDay: true,
          type: EventType.event,
          meetingLink: null,
        );

        await CalendarStorage.addEvent(event1);
        await CalendarStorage.addEvent(event2);
        await CalendarStorage.addEvent(event3);

        final eventsOn15th = await CalendarStorage.getEventsForDate(date1);
        expect(eventsOn15th.length, 2);
        expect(eventsOn15th[0].title, 'Event on 15th');
        expect(eventsOn15th[1].title, 'Another event on 15th');

        final eventsOn16th = await CalendarStorage.getEventsForDate(date2);
        expect(eventsOn16th.length, 1);
        expect(eventsOn16th[0].title, 'Event on 16th');
      },
    );

    test(
      'getEventsForMonth should return only events in specific month',
      () async {
        final event1 = CalendarEvent(
          id: 'event-1',
          title: 'Event in January',
          description: null,
          date: DateTime(2025, 1, 15),
          startTime: null,
          endTime: null,
          isAllDay: true,
          type: EventType.event,
          meetingLink: null,
        );

        final event2 = CalendarEvent(
          id: 'event-2',
          title: 'Event in February',
          description: null,
          date: DateTime(2025, 2, 10),
          startTime: null,
          endTime: null,
          isAllDay: true,
          type: EventType.task,
          meetingLink: null,
        );

        final event3 = CalendarEvent(
          id: 'event-3',
          title: 'Another event in January',
          description: null,
          date: DateTime(2025, 1, 20),
          startTime: null,
          endTime: null,
          isAllDay: true,
          type: EventType.event,
          meetingLink: null,
        );

        await CalendarStorage.addEvent(event1);
        await CalendarStorage.addEvent(event2);
        await CalendarStorage.addEvent(event3);

        final januaryEvents = await CalendarStorage.getEventsForMonth(2025, 1);
        expect(januaryEvents.length, 2);
        expect(januaryEvents[0].title, 'Event in January');
        expect(januaryEvents[1].title, 'Another event in January');

        final februaryEvents = await CalendarStorage.getEventsForMonth(2025, 2);
        expect(februaryEvents.length, 1);
        expect(februaryEvents[0].title, 'Event in February');
      },
    );

    test(
      'getEventsForMonth should filter by year and month correctly',
      () async {
        final event2024 = CalendarEvent(
          id: 'event-2024',
          title: 'Event in 2024 January',
          description: null,
          date: DateTime(2024, 1, 15),
          startTime: null,
          endTime: null,
          isAllDay: true,
          type: EventType.event,
          meetingLink: null,
        );

        final event2025 = CalendarEvent(
          id: 'event-2025',
          title: 'Event in 2025 January',
          description: null,
          date: DateTime(2025, 1, 15),
          startTime: null,
          endTime: null,
          isAllDay: true,
          type: EventType.event,
          meetingLink: null,
        );

        await CalendarStorage.addEvent(event2024);
        await CalendarStorage.addEvent(event2025);

        final events2024 = await CalendarStorage.getEventsForMonth(2024, 1);
        expect(events2024.length, 1);
        expect(events2024[0].id, 'event-2024');

        final events2025 = await CalendarStorage.getEventsForMonth(2025, 1);
        expect(events2025.length, 1);
        expect(events2025[0].id, 'event-2025');
      },
    );
  });
}
