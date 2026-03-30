import 'package:flutter/material.dart';
import 'package:kivixa/i18n/strings.g.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 64),
            Text(t.home.welcome, style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(t.home.createNewNote, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
