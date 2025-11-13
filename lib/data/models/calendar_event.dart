import 'package:flutter/material.dart';

enum EventType { event, task }

enum RecurrenceType { none, daily, weekly, monthly, yearly, custom }

class RecurrenceRule {
  final RecurrenceType type;
  final int interval; // Every X days/weeks/months/years
  final List<int>? weekdays; // For weekly: 1=Monday, 7=Sunday
  final int? monthDay; // For monthly: day of month (1-31)
  final int? nthWeekday; // For monthly: nth occurrence (1-5, -1 for last)
  final int? nthWeekdayDay; // Which weekday (1=Monday, 7=Sunday)
  final DateTime? endDate;

  RecurrenceRule({
    required this.type,
    this.interval = 1,
    this.weekdays,
    this.monthDay,
    this.nthWeekday,
    this.nthWeekdayDay,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'interval': interval,
      'weekdays': weekdays,
      'monthDay': monthDay,
      'nthWeekday': nthWeekday,
      'nthWeekdayDay': nthWeekdayDay,
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      type: RecurrenceType.values.firstWhere((e) => e.name == json['type']),
      interval: json['interval'] as int? ?? 1,
      weekdays: (json['weekdays'] as List?)?.cast<int>(),
      monthDay: json['monthDay'] as int?,
      nthWeekday: json['nthWeekday'] as int?,
      nthWeekdayDay: json['nthWeekdayDay'] as int?,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
    );
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final EventType type;
  final String? meetingLink;
  final RecurrenceRule? recurrence;
  final bool isCompleted;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.type = EventType.event,
    this.meetingLink,
    this.recurrence,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': startTime != null
          ? {'hour': startTime!.hour, 'minute': startTime!.minute}
          : null,
      'endTime': endTime != null
          ? {'hour': endTime!.hour, 'minute': endTime!.minute}
          : null,
      'isAllDay': isAllDay,
      'type': type.name,
      'meetingLink': meetingLink,
      'recurrence': recurrence?.toJson(),
      'isCompleted': isCompleted,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] != null
          ? TimeOfDay(
              hour: (json['startTime'] as Map<String, dynamic>)['hour'] as int,
              minute:
                  (json['startTime'] as Map<String, dynamic>)['minute'] as int,
            )
          : null,
      endTime: json['endTime'] != null
          ? TimeOfDay(
              hour: (json['endTime'] as Map<String, dynamic>)['hour'] as int,
              minute:
                  (json['endTime'] as Map<String, dynamic>)['minute'] as int,
            )
          : null,
      isAllDay: json['isAllDay'] as bool? ?? false,
      type: EventType.values.firstWhere((e) => e.name == json['type']),
      meetingLink: json['meetingLink'] as String?,
      recurrence: json['recurrence'] != null
          ? RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isAllDay,
    EventType? type,
    String? meetingLink,
    RecurrenceRule? recurrence,
    bool? isCompleted,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      type: type ?? this.type,
      meetingLink: meetingLink ?? this.meetingLink,
      recurrence: recurrence ?? this.recurrence,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Check if this event occurs on a specific date based on recurrence rules
  bool occursOn(DateTime checkDate) {
    // Normalize dates to ignore time
    final eventDate = DateTime(date.year, date.month, date.day);
    final targetDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    // If no recurrence, simple date match
    if (recurrence == null || recurrence!.type == RecurrenceType.none) {
      return eventDate == targetDate;
    }

    // Check if target date is before event start or after recurrence end
    if (targetDate.isBefore(eventDate)) return false;
    if (recurrence!.endDate != null &&
        targetDate.isAfter(recurrence!.endDate!)) {
      return false;
    }

    final daysDiff = targetDate.difference(eventDate).inDays;

    switch (recurrence!.type) {
      case RecurrenceType.daily:
        return daysDiff % recurrence!.interval == 0;

      case RecurrenceType.weekly:
        if (daysDiff % (7 * recurrence!.interval) < 7 &&
            daysDiff % (7 * recurrence!.interval) >= 0) {
          if (recurrence!.weekdays != null) {
            return recurrence!.weekdays!.contains(targetDate.weekday);
          }
          return targetDate.weekday == eventDate.weekday;
        }
        return false;

      case RecurrenceType.monthly:
        if (recurrence!.nthWeekday != null) {
          // Nth weekday of month (e.g., 2nd Saturday)
          return _isNthWeekdayOfMonth(
            targetDate,
            recurrence!.nthWeekday!,
            recurrence!.nthWeekdayDay ?? eventDate.weekday,
          );
        }
        // Same day of month
        return targetDate.day == eventDate.day &&
            (targetDate.year - eventDate.year) * 12 +
                    (targetDate.month - eventDate.month) %
                        recurrence!.interval ==
                0;

      case RecurrenceType.yearly:
        return targetDate.month == eventDate.month &&
            targetDate.day == eventDate.day &&
            (targetDate.year - eventDate.year) % recurrence!.interval == 0;

      case RecurrenceType.none:
      case RecurrenceType.custom:
        return false;
    }
  }

  bool _isNthWeekdayOfMonth(DateTime date, int nth, int weekday) {
    if (date.weekday != weekday) return false;

    if (nth == -1) {
      // Last occurrence of weekday in month
      final nextWeek = date.add(const Duration(days: 7));
      return nextWeek.month != date.month;
    }

    // Count which occurrence this is
    var occurrence = 0;
    for (var day = 1; day <= date.day; day++) {
      final checkDate = DateTime(date.year, date.month, day);
      if (checkDate.weekday == weekday) {
        occurrence++;
      }
    }
    return occurrence == nth;
  }
}
