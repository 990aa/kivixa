import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF6200EE);
const Color secondaryColor = Color(0xFF03DAC6);

ThemeData buildLightTheme(ColorScheme? lightColorScheme) {
  final colorScheme = lightColorScheme ??
      ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      );
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
  );
}

ThemeData buildDarkTheme(ColorScheme? darkColorScheme) {
  final colorScheme = darkColorScheme ??
      ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      );
  return ThemeData(
    colorScheme: colorScheme,
    brightness: Brightness.dark,
    useMaterial3: true,
  );
}
