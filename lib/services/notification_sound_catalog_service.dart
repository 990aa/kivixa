import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ReminderSoundOption {
  const ReminderSoundOption({
    required this.id,
    required this.label,
    required this.fileName,
    required this.downloadUrl,
    this.bundledAssetPath,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String fileName;
  final String downloadUrl;
  final String? bundledAssetPath;
  final bool isDefault;
}

class NotificationSoundCatalogService {
  NotificationSoundCatalogService._();

  static final instance = NotificationSoundCatalogService._();

  static const officialNotificationAssetPath =
      'assets/audio/NOTIFICATION_dragon-studio-notification-sound-effect-372475.mp3';

  static const defaultReminderSoundId = 'alarm_star_dust';

  static const _repoAudioBaseUrl =
      'https://raw.githubusercontent.com/990aa/kivixa/main/audio';

  static const reminderSoundOptions = <ReminderSoundOption>[
    ReminderSoundOption(
      id: 'alarm_star_dust',
      label: 'Star Dust (Default)',
      fileName: 'ALARM_lesiakower-star-dust-alarm-clock-114194.mp3',
      downloadUrl:
          '$_repoAudioBaseUrl/ALARM_lesiakower-star-dust-alarm-clock-114194.mp3',
      bundledAssetPath:
          'assets/audio/ALARM_lesiakower-star-dust-alarm-clock-114194.mp3',
      isDefault: true,
    ),
    ReminderSoundOption(
      id: 'alarm_wind_chimes',
      label: 'Wind Chimes',
      fileName: 'ALARM_35722__offthesky__wind-chimes.wav',
      downloadUrl: '$_repoAudioBaseUrl/ALARM_35722__offthesky__wind-chimes.wav',
    ),
    ReminderSoundOption(
      id: 'alarm_chiming_out',
      label: 'Chiming Out',
      fileName: 'ALARM_246390__foolboymedia__chiming-out.mp3',
      downloadUrl:
          '$_repoAudioBaseUrl/ALARM_246390__foolboymedia__chiming-out.mp3',
    ),
    ReminderSoundOption(
      id: 'alarm_soft_plucks',
      label: 'Soft Plucks',
      fileName: 'ALARM_lesiakower-soft-plucks-alarm-clock-120696.mp3',
      downloadUrl:
          '$_repoAudioBaseUrl/ALARM_lesiakower-soft-plucks-alarm-clock-120696.mp3',
    ),
  ];

  ReminderSoundOption optionById(String id) {
    return reminderSoundOptions.firstWhere(
      (option) => option.id == id,
      orElse: () => reminderSoundOptions.first,
    );
  }

  Future<Directory> _soundsDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'notification_sounds'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileForOption(ReminderSoundOption option) async {
    final dir = await _soundsDirectory();
    return File(p.join(dir.path, option.fileName));
  }

  Future<void> ensureDefaultReminderSoundInstalled() async {
    final defaultOption = reminderSoundOptions.firstWhere(
      (option) => option.isDefault,
    );

    final targetFile = await _fileForOption(defaultOption);
    if (targetFile.existsSync()) {
      return;
    }

    final assetPath = defaultOption.bundledAssetPath;
    if (assetPath == null) {
      return;
    }

    final data = await rootBundle.load(assetPath);
    await targetFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  }

  Future<Map<String, bool>> downloadStates() async {
    await ensureDefaultReminderSoundInstalled();

    final states = <String, bool>{};
    for (final option in reminderSoundOptions) {
      final file = await _fileForOption(option);
      states[option.id] = file.existsSync();
    }
    return states;
  }

  Future<String> localPathForReminderSound(String soundId) async {
    await ensureDefaultReminderSoundInstalled();

    final option = optionById(soundId);
    final file = await _fileForOption(option);
    if (file.existsSync()) {
      return file.path;
    }

    final fallback = await _fileForOption(optionById(defaultReminderSoundId));
    if (fallback.existsSync()) {
      return fallback.path;
    }

    return file.path;
  }

  Future<void> downloadReminderSound(String soundId) async {
    final option = optionById(soundId);
    final target = await _fileForOption(option);

    final response = await http.get(Uri.parse(option.downloadUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to download reminder sound (${response.statusCode})',
      );
    }

    await target.writeAsBytes(response.bodyBytes, flush: true);
  }
}
