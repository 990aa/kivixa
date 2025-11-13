import 'package:kivixa/data/models/notification_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsStorage {
  static const _settingsKey = 'notification_settings';

  static Future<NotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson == null) return NotificationSettings();

    return NotificationSettings.fromJsonString(settingsJson);
  }

  static Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settings.toJsonString());
  }
}
