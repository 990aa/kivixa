import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kivixa/core/theme/icons.dart';
import 'package:kivixa/core/theme/theme.dart';
import 'package:kivixa/core/theme/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider).toThemeMode();

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Kivixa',
          theme: KivixaTheme.lightTheme(lightDynamic),
          darkTheme: KivixaTheme.darkTheme(darkDynamic),
          themeMode: themeMode,
          home: const MyHomePage(title: 'Kivixa Theme Demo'),
        );
      },
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Theme Mode:'),
            Text(
              currentTheme.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(PhosphorIcons.sun),
                  onPressed: () =>
                      themeNotifier.setThemeMode(ThemeModeSetting.light),
                  tooltip: 'Light Mode',
                ),
                IconButton(
                  icon: const Icon(PhosphorIcons.moon),
                  onPressed: () =>
                      themeNotifier.setThemeMode(ThemeModeSetting.dark),
                  tooltip: 'Dark Mode',
                ),
                IconButton(
                  icon: const Icon(PhosphorIcons.monitor),
                  onPressed: () =>
                      themeNotifier.setThemeMode(ThemeModeSetting.system),
                  tooltip: 'System Mode',
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
