import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/helpers/database_helper.dart';
import 'package:kivixa/models/folder.dart';
import 'package:kivixa/models/pdf.dart';
import 'package:kivixa/helpers/folder_icon.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:kivixa/features/notes/screens/notes_home_screen.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kivixa',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Folder> _folders = [];
  List<Pdf> _pdfs = [];
  final TextEditingController _nameController = TextEditingController();
  SortType _sortType = SortType.name;
  int? _currentFolderId;
  final List<Folder> _folderPath = [];

  @override
  void initState() {
    super.initState();
    _loadFoldersAndPdfs();
  }

  Future<void> _loadFoldersAndPdfs() async {
    final folders = await DatabaseHelper().getFolders(_currentFolderId);
    final pdfs = _currentFolderId == null ? <Pdf>[] : await DatabaseHelper().getPdfs(_currentFolderId!);
    if (_currentFolderId != null && !_folderPath.any((f) => f.id == _currentFolderId)) {
      // This is a simplified path management. A proper implementation would fetch the folder from DB.
      // For now, we assume navigation is linear and we can add the folder if it's not there.
      // This part needs a proper implementation for deep folder navigation and path reconstruction.
    }
    setState(() {
      _folders = folders;
      _pdfs = pdfs;
      _sort();
    });
  }

  void _sort() {
    if (_sortType == SortType.name) {
      _folders.sort((a, b) => a.name.compareTo(b.name));
      _pdfs.sort((a, b) => a.name.compareTo(b.name));
    } else {
      // Sorting PDFs by date would require a createdAt field in the Pdf model.
      // For now, we only sort folders by date.
      _folders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Future<void> _addFolder() async {
    if (_nameController.text.isNotEmpty) {
      final color = getRandomColor();
      final newFolder = Folder(
        name: _nameController.text,
        cover: '', // Not used for custom icon
        createdAt: DateTime.now(),
        colorValue: color.value,
        parentId: _currentFolderId,
      );
      await DatabaseHelper().insertFolder(newFolder);
      _nameController.clear();
      _loadFoldersAndPdfs();
    }
  }

  Future<void> _renameFolder(Folder folder) async {
    _nameController.text = folder.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Enter folder name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  folder.name = _nameController.text;
                  await DatabaseHelper().updateFolder(folder);
                  _nameController.clear();
                  _loadFoldersAndPdfs();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFolder(Folder folder) async {
    await DatabaseHelper().deleteFolder(folder.id!);
    _loadFoldersAndPdfs();
  }

  Future<void> _importPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final path = result.files.single.path!;
      final fileName = p.basename(path);
      final appDir = await getApplicationDocumentsDirectory();
      final newPath = p.join(appDir.path, fileName);
      await File(path).copy(newPath);

      final newPdf = Pdf(
        name: fileName,
        path: newPath,
        folderId: _currentFolderId!,
      );
      await DatabaseHelper().insertPdf(newPdf);
      _loadFoldersAndPdfs();
    }
  }

  Future<void> _renamePdf(Pdf pdf) async {
    _nameController.text = pdf.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename PDF'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Enter PDF name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  pdf.name = _nameController.text;
                  await DatabaseHelper().updatePdf(pdf);
                  _nameController.clear();
                  _loadFoldersAndPdfs();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePdf(Pdf pdf) async {
    await DatabaseHelper().deletePdf(pdf.id!);
    final file = File(pdf.path);
    if (await file.exists()) {
      await file.delete();
    }
    _loadFoldersAndPdfs();
  }

  void _navigateToFolder(Folder folder) {
    setState(() {
      _currentFolderId = folder.id;
      _folderPath.add(folder);
    });
    _loadFoldersAndPdfs();
  }

  void _navigateToParentFolder() {
    setState(() {
      if (_folderPath.isNotEmpty) {
        _folderPath.removeLast();
        _currentFolderId = _folderPath.isEmpty ? null : _folderPath.last.id;
      } else {
        _currentFolderId = null;
      }
    });
    _loadFoldersAndPdfs();
  }

  String _getCurrentPath() {
    if (_folderPath.isEmpty) {
      return 'Home';
    }
    return 'Home > ${_folderPath.map((f) => f.name).join(' > ')}';
  }

  @override
  Widget build(BuildContext context) {
    final items = [..._folders, ..._pdfs];

    return Scaffold(
      appBar: AppBar(
        leading: _currentFolderId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateToParentFolder,
              )
            : null,
        title: Text(_getCurrentPath()),
        actions: [
          PopupMenuButton<SortType>(
            onSelected: (SortType result) {
              setState(() {
                _sortType = result;
                _sort();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortType>>[
              const PopupMenuItem<SortType>(
                value: SortType.name,
                child: Text('Sort by name'),
              ),
              const PopupMenuItem<SortType>(
                value: SortType.date,
                child: Text('Sort by date'),
              ),
            ],
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 3 / 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: items.length,
        itemBuilder: (BuildContext ctx, index) {
          final item = items[index];
          if (item is Folder) {
            return _buildFolderItem(item);
          } else if (item is Pdf) {
            return _buildPdfItem(item);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('New Folder'),
                    content: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter folder name',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _addFolder();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  );
                },
              );
            },
            heroTag: 'addFolder',
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 10),
          if (_currentFolderId != null)
            FloatingActionButton(
              onPressed: _importPdf,
              heroTag: 'importPdf',
              child: const Icon(Icons.picture_as_pdf),
            ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotesHomeScreen()),
              );
            },
            heroTag: 'notes',
            child: const Icon(Icons.note_add),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(Folder folder) {
    return GestureDetector(
      onTap: () => _navigateToFolder(folder),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Rename'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _renameFolder(folder);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteFolder(folder);
                  },
                ),
              ],
            );
          },
        );
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FolderIcon(
              folderColor: folder.colorValue != null
                  ? Color(folder.colorValue!)
                  : Colors.amber,
            ),
            const SizedBox(height: 8),
            Text(
              folder.name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfItem(Pdf pdf) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(pdfPath: pdf.path),
          ),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Rename'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _renamePdf(pdf);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deletePdf(pdf);
                  },
                ),
              ],
            );
          },
        );
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              pdf.name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String pdfPath;

  const PdfViewerScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
      ),
      body: PDFView(
        filePath: pdfPath,
      ),
    );
  }
}

enum SortType { name, date }
