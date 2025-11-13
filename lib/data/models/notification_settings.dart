import 'dart:convert';

class NotificationSettings {
  NotificationSettings({
    this.notificationsEnabled = true,
    this.eventNotificationsEnabled = true,
    this.taskNotificationsEnabled = true,
    this.overdueNotificationsEnabled = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      eventNotificationsEnabled:
          json['eventNotificationsEnabled'] as bool? ?? true,
      taskNotificationsEnabled:
          json['taskNotificationsEnabled'] as bool? ?? true,
      overdueNotificationsEnabled:
          json['overdueNotificationsEnabled'] as bool? ?? true,
    );
  }

  final bool notificationsEnabled;
  final bool eventNotificationsEnabled;
  final bool taskNotificationsEnabled;
  final bool overdueNotificationsEnabled;

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'eventNotificationsEnabled': eventNotificationsEnabled,
      'taskNotificationsEnabled': taskNotificationsEnabled,
      'overdueNotificationsEnabled': overdueNotificationsEnabled,
    };
  }

  NotificationSettings copyWith({
    bool? notificationsEnabled,
    bool? eventNotificationsEnabled,
    bool? taskNotificationsEnabled,
    bool? overdueNotificationsEnabled,
  }) {
    return NotificationSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      eventNotificationsEnabled:
          eventNotificationsEnabled ?? this.eventNotificationsEnabled,
      taskNotificationsEnabled:
          taskNotificationsEnabled ?? this.taskNotificationsEnabled,
      overdueNotificationsEnabled:
          overdueNotificationsEnabled ?? this.overdueNotificationsEnabled,
    );
  }

  String toJsonString() => json.encode(toJson());

  static NotificationSettings fromJsonString(String jsonString) {
    return NotificationSettings.fromJson(json.decode(jsonString));
  }
}
