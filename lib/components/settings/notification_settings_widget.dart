import 'package:flutter/material.dart';
import 'package:kivixa/components/settings/settings_subtitle.dart';
import 'package:kivixa/components/settings/settings_switch.dart';
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
        ],
      ],
    );
  }
}
