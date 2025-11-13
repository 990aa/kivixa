import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/calendar_event.dart';

void main() {
  group('CalendarEvent', () {
    test('should create event with all properties', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Test Event',
        description: 'Test Description',
        date: DateTime(2025, 1, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 30),
        isAllDay: false,
        type: EventType.event,
        meetingLink: 'https://example.com/meet',
      );

      expect(event.id, 'test-id');
      expect(event.title, 'Test Event');
      expect(event.description, 'Test Description');
      expect(event.date, DateTime(2025, 1, 15));
      expect(event.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(event.endTime, const TimeOfDay(hour: 10, minute: 30));
      expect(event.isAllDay, false);
      expect(event.type, EventType.event);
      expect(event.meetingLink, 'https://example.com/meet');
    });

    test('should create all-day task without times', () {
      final task = CalendarEvent(
        id: 'task-id',
        title: 'Test Task',
        description: null,
        date: DateTime(2025, 1, 16),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.task,
        meetingLink: null,
      );

      expect(task.title, 'Test Task');
      expect(task.description, null);
      expect(task.startTime, null);
      expect(task.endTime, null);
      expect(task.isAllDay, true);
      expect(task.type, EventType.task);
      expect(task.meetingLink, null);
    });

    test('toJson should serialize event correctly', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Test Event',
        description: 'Test Description',
        date: DateTime(2025, 1, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 30),
        isAllDay: false,
        type: EventType.event,
        meetingLink: 'https://example.com/meet',
      );

      final json = event.toJson();

      expect(json['id'], 'test-id');
      expect(json['title'], 'Test Event');
      expect(json['description'], 'Test Description');
      expect(json['date'], DateTime(2025, 1, 15).toIso8601String());
      expect(json['startTime'], {'hour': 9, 'minute': 0});
      expect(json['endTime'], {'hour': 10, 'minute': 30});
      expect(json['isAllDay'], false);
      expect(json['type'], 'event');
      expect(json['meetingLink'], 'https://example.com/meet');
    });

    test('toJson should handle null optional fields', () {
      final event = CalendarEvent(
        id: 'test-id',
        title: 'Test Event',
        description: null,
        date: DateTime(2025, 1, 15),
        startTime: null,
        endTime: null,
        isAllDay: true,
        type: EventType.task,
        meetingLink: null,
      );

      final json = event.toJson();

      expect(json['description'], null);
      expect(json['startTime'], null);
      expect(json['endTime'], null);
      expect(json['meetingLink'], null);
      expect(json['type'], 'task');
    });

    test('fromJson should deserialize event correctly', () {
      final json = {
        'id': 'test-id',
        'title': 'Test Event',
        'description': 'Test Description',
        'date': DateTime(2025, 1, 15).toIso8601String(),
        'startTime': {'hour': 9, 'minute': 0},
        'endTime': {'hour': 10, 'minute': 30},
        'isAllDay': false,
        'type': 'event',
        'meetingLink': 'https://example.com/meet',
      };

      final event = CalendarEvent.fromJson(json);

      expect(event.id, 'test-id');
      expect(event.title, 'Test Event');
      expect(event.description, 'Test Description');
      expect(event.date, DateTime(2025, 1, 15));
      expect(event.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(event.endTime, const TimeOfDay(hour: 10, minute: 30));
      expect(event.isAllDay, false);
      expect(event.type, EventType.event);
      expect(event.meetingLink, 'https://example.com/meet');
    });

    test('fromJson should handle null optional fields', () {
      final json = {
        'id': 'test-id',
        'title': 'Test Task',
        'description': null,
        'date': DateTime(2025, 1, 15).toIso8601String(),
        'startTime': null,
        'endTime': null,
        'isAllDay': true,
        'type': 'task',
        'meetingLink': null,
      };

      final event = CalendarEvent.fromJson(json);

      expect(event.title, 'Test Task');
      expect(event.description, null);
      expect(event.startTime, null);
      expect(event.endTime, null);
      expect(event.isAllDay, true);
      expect(event.type, EventType.task);
      expect(event.meetingLink, null);
    });

    test('fromJson should parse task type correctly', () {
      final json = {
        'id': 'test-id',
        'title': 'Test Task',
        'description': null,
        'date': DateTime(2025, 1, 15).toIso8601String(),
        'startTime': null,
        'endTime': null,
        'isAllDay': true,
        'type': 'task',
        'meetingLink': null,
      };

      final event = CalendarEvent.fromJson(json);

      expect(event.type, EventType.task);
    });

    test('copyWith should create new instance with updated fields', () {
      final original = CalendarEvent(
        id: 'test-id',
        title: 'Original Title',
        description: 'Original Description',
        date: DateTime(2025, 1, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        isAllDay: false,
        type: EventType.event,
        meetingLink: 'https://example.com/original',
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        startTime: const TimeOfDay(hour: 10, minute: 0),
      );

      expect(updated.id, 'test-id');
      expect(updated.title, 'Updated Title');
      expect(updated.description, 'Original Description');
      expect(updated.startTime, const TimeOfDay(hour: 10, minute: 0));
      expect(updated.endTime, const TimeOfDay(hour: 10, minute: 0));
      expect(updated.meetingLink, 'https://example.com/original');
    });

    test('toJson and fromJson should be reversible', () {
      final original = CalendarEvent(
        id: 'test-id',
        title: 'Test Event',
        description: 'Test Description',
        date: DateTime(2025, 1, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 30),
        isAllDay: false,
        type: EventType.event,
        meetingLink: 'https://example.com/meet',
      );

      final json = original.toJson();
      final restored = CalendarEvent.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.date, original.date);
      expect(restored.startTime, original.startTime);
      expect(restored.endTime, original.endTime);
      expect(restored.isAllDay, original.isAllDay);
      expect(restored.type, original.type);
      expect(restored.meetingLink, original.meetingLink);
    });
  });
}
