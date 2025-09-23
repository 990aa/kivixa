import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/folders_bloc.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/screens/note_editor_screen.dart';
import 'package:kivixa/features/notes/blocs/document_bloc.dart';
import 'package:kivixa/features/notes/blocs/drawing_bloc.dart';
import 'package:kivixa/features/notes/services/notes_database_service.dart';
import 'package:kivixa/features/notes/widgets/folder_grid_view.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:uuid/uuid.dart';
import 'package:kivixa/features/notes/models/note_document.dart';
import 'package:kivixa/features/notes/models/note_page.dart';
import 'package:kivixa/features/notes/models/paper_settings.dart';

class FolderManagementScreen extends StatefulWidget {
  const FolderManagementScreen({super.key});

  @override
  State<FolderManagementScreen> createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
  bool _isNeumorphic = false;

  @override
  void initState() {
    super.initState();
    context.read<FoldersBloc>().add(LoadFolders());
  }

  void _showCreateFolderDialog(BuildContext context, List<Folder> folders) {
    final TextEditingController folderNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Folder'),
          content: TextField(
            controller: folderNameController,
            decoration: const InputDecoration(hintText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (folderNameController.text.isNotEmpty) {
                  final newFolder = Folder(
                    name: folderNameController.text,
                    color: Colors
                        .primaries[folders.length % Colors.primaries.length],
                    noteCount: 0,
                  );
                  context.read<FoldersBloc>().add(AddFolder(newFolder));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

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
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                )
              : null,
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
        body: BlocBuilder<FoldersBloc, FoldersState>(
          builder: (context, state) {
            if (state is FoldersLoadInProgress) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is FoldersLoadSuccess) {
              return FolderGridView(
                isNeumorphic: _isNeumorphic,
                folders: state.folders,
                allFolders: state.folders,
              );
            } else if (state is FoldersLoadFailure) {
              return Center(child: Text('Error: ${state.error}'));
            }
            return const Center(child: Text('No folders found.'));
          },
        ),
        floatingActionButton: BlocBuilder<FoldersBloc, FoldersState>(
          builder: (context, state) {
            final folders = (state is FoldersLoadSuccess)
                ? state.folders
                : <Folder>[];
            return SpeedDial(
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
                  onTap: () => _showCreateFolderDialog(context, folders),
                ),
                SpeedDialChild(
                  child: const Icon(Icons.note_add),
                  label: 'Create Note',
                  onTap: () {
                    final newDocument = NoteDocument(
                      id: const Uuid().v4(),
                      title: 'Untitled Note',
                      pages: [
                        NotePage(
                          pageNumber: 0,
                          strokes: [],
                          paperSettings: PaperSettings(
                            paperType: PaperType.plain,
                            paperSize: PaperSize.a4,
                            options: PlainPaperOptions(
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (_) =>
                              DocumentBloc(NotesDatabaseService.instance),
                          child: BlocProvider(
                            create: (_) => DrawingBloc(),
                            child: NoteEditorScreen(documentId: newDocument.id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
