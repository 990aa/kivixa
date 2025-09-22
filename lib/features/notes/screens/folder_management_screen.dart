import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/widgets/folder_grid_view.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class FolderManagementScreen extends StatefulWidget {
  const FolderManagementScreen({super.key});

  @override
  State<FolderManagementScreen> createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
  bool _isNeumorphic = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuTheme(
      data: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.transparent,
        elevation: 0,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: Icon(_isNeumorphic ? Icons.view_quilt : Icons.view_agenda),
              onPressed: () {
                setState(() {
                  _isNeumorphic = !_isNeumorphic;
                });
              },
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: FolderGridView(isNeumorphic: _isNeumorphic),
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
