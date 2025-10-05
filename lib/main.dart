// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'domain/models/note.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(PageTemplateAdapter());
  Hive.registerAdapter(DrawingToolAdapter());
  Hive.registerAdapter(StrokeAdapter());
  Hive.registerAdapter(CanvasImageAdapter());
  Hive.registerAdapter(NotePageAdapter());
  Hive.registerAdapter(NoteAdapter());
  
  runApp(const ProviderScope(child: KivixaApp()));
}

class KivixaApp extends StatelessWidget {
  const KivixaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kivixa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}