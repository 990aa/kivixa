import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModeKey = 'theme_mode';

enum ThemeModeSetting {
  system,
  light,
  dark;

  ThemeMode toThemeMode() {
    switch (this) {
      case ThemeModeSetting.system:
        return ThemeMode.system;
      case ThemeModeSetting.light:
        return ThemeMode.light;
      case ThemeModeSetting.dark:
        return ThemeMode.dark;
    }
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeModeSetting> {
  ThemeModeNotifier(this._prefs) : super(ThemeModeSetting.system) {
    _loadThemeMode();
  }

  final SharedPreferences _prefs;

  Future<void> _loadThemeMode() async {
    final savedTheme = _prefs.getString(_themeModeKey);
    if (savedTheme != null) {
      state = ThemeModeSetting.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeModeSetting.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeModeSetting mode) async {
    if (mode != state) {
      state = mode;
      await _prefs.setString(_themeModeKey, mode.toString());
    }
  }
}

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final themeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeModeSetting>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).asData!.value;
  return ThemeModeNotifier(prefs);
});
