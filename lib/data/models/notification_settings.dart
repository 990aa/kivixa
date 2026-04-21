import 'dart:convert';

const defaultReminderSoundId = 'alarm_star_dust';

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

enum NotificationFeedbackMode {
  vibrateOnly('vibrate_only', 'Vibrate only'),
  vibrateWithSound('vibrate_with_sound', 'Vibrate + Sound');

  const NotificationFeedbackMode(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static NotificationFeedbackMode fromStorageKey(String? key) {
    for (final mode in NotificationFeedbackMode.values) {
      if (mode.storageKey == key) {
        return mode;
      }
    }
    return NotificationFeedbackMode.vibrateWithSound;
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
    this.notificationFeedbackMode = NotificationFeedbackMode.vibrateWithSound,
    this.reminderSoundId = defaultReminderSoundId,
    List<int> leadTimesInMinutes = const [10, 60, 1440],
  }) : leadTimesInMinutes = _sanitizeLeadTimes(leadTimesInMinutes);

  factory NotificationSettings.defaults() => NotificationSettings();

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final legacySoundProfile = NotificationSoundProfile.fromStorageKey(
      json['soundProfile'] as String?,
    );
    final legacyVibrateOnly = json['vibrateOnlyOnAndroid'] as bool? ?? false;
    final feedbackMode = json['notificationFeedbackMode'] != null
        ? NotificationFeedbackMode.fromStorageKey(
            json['notificationFeedbackMode'] as String?,
          )
        : (legacyVibrateOnly
              ? NotificationFeedbackMode.vibrateOnly
              : NotificationFeedbackMode.vibrateWithSound);

    final reminderSoundId =
        (json['reminderSoundId'] as String?)?.trim().isNotEmpty == true
        ? (json['reminderSoundId'] as String).trim()
        : defaultReminderSoundId;

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
      soundProfile: legacySoundProfile,
      vibrateOnlyOnAndroid: legacyVibrateOnly,
      notificationFeedbackMode: feedbackMode,
      reminderSoundId: reminderSoundId,
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

  /// Legacy fields retained for backward compatibility with existing tests/data.
  /// New code should use [notificationFeedbackMode] and [reminderSoundId].
  final NotificationSoundProfile soundProfile;
  final bool vibrateOnlyOnAndroid;

  final NotificationFeedbackMode notificationFeedbackMode;
  final String reminderSoundId;
  final List<int> leadTimesInMinutes;

  Map<String, dynamic> toJson() {
    final legacySoundProfile =
        notificationFeedbackMode == NotificationFeedbackMode.vibrateOnly
        ? NotificationSoundProfile.silent
        : NotificationSoundProfile.defaultTone;
    final legacyVibrateOnly =
        notificationFeedbackMode == NotificationFeedbackMode.vibrateOnly;

    return {
      'notificationsEnabled': notificationsEnabled,
      'eventNotificationsEnabled': eventNotificationsEnabled,
      'taskNotificationsEnabled': taskNotificationsEnabled,
      'overdueNotificationsEnabled': overdueNotificationsEnabled,
      'projectDeadlineNotificationsEnabled':
          projectDeadlineNotificationsEnabled,
      'exactTimeNotificationsEnabled': exactTimeNotificationsEnabled,
      'soundProfile': legacySoundProfile.storageKey,
      'vibrateOnlyOnAndroid': legacyVibrateOnly,
      'notificationFeedbackMode': notificationFeedbackMode.storageKey,
      'reminderSoundId': reminderSoundId,
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
    NotificationFeedbackMode? notificationFeedbackMode,
    String? reminderSoundId,
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
      notificationFeedbackMode:
          notificationFeedbackMode ?? this.notificationFeedbackMode,
      reminderSoundId: (reminderSoundId ?? this.reminderSoundId).trim().isEmpty
          ? defaultReminderSoundId
          : (reminderSoundId ?? this.reminderSoundId).trim(),
      leadTimesInMinutes: leadTimesInMinutes ?? this.leadTimesInMinutes,
    );
  }

  String toJsonString() => json.encode(toJson());

  static NotificationSettings fromJsonString(String jsonString) {
    return NotificationSettings.fromJson(json.decode(jsonString));
  }
}
