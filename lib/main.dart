import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/screens/notes_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kivixa',
      theme: ThemeData.dark(),
      home: const NotesHomeScreen(),
    );
  }
}