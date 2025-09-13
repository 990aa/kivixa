import 'package:flutter/material.dart';
import 'package:kivixa/core/theme/color_schemes.dart';
import 'package:kivixa/core/theme/typography.dart';

class KivixaTheme {
  static ThemeData lightTheme(ColorScheme? dynamicColorScheme) {
    final colorScheme = dynamicColorScheme ?? lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      // Add other theme properties like button themes, card themes, etc. here
    );
  }

  static ThemeData darkTheme(ColorScheme? dynamicColorScheme) {
    final colorScheme = dynamicColorScheme ?? darkColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      // Add other theme properties like button themes, card themes, etc. here
    );
  }
}
