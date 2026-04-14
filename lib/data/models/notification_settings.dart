import 'dart:convert';

enum NotificationSoundProfile {
  defaultTone('default', 'Default'),
  alarm('alarm', 'Alarm'),
  ringtone('ringtone', 'Ringtone'),
  silent('silent', 'Silent');

  const NotificationSoundProfile(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static NotificationSoundProfile fromStorageKey(String? key) {
    for (final profile in NotificationSoundProfile.values) {
      if (profile.storageKey == key) {
        return profile;
      }
    }
    return NotificationSoundProfile.defaultTone;
  }
}

List<int> _sanitizeLeadTimes(List<dynamic>? rawLeadTimes) {
  final values = <int>{};
  for (final value in rawLeadTimes ?? const <dynamic>[]) {
    if (value is int && value > 0) {
      values.add(value);
    }
  }

  if (values.isEmpty) {
    values.addAll(const [10, 60, 1440]);
  }

  final sorted = values.toList()..sort();
  return sorted;
}

class NotificationSettings {
  NotificationSettings({
    this.notificationsEnabled = true,
    this.eventNotificationsEnabled = true,
    this.taskNotificationsEnabled = true,
    this.overdueNotificationsEnabled = true,
    this.projectDeadlineNotificationsEnabled = true,
    this.exactTimeNotificationsEnabled = true,
    this.soundProfile = NotificationSoundProfile.defaultTone,
    this.vibrateOnlyOnAndroid = false,
    List<int> leadTimesInMinutes = const [10, 60, 1440],
  }) : leadTimesInMinutes = _sanitizeLeadTimes(leadTimesInMinutes);

  factory NotificationSettings.defaults() => NotificationSettings();

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      eventNotificationsEnabled:
          json['eventNotificationsEnabled'] as bool? ?? true,
      taskNotificationsEnabled:
          json['taskNotificationsEnabled'] as bool? ?? true,
      overdueNotificationsEnabled:
          json['overdueNotificationsEnabled'] as bool? ?? true,
      projectDeadlineNotificationsEnabled:
          json['projectDeadlineNotificationsEnabled'] as bool? ?? true,
      exactTimeNotificationsEnabled:
          json['exactTimeNotificationsEnabled'] as bool? ?? true,
      soundProfile: NotificationSoundProfile.fromStorageKey(
        json['soundProfile'] as String?,
      ),
      vibrateOnlyOnAndroid: json['vibrateOnlyOnAndroid'] as bool? ?? false,
      leadTimesInMinutes: _sanitizeLeadTimes(
        json['leadTimesInMinutes'] as List?,
      ),
    );
  }

  final bool notificationsEnabled;
  final bool eventNotificationsEnabled;
  final bool taskNotificationsEnabled;
  final bool overdueNotificationsEnabled;
  final bool projectDeadlineNotificationsEnabled;
  final bool exactTimeNotificationsEnabled;
  final NotificationSoundProfile soundProfile;
  final bool vibrateOnlyOnAndroid;
  final List<int> leadTimesInMinutes;

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'eventNotificationsEnabled': eventNotificationsEnabled,
      'taskNotificationsEnabled': taskNotificationsEnabled,
      'overdueNotificationsEnabled': overdueNotificationsEnabled,
      'projectDeadlineNotificationsEnabled':
          projectDeadlineNotificationsEnabled,
      'exactTimeNotificationsEnabled': exactTimeNotificationsEnabled,
      'soundProfile': soundProfile.storageKey,
      'vibrateOnlyOnAndroid': vibrateOnlyOnAndroid,
      'leadTimesInMinutes': leadTimesInMinutes,
    };
  }

  NotificationSettings copyWith({
    bool? notificationsEnabled,
    bool? eventNotificationsEnabled,
    bool? taskNotificationsEnabled,
    bool? overdueNotificationsEnabled,
    bool? projectDeadlineNotificationsEnabled,
    bool? exactTimeNotificationsEnabled,
    NotificationSoundProfile? soundProfile,
    bool? vibrateOnlyOnAndroid,
    List<int>? leadTimesInMinutes,
  }) {
    return NotificationSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      eventNotificationsEnabled:
          eventNotificationsEnabled ?? this.eventNotificationsEnabled,
      taskNotificationsEnabled:
          taskNotificationsEnabled ?? this.taskNotificationsEnabled,
      overdueNotificationsEnabled:
          overdueNotificationsEnabled ?? this.overdueNotificationsEnabled,
      projectDeadlineNotificationsEnabled:
          projectDeadlineNotificationsEnabled ??
          this.projectDeadlineNotificationsEnabled,
      exactTimeNotificationsEnabled:
          exactTimeNotificationsEnabled ?? this.exactTimeNotificationsEnabled,
      soundProfile: soundProfile ?? this.soundProfile,
      vibrateOnlyOnAndroid: vibrateOnlyOnAndroid ?? this.vibrateOnlyOnAndroid,
      leadTimesInMinutes: leadTimesInMinutes ?? this.leadTimesInMinutes,
    );
  }

  String toJsonString() => json.encode(toJson());

  static NotificationSettings fromJsonString(String jsonString) {
    return NotificationSettings.fromJson(json.decode(jsonString));
  }
}
