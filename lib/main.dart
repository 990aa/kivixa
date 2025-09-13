import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kivixa/core/theme/theme.dart';

import 'package:kivixa/features/library/library_screen.dart';
import 'package:kivixa/features/splash/splash_screen.dart';
import 'package:kivixa/features/onboarding/onboarding_screen.dart';
import 'package:kivixa/features/about/about_screen.dart';
import 'package:kivixa/features/changelog/changelog_screen.dart';
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
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/home': (context) => const LibraryScreen(),
            '/about': (context) => const AboutScreen(),
            '/changelog': (context) => const ChangelogScreen(),
          },
          onGenerateRoute: (settings) {
            // Add smooth transitions for deep links and navigation
            WidgetBuilder? builder = {
              '/': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const LibraryScreen(),
              '/about': (context) => const AboutScreen(),
              '/changelog': (context) => const ChangelogScreen(),
            }[settings.name];
            if (builder != null) {
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    builder(context),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 400),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
