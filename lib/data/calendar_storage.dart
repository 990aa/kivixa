import 'dart:convert';

import 'package:kivixa/data/models/calendar_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarStorage {
  static const _eventsKey = 'calendar_events';

  static Future<List<CalendarEvent>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString(_eventsKey);
    if (eventsJson == null) return [];

    final List<dynamic> decoded = json.decode(eventsJson);
    return decoded.map((e) => CalendarEvent.fromJson(e)).toList();
  }

  static Future<void> saveEvents(List<CalendarEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(events.map((e) => e.toJson()).toList());
    await prefs.setString(_eventsKey, encoded);
  }

  static Future<void> addEvent(CalendarEvent event) async {
    final events = await loadEvents();
    events.add(event);
    await saveEvents(events);
  }

  static Future<void> updateEvent(CalendarEvent event) async {
    final events = await loadEvents();
    final index = events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      events[index] = event;
      await saveEvents(events);
    }
  }

  static Future<void> deleteEvent(String eventId) async {
    final events = await loadEvents();
    events.removeWhere((e) => e.id == eventId);
    await saveEvents(events);
  }

  static Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    final events = await loadEvents();
    return events.where((e) => e.occursOn(date)).toList();
  }

  static Future<List<CalendarEvent>> getEventsForMonth(
    int year,
    int month,
  ) async {
    final events = await loadEvents();
    final result = <CalendarEvent>[];

    // Check each day of the month
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    for (
      var day = firstDay;
      day.isBefore(lastDay.add(const Duration(days: 1)));
      day = day.add(const Duration(days: 1))
    ) {
      for (final event in events) {
        if (event.occursOn(day) &&
            !result.any((e) => e.id == event.id && e.date == event.date)) {
          result.add(event);
        }
      }
    }

    return result;
  }
}
