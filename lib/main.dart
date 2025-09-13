import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kivixa/core/theme/theme.dart';
import 'package:kivixa/features/library/library_screen.dart';
import 'package:kivixa/providers.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Kivixa',
          theme: KivixaTheme.lightTheme(lightDynamic),
          darkTheme: KivixaTheme.darkTheme(darkDynamic),
          themeMode: themeMode.toThemeMode(),
          home: const LibraryScreen(),
        );
      },
    );
  }
}