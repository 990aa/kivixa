import 'dart:async';
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

  static const officialNotificationAssetPath = 'assets/audio/NOTIFICATION.mp3';

  static const defaultReminderSoundId = 'alarm_star_dust';

  static const _repoAudioBaseUrl =
      'https://raw.githubusercontent.com/990aa/kivixa/main/audio';

  static const reminderSoundOptions = <ReminderSoundOption>[
    ReminderSoundOption(
      id: 'alarm_star_dust',
      label: 'Star Dust (Default)',
      fileName: 'SOUND_star-dust.mp3',
      downloadUrl: '$_repoAudioBaseUrl/SOUND_star-dust.mp3',
      bundledAssetPath: 'assets/audio/SOUND_star-dust.mp3',
      isDefault: true,
    ),
    ReminderSoundOption(
      id: 'alarm_wind_chimes',
      label: 'Wind Chimes',
      fileName: 'SOUND_wind-chimes.wav',
      downloadUrl: '$_repoAudioBaseUrl/SOUND_wind-chimes.wav',
    ),
    ReminderSoundOption(
      id: 'alarm_chiming_out',
      label: 'Chiming Out',
      fileName: 'SOUND_chiming-out.mp3',
      downloadUrl: '$_repoAudioBaseUrl/SOUND_chiming-out.mp3',
    ),
    ReminderSoundOption(
      id: 'alarm_soft_plucks',
      label: 'Soft Plucks',
      fileName: 'SOUND_soft-plucks.mp3',
      downloadUrl: '$_repoAudioBaseUrl/SOUND_soft-plucks.mp3',
    ),
  ];

  ReminderSoundOption optionById(String id) {
    return reminderSoundOptions.firstWhere(
      (option) => option.id == id,
      orElse: () => reminderSoundOptions.first,
    );
  }

  Future<Directory> _soundsDirectory() async {
    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final dir = Directory(p.join(externalDir.path, 'notification_sounds'));
        try {
          await dir.create(recursive: true);
          return dir;
        } catch (e) {
          // If creation fails (permissions, mounted drive, etc.), fall back
          // to the user's documents directory or system temp directory.
          try {
            final docs = await getApplicationDocumentsDirectory();
            final fallback = Directory(
              p.join(docs.path, 'kivixa', 'notification_sounds'),
            );
            await fallback.create(recursive: true);
            return fallback;
          } catch (e) {
            final temp = Directory(
              p.join(Directory.systemTemp.path, 'kivixa_notification_sounds'),
            );
            await temp.create(recursive: true);
            return temp;
          }
        }
      }
    }

    if (Platform.isIOS || Platform.isMacOS) {
      final libraryDir = await getLibraryDirectory();
      final dir = Directory(p.join(libraryDir.path, 'Sounds'));
      try {
        await dir.create(recursive: true);
        return dir;
      } catch (e) {
        try {
          final docs = await getApplicationDocumentsDirectory();
          final fallback = Directory(
            p.join(docs.path, 'kivixa', 'notification_sounds'),
          );
          await fallback.create(recursive: true);
          return fallback;
        } catch (e) {
          final temp = Directory(
            p.join(Directory.systemTemp.path, 'kivixa_notification_sounds'),
          );
          await temp.create(recursive: true);
          return temp;
        }
      }
    }

    // Windows and Linux: Use AppData\Roaming (Windows) or ~/.local/share
    // (Linux) via getApplicationSupportDirectory. On Windows this is always
    // under the current user's profile — never in Program Files — so it is
    // always writable without elevation.
    //
    // Fallback chain:
    //   1. getApplicationSupportDirectory  → %APPDATA%\kivixa\notification_sounds
    //   2. getApplicationDocumentsDirectory → Documents\Kivixa\notification_sounds
    //   3. systemTemp                       → Temp\kivixa_notification_sounds
    try {
      final supportDir = await getApplicationSupportDirectory();
      final dir = Directory(p.join(supportDir.path, 'notification_sounds'));
      await dir.create(recursive: true);
      return dir;
    } catch (_) {}

    try {
      final docs = await getApplicationDocumentsDirectory();
      final fallback = Directory(
        p.join(docs.path, 'Kivixa', 'notification_sounds'),
      );
      await fallback.create(recursive: true);
      return fallback;
    } catch (_) {}

    final temp = Directory(
      p.join(Directory.systemTemp.path, 'kivixa_notification_sounds'),
    );
    await temp.create(recursive: true);
    return temp;
  }

  Future<File> _fileForOption(ReminderSoundOption option) async {
    final dir = await _soundsDirectory();
    return File(p.join(dir.path, option.fileName));
  }

  Future<void> ensureDefaultReminderSoundInstalled() async {
    final defaultOption = reminderSoundOptions.firstWhere(
      (option) => option.isDefault,
      orElse: () => reminderSoundOptions.first,
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

  Future<String?> localPathForReminderSound(String soundId) async {
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

    return null;
  }

  Future<void> downloadReminderSound(
    String soundId, {
    http.Client? client,
  }) async {
    final option = optionById(soundId);
    final target = await _fileForOption(option);

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(Uri.parse(option.downloadUrl))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Failed to download reminder sound (${response.statusCode})',
        );
      }

      await target.writeAsBytes(response.bodyBytes, flush: true);
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<bool> deleteReminderSound(String soundId) async {
    final option = optionById(soundId);
    if (option.isDefault) {
      return false;
    }

    final target = await _fileForOption(option);
    if (!target.existsSync()) {
      return false;
    }

    await target.delete();
    return true;
  }
}
