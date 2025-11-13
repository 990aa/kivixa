import 'package:flutter/material.dart';

enum EventType { event, task }

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
    );
  }
}
