import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/screens/folder_management_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnTheme(
      data: ShadcnThemeData(
        brightness: Brightness.dark,
        primary: ShadcnColor.fromRgb(0, 122, 255),
      ),
      child: MaterialApp(
        title: 'Kivixa',
        theme: ThemeData.dark(),
        home: const FolderManagementScreen(),
      ),
    );
  }
}
