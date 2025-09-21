import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:kivixa/features/notes/widgets/folder_grid_view.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class FolderManagementScreen extends StatelessWidget {
  const FolderManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuTheme(
      data: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.transparent,
        elevation: 0,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Folder Management'),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: const FolderGridView(),
        floatingActionButton: SpeedDial(
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.create_new_folder),
              label: 'Create Folder',
              onTap: () {
                // TODO: Implement create folder action
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.note_add),
              label: 'Create Note',
              onTap: () {
                // TODO: Implement create note action
              },
            ),
          ],
        ),
      ),
    );
  }
}
