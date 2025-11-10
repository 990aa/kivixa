import 'package:flutter/material.dart';
import 'package:kivixa/components/theming/font_fallbacks.dart';
import 'package:kivixa/data/prefs.dart';

abstract class KivixaTheme {
  static TextTheme? createTextTheme(Brightness brightness) {
    if (stows.hyperlegibleFont.value) {
      return ThemeData(brightness: brightness).textTheme.withFont(
        fontFamily: 'AtkinsonHyperlegibleNext',
        fontFamilyFallback: kivixaSansSerifFontFallbacks,
      );
    } else {
      return null;
    }
  }

  static ThemeData createTheme(
    ColorScheme colorScheme,
    TargetPlatform platform,
  ) => ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: createTextTheme(colorScheme.brightness),
    platform: platform,
    pageTransitionsTheme: _pageTransitionsTheme,
  );

  /// Synced with [PageTransitionsTheme._defaultBuilders]
  /// but with PredictiveBackPageTransitionsBuilder for Android.
  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    },
  );
}
