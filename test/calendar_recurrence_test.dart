import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/calendar_event.dart';

void main() {
  group('RecurrenceRule', () {
    test('should serialize and deserialize correctly', () {
      final rule = RecurrenceRule(
        type: RecurrenceType.weekly,
        interval: 2,
        weekdays: [1, 3, 5], // Monday, Wednesday, Friday
        endDate: DateTime(2025, 12, 31),
      );

      final json = rule.toJson();
      final restored = RecurrenceRule.fromJson(json);

      expect(restored.type, RecurrenceType.weekly);
      expect(restored.interval, 2);
      expect(restored.weekdays, [1, 3, 5]);
      expect(restored.endDate, DateTime(2025, 12, 31));
    });

    test('should handle null optional fields in JSON', () {
      final rule = RecurrenceRule(type: RecurrenceType.daily, interval: 1);

      final json = rule.toJson();
      final restored = RecurrenceRule.fromJson(json);

      expect(restored.weekdays, null);
      expect(restored.endDate, null);
      expect(restored.monthDay, null);
      expect(restored.nthWeekday, null);
    });
  });

  group('CalendarEvent with recurrence', () {
    test('should serialize recurrence correctly', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Recurring Meeting',
        description: 'Weekly team sync',
        date: DateTime(2025, 1, 1),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        isAllDay: false,
        type: EventType.event,
        meetingLink: 'https://meet.example.com',
        recurrence: RecurrenceRule(
          type: RecurrenceType.weekly,
          interval: 1,
          weekdays: [1, 3, 5],
        ),
      );

      final json = event.toJson();
      expect(json['recurrence'], isNotNull);
      expect(json['recurrence']['type'], 'weekly');

      final restored = CalendarEvent.fromJson(json);
      expect(restored.recurrence, isNotNull);
      expect(restored.recurrence!.type, RecurrenceType.weekly);
      expect(restored.recurrence!.weekdays, [1, 3, 5]);
    });

    test('should handle events without recurrence', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'One-time Event',
        description: null,
        date: DateTime(2025, 1, 1),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
        recurrence: null,
      );

      final json = event.toJson();
      expect(json['recurrence'], null);

      final restored = CalendarEvent.fromJson(json);
      expect(restored.recurrence, null);
    });
  });

  group('CalendarEvent.occursOn()', () {
    test('should return true for event date when no recurrence', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Event',
        description: null,
        date: DateTime(2025, 1, 15),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
      );

      expect(event.occursOn(DateTime(2025, 1, 15)), true);
      expect(event.occursOn(DateTime(2025, 1, 16)), false);
    });

    test('should handle daily recurrence', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Daily Event',
        description: null,
        date: DateTime(2025, 1, 1),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
        recurrence: RecurrenceRule(type: RecurrenceType.daily, interval: 1),
      );

      expect(event.occursOn(DateTime(2025, 1, 1)), true);
      expect(event.occursOn(DateTime(2025, 1, 2)), true);
      expect(event.occursOn(DateTime(2025, 1, 15)), true);
      expect(event.occursOn(DateTime(2024, 12, 31)), false); // Before start
    });

    test('should handle daily recurrence with interval', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Every 3 Days',
        description: null,
        date: DateTime(2025, 1, 1),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
        recurrence: RecurrenceRule(type: RecurrenceType.daily, interval: 3),
      );

      expect(event.occursOn(DateTime(2025, 1, 1)), true); // Day 0
      expect(event.occursOn(DateTime(2025, 1, 2)), false);
      expect(event.occursOn(DateTime(2025, 1, 3)), false);
      expect(event.occursOn(DateTime(2025, 1, 4)), true); // Day 3
      expect(event.occursOn(DateTime(2025, 1, 7)), true); // Day 6
    });

    test('should handle weekly recurrence on same weekday', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Weekly Event',
        description: null,
        date: DateTime(2025, 1, 6), // Monday
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
        recurrence: RecurrenceRule(type: RecurrenceType.weekly, interval: 1),
      );

      expect(event.occursOn(DateTime(2025, 1, 6)), true); // First Monday
      expect(event.occursOn(DateTime(2025, 1, 13)), true); // Second Monday
      expect(event.occursOn(DateTime(2025, 1, 20)), true); // Third Monday
      expect(event.occursOn(DateTime(2025, 1, 7)), false); // Tuesday
    });

    test('should handle weekly recurrence with specific weekdays', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'MWF Event',
        description: null,
        date: DateTime(2025, 1, 6), // Monday
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
        recurrence: RecurrenceRule(
          type: RecurrenceType.weekly,
          interval: 1,
          weekdays: [1, 3, 5], // Monday, Wednesday, Friday
        ),
      );

      expect(event.occursOn(DateTime(2025, 1, 6)), true); // Monday
      expect(event.occursOn(DateTime(2025, 1, 7)), false); // Tuesday
      expect(event.occursOn(DateTime(2025, 1, 8)), true); // Wednesday
      expect(event.occursOn(DateTime(2025, 1, 9)), false); // Thursday
      expect(event.occursOn(DateTime(2025, 1, 10)), true); // Friday
      expect(event.occursOn(DateTime(2025, 1, 11)), false); // Saturday
    });

    test('should handle monthly recurrence on same day', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Monthly Event',
        description: null,
        date: DateTime(2025, 1, 15),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
        recurrence: RecurrenceRule(type: RecurrenceType.monthly, interval: 1),
      );

      expect(event.occursOn(DateTime(2025, 1, 15)), true);
      expect(event.occursOn(DateTime(2025, 2, 15)), true);
      expect(event.occursOn(DateTime(2025, 3, 15)), true);
      expect(event.occursOn(DateTime(2025, 1, 16)), false);
    });

    test('should handle yearly recurrence', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Birthday',
        description: null,
        date: DateTime(2025, 6, 15),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
        recurrence: RecurrenceRule(type: RecurrenceType.yearly, interval: 1),
      );

      expect(event.occursOn(DateTime(2025, 6, 15)), true);
      expect(event.occursOn(DateTime(2026, 6, 15)), true);
      expect(event.occursOn(DateTime(2027, 6, 15)), true);
      expect(event.occursOn(DateTime(2025, 6, 16)), false);
      expect(event.occursOn(DateTime(2025, 7, 15)), false);
    });

    test('should respect recurrence end date', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Limited Recurrence',
        description: null,
        date: DateTime(2025, 1, 1),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
        recurrence: RecurrenceRule(
          type: RecurrenceType.daily,
          interval: 1,
          endDate: DateTime(2025, 1, 10),
        ),
      );

      expect(event.occursOn(DateTime(2025, 1, 1)), true);
      expect(event.occursOn(DateTime(2025, 1, 10)), true);
      expect(event.occursOn(DateTime(2025, 1, 11)), false); // After end date
    });

    test('should handle 2nd Saturday of month recurrence', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: '2nd Saturday',
        description: null,
        date: DateTime(2025, 1, 11), // 2nd Saturday of Jan 2025
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
        recurrence: RecurrenceRule(
          type: RecurrenceType.monthly,
          interval: 1,
          nthWeekday: 2, // 2nd occurrence
          nthWeekdayDay: 6, // Saturday (1=Mon, 6=Sat, 7=Sun)
        ),
      );

      expect(event.occursOn(DateTime(2025, 1, 11)), true); // 2nd Sat of Jan
      expect(event.occursOn(DateTime(2025, 1, 4)), false); // 1st Sat of Jan
      expect(event.occursOn(DateTime(2025, 1, 18)), false); // 3rd Sat of Jan
      expect(event.occursOn(DateTime(2025, 2, 8)), true); // 2nd Sat of Feb
    });

    test('should handle last weekday of month recurrence', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Last Friday',
        description: null,
        date: DateTime(2025, 1, 31), // Last Friday of Jan 2025
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
        recurrence: RecurrenceRule(
          type: RecurrenceType.monthly,
          interval: 1,
          nthWeekday: -1, // Last occurrence
          nthWeekdayDay: 5, // Friday
        ),
      );

      expect(event.occursOn(DateTime(2025, 1, 31)), true); // Last Fri of Jan
      expect(event.occursOn(DateTime(2025, 1, 24)), false); // 2nd to last Fri
      expect(event.occursOn(DateTime(2025, 2, 28)), true); // Last Fri of Feb
    });
  });

  group('CalendarEvent copyWith with recurrence', () {
    test('should copy event with updated recurrence', () {
      final original = CalendarEvent(
        id: 'test-id',
        title: 'Event',
        description: null,
        date: DateTime(2025, 1, 1),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.event,
        meetingLink: null,
        recurrence: RecurrenceRule(type: RecurrenceType.daily, interval: 1),
      );

      final updated = original.copyWith(
        recurrence: RecurrenceRule(
          type: RecurrenceType.weekly,
          interval: 1,
          weekdays: [1, 3, 5],
        ),
      );

      expect(updated.id, 'test-id');
      expect(updated.recurrence, isNotNull);
      expect(updated.recurrence!.type, RecurrenceType.weekly);
      expect(updated.recurrence!.weekdays, [1, 3, 5]);
    });
  });

  group('Event type and recurrence combinations', () {
    test('should support recurring tasks', () {
      final task = CalendarEvent(
        id: 'test-id',
        title: 'Daily Standup',
        description: null,
        date: DateTime(2025, 1, 6), // Monday
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 9, minute: 15),
        isAllDay: false,
        type: EventType.task,
        meetingLink: null,
        recurrence: RecurrenceRule(
          type: RecurrenceType.weekly,
          interval: 1,
          weekdays: [1, 2, 3, 4, 5], // Weekdays only (Mon-Fri)
        ),
      );

      expect(task.type, EventType.task);
      expect(task.recurrence, isNotNull);
      expect(task.occursOn(DateTime(2025, 1, 6)), true); // Monday
      expect(task.occursOn(DateTime(2025, 1, 7)), true); // Tuesday
      expect(task.occursOn(DateTime(2025, 1, 10)), true); // Friday
      expect(task.occursOn(DateTime(2025, 1, 11)), false); // Saturday
      expect(task.occursOn(DateTime(2025, 1, 13)), true); // Next Monday
    });

    test('should support recurring events with meeting links', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Weekly Review',
        description: 'Team review meeting',
        date: DateTime(2025, 1, 6), // Monday
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 15, minute: 0),
        isAllDay: false,
        type: EventType.event,
        meetingLink: 'https://meet.example.com/weekly-review',
        recurrence: RecurrenceRule(type: RecurrenceType.weekly, interval: 1),
      );

      expect(event.meetingLink, isNotNull);
      expect(event.recurrence, isNotNull);
      expect(event.occursOn(DateTime(2025, 1, 6)), true);
      expect(event.occursOn(DateTime(2025, 1, 13)), true);
    });
  });
}
