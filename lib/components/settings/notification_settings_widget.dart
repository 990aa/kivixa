import 'package:flutter/material.dart';
import 'package:kivixa/components/settings/settings_subtitle.dart';
import 'package:kivixa/data/models/notification_settings.dart';
import 'package:kivixa/data/notification_settings_storage.dart';
import 'package:kivixa/services/notification_service.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  static const _leadTimeOptions = <int>[5, 10, 15, 30, 60, 120, 1440, 2880];

  late NotificationSettings _settings;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationSettingsStorage.loadSettings();
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _updateSettings(NotificationSettings settings) async {
    await NotificationSettingsStorage.saveSettings(settings);
    setState(() {
      _settings = settings;
    });

    // Reschedule notifications based on new settings
    if (settings.notificationsEnabled) {
      await NotificationService.instance.rescheduleAllNotifications();
    } else {
      await NotificationService.instance.cancelAllNotifications();
    }
  }

  String _formatLeadTime(int minutes) {
    if (minutes % 1440 == 0) {
      final days = minutes ~/ 1440;
      return days == 1 ? '1 day before' : '$days days before';
    }
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hour before' : '$hours hours before';
    }
    return '$minutes min before';
  }

  Future<void> _toggleLeadTime(int minutes) async {
    final nextLeadTimes = [..._settings.leadTimesInMinutes];
    if (nextLeadTimes.contains(minutes)) {
      nextLeadTimes.remove(minutes);
    } else {
      nextLeadTimes.add(minutes);
    }
    nextLeadTimes.sort();
    await _updateSettings(
      _settings.copyWith(leadTimesInMinutes: nextLeadTimes),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSubtitle(subtitle: 'Calendar Notifications'),
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text(
            'Receive notifications for calendar events and tasks',
          ),
          value: _settings.notificationsEnabled,
          onChanged: (value) {
            _updateSettings(_settings.copyWith(notificationsEnabled: value));
          },
          secondary: Icon(
            _settings.notificationsEnabled
                ? Icons.notifications_active
                : Icons.notifications_off,
          ),
        ),
        if (_settings.notificationsEnabled) ...[
          SwitchListTile(
            title: const Text('Event Notifications'),
            subtitle: const Text('Get notified when events start'),
            value: _settings.eventNotificationsEnabled,
            onChanged: (value) {
              _updateSettings(
                _settings.copyWith(eventNotificationsEnabled: value),
              );
            },
            secondary: const Icon(Icons.event),
          ),
          SwitchListTile(
            title: const Text('Task Notifications'),
            subtitle: const Text('Get notified when tasks are due'),
            value: _settings.taskNotificationsEnabled,
            onChanged: (value) {
              _updateSettings(
                _settings.copyWith(taskNotificationsEnabled: value),
              );
            },
            secondary: const Icon(Icons.task_alt),
          ),
          SwitchListTile(
            title: const Text('Project Deadline Notifications'),
            subtitle: const Text('Get reminders for project deadlines'),
            value: _settings.projectDeadlineNotificationsEnabled,
            onChanged: (value) {
              _updateSettings(
                _settings.copyWith(projectDeadlineNotificationsEnabled: value),
              );
            },
            secondary: const Icon(Icons.flag_circle),
          ),
          SwitchListTile(
            title: const Text('Overdue Task Reminders'),
            subtitle: const Text(
              'Receive daily reminders for overdue tasks until completed',
            ),
            value: _settings.overdueNotificationsEnabled,
            onChanged: (value) {
              _updateSettings(
                _settings.copyWith(overdueNotificationsEnabled: value),
              );
            },
            secondary: const Icon(Icons.alarm),
          ),
          SwitchListTile(
            title: const Text('Exact-Time Notifications'),
            subtitle: const Text(
              'Schedule reminders at the exact task/event/deadline time',
            ),
            value: _settings.exactTimeNotificationsEnabled,
            onChanged: (value) {
              _updateSettings(
                _settings.copyWith(exactTimeNotificationsEnabled: value),
              );
            },
            secondary: const Icon(Icons.schedule_send),
          ),
          SwitchListTile(
            title: const Text('Vibrate-Only on Android'),
            subtitle: const Text(
              'Use vibration without audio for calendar and productivity alerts',
            ),
            value: _settings.vibrateOnlyOnAndroid,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(vibrateOnlyOnAndroid: value));
            },
            secondary: const Icon(Icons.vibration),
          ),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('Notification Sound'),
            subtitle: Text(_settings.soundProfile.label),
            trailing: DropdownButton<NotificationSoundProfile>(
              value: _settings.soundProfile,
              onChanged: (profile) {
                if (profile == null) return;
                _updateSettings(_settings.copyWith(soundProfile: profile));
              },
              items: NotificationSoundProfile.values
                  .map(
                    (profile) => DropdownMenuItem(
                      value: profile,
                      child: Text(profile.label),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.notification_important),
            title: const Text('Lead Time Reminders'),
            subtitle: Text(
              _settings.leadTimesInMinutes
                      .map(_formatLeadTime)
                      .join(', ')
                      .trim()
                      .isEmpty
                  ? 'No lead reminders selected'
                  : _settings.leadTimesInMinutes
                        .map(_formatLeadTime)
                        .join(', '),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _leadTimeOptions.map((minutes) {
              final selected = _settings.leadTimesInMinutes.contains(minutes);
              return FilterChip(
                label: Text(_formatLeadTime(minutes)),
                selected: selected,
                onSelected: (_) => _toggleLeadTime(minutes),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
