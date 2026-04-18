import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kivixa/components/settings/settings_subtitle.dart';
import 'package:kivixa/data/models/notification_settings.dart';
import 'package:kivixa/data/notification_settings_storage.dart';
import 'package:kivixa/services/notification_service.dart';
import 'package:kivixa/services/productivity/productivity_timer_service.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  static const _leadTimeOptions = <int>[5, 10, 15, 30, 60, 120, 1440, 2880];
  final _timerService = ProductivityTimerService.instance;

  late NotificationSettings _settings;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _timerService.addListener(_onTimerSettingsChanged);
    unawaited(_initializeTimerService());
    _loadSettings();
  }

  @override
  void dispose() {
    _timerService.removeListener(_onTimerSettingsChanged);
    super.dispose();
  }

  void _onTimerSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeTimerService() async {
    await _timerService.initialize();
    if (mounted) {
      setState(() {});
    }
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

  Future<void> _requestTimerPermission() async {
    await _timerService.requestNotificationPermission();
    if (mounted) {
      setState(() {});
    }
  }

  String _leadTimeSummary() {
    final sorted = [..._settings.leadTimesInMinutes]..sort();
    if (sorted.isEmpty) {
      return 'No lead reminders selected';
    }
    return sorted.map(_formatLeadTime).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSubtitle(subtitle: 'App Notifications'),
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text(
            'Enable or disable notifications across calendar and productivity timer features',
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

        const SettingsSubtitle(subtitle: 'Calendar Notifications'),
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
          ListTile(
            leading: const Icon(Icons.notification_important),
            title: const Text('Lead Time Reminders'),
            subtitle: Text(_leadTimeSummary()),
            trailing: PopupMenuButton<int>(
              tooltip: 'Select lead-time reminders',
              icon: const Icon(Icons.arrow_drop_down_circle_outlined),
              onSelected: (minutes) {
                _toggleLeadTime(minutes);
              },
              itemBuilder: (context) {
                return _leadTimeOptions
                    .map((minutes) {
                      return CheckedPopupMenuItem<int>(
                        value: minutes,
                        checked: _settings.leadTimesInMinutes.contains(minutes),
                        child: Text(_formatLeadTime(minutes)),
                      );
                    })
                    .toList(growable: false);
              },
            ),
          ),
        ] else ...[
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Calendar notifications are disabled'),
            subtitle: Text(
              'Enable app notifications to configure calendar reminders.',
            ),
          ),
        ],

        const SettingsSubtitle(subtitle: 'Sound & Vibration'),
        ListTile(
          leading: const Icon(Icons.music_note),
          title: const Text('Notification Sound'),
          subtitle: Text(_settings.soundProfile.label),
          trailing: DropdownButton<NotificationSoundProfile>(
            value: _settings.soundProfile,
            onChanged: _settings.notificationsEnabled
                ? (profile) {
                    if (profile == null) return;
                    _updateSettings(_settings.copyWith(soundProfile: profile));
                  }
                : null,
            items: NotificationSoundProfile.values
                .map(
                  (profile) => DropdownMenuItem(
                    value: profile,
                    child: Text(profile.label),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        SwitchListTile(
          title: const Text('Vibrate on Android'),
          subtitle: const Text(
            'Use vibration for notifications on supported Android devices',
          ),
          value: _settings.vibrateOnlyOnAndroid,
          onChanged: _settings.notificationsEnabled
              ? (value) {
                  _updateSettings(
                    _settings.copyWith(vibrateOnlyOnAndroid: value),
                  );
                }
              : null,
          secondary: const Icon(Icons.vibration),
        ),

        const SettingsSubtitle(subtitle: 'Productivity Timer Notifications'),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notification Permission'),
          subtitle: Text(
            _timerService.notificationsPermissionGranted
                ? 'Granted - timer notifications are allowed by the system'
                : 'Not granted - tap Enable to allow timer notifications',
          ),
          trailing: _timerService.notificationsPermissionGranted
              ? Icon(Icons.check_circle, color: Colors.green[700])
              : TextButton(
                  onPressed: _requestTimerPermission,
                  child: const Text('Enable'),
                ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.volume_up),
          title: const Text('Timer Sound Alerts'),
          subtitle: const Text(
            'Play sound when productivity timer sessions complete',
          ),
          value: _timerService.soundEnabled,
          onChanged: (value) => _timerService.setSoundEnabled(value),
        ),
      ],
    );
  }
}
