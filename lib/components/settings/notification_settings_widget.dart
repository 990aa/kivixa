import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kivixa/components/settings/settings_subtitle.dart';
import 'package:kivixa/data/models/notification_settings.dart';
import 'package:kivixa/data/notification_settings_storage.dart';
import 'package:kivixa/services/notification_service.dart';
import 'package:kivixa/services/notification_sound_catalog_service.dart';
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
  final _soundCatalog = NotificationSoundCatalogService.instance;

  var _settings = NotificationSettings.defaults();
  var _loading = true;
  final _downloadingSoundIds = <String>{};
  final _deletingSoundIds = <String>{};
  Map<String, bool> _soundDownloadStates = const {};

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
    try {
      final settings = await NotificationSettingsStorage.loadSettings();
      final states = await _soundCatalog.downloadStates();
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = settings;
        _soundDownloadStates = states;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = NotificationSettings.defaults();
        _soundDownloadStates = const {};
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load notification sounds: $error')),
      );
    }
  }

  Future<void> _updateSettings(NotificationSettings settings) async {
    await NotificationSettingsStorage.saveSettings(settings);
    setState(() {
      _settings = settings;
    });

    // Apply changed settings to all future schedules.
    await NotificationService.instance.cancelAllNotifications();
    await NotificationService.instance.rescheduleAllNotifications();
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

  Future<void> _downloadReminderSound(String soundId) async {
    if (_downloadingSoundIds.contains(soundId)) {
      return;
    }

    setState(() {
      _downloadingSoundIds.add(soundId);
    });

    try {
      await _soundCatalog.downloadReminderSound(soundId);
      final updatedStates = await _soundCatalog.downloadStates();
      if (!mounted) {
        return;
      }
      setState(() {
        _soundDownloadStates = updatedStates;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download sound: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingSoundIds.remove(soundId);
        });
      }
    }
  }

  Future<void> _deleteReminderSound(String soundId) async {
    if (_deletingSoundIds.contains(soundId)) {
      return;
    }

    setState(() {
      _deletingSoundIds.add(soundId);
    });

    try {
      final deleted = await _soundCatalog.deleteReminderSound(soundId);
      final updatedStates = await _soundCatalog.downloadStates();
      if (!mounted) {
        return;
      }

      if (_settings.reminderSoundId == soundId) {
        await _updateSettings(
          _settings.copyWith(
            reminderSoundId:
                NotificationSoundCatalogService.defaultReminderSoundId,
          ),
        );
        if (!mounted) {
          return;
        }
      }

      setState(() {
        _soundDownloadStates = updatedStates;
      });

      if (deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sound deleted successfully')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete sound: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _deletingSoundIds.remove(soundId);
        });
      }
    }
  }

  bool _isSoundReady(String soundId) {
    return _soundDownloadStates[soundId] ?? false;
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
        const SettingsSubtitle(subtitle: 'Calendar Notifications'),
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

        const SettingsSubtitle(subtitle: 'Sound & Vibration'),
        SwitchListTile(
          secondary: const Icon(Icons.volume_up),
          title: const Text('Sound'),
          subtitle: const Text(
            'Play selected reminder/timer sound for notifications and alerts',
          ),
          value: _settings.notificationSoundEnabled,
          onChanged: (value) {
            _updateSettings(
              _settings.copyWith(
                notificationFeedbackMode: NotificationFeedbackMode.fromFlags(
                  soundEnabled: value,
                  vibrationEnabled: _settings.notificationVibrationEnabled,
                ),
              ),
            );
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.vibration),
          title: const Text('Vibration'),
          subtitle: const Text('Vibrate on reminder/timer alerts'),
          value: _settings.notificationVibrationEnabled,
          onChanged: (value) {
            _updateSettings(
              _settings.copyWith(
                notificationFeedbackMode: NotificationFeedbackMode.fromFlags(
                  soundEnabled: _settings.notificationSoundEnabled,
                  vibrationEnabled: value,
                ),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.music_note),
          title: const Text('Reminder & Timer Alert Sound'),
          subtitle: Text(
            _soundCatalog.optionById(_settings.reminderSoundId).label,
          ),
        ),
        ...NotificationSoundCatalogService.reminderSoundOptions.map((option) {
          final isSelected = option.id == _settings.reminderSoundId;
          final isReady = _isSoundReady(option.id);
          final isDownloading = _downloadingSoundIds.contains(option.id);
          final isDeleting = _deletingSoundIds.contains(option.id);
          final canDelete = !option.isDefault && isReady;

          Widget trailing;
          if (isDownloading || isDeleting) {
            trailing = const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          } else if (isReady) {
            trailing = Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!isSelected)
                  TextButton(
                    onPressed: () {
                      _updateSettings(
                        _settings.copyWith(reminderSoundId: option.id),
                      );
                    },
                    child: const Text('Use'),
                  ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (canDelete)
                  OutlinedButton(
                    onPressed: () => _deleteReminderSound(option.id),
                    child: const Text('Delete'),
                  ),
              ],
            );
          } else {
            trailing = OutlinedButton(
              onPressed: () => _downloadReminderSound(option.id),
              child: const Text('Download'),
            );
          }

          return ListTile(
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            ),
            title: Text(option.label),
            subtitle: Text(
              isReady ? 'Ready to use' : 'Download to enable this sound',
            ),
            trailing: trailing,
            onTap: isReady
                ? () => _updateSettings(
                    _settings.copyWith(reminderSoundId: option.id),
                  )
                : null,
          );
        }),

        const SettingsSubtitle(subtitle: 'Productivity Timer Notifications'),
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
