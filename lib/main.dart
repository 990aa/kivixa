import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/folders_bloc.dart';
import 'package:kivixa/features/notes/screens/folder_management_screen.dart';
import 'package:kivixa/features/notes/services/notes_database_service.dart';
import 'package:kivixa/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FoldersBloc(NotesDatabaseService.instance),
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          return MaterialApp(
            title: 'Kivixa',
            theme: buildLightTheme(lightDynamic),
            darkTheme: buildDarkTheme(darkDynamic),
            home: const FolderManagementScreen(),
          );
        },
      ),
    );
  }
}
