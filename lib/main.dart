import 'package:flutter/material.dart';
import 'package:kivixa/helpers/database_helper.dart';
import 'package:kivixa/models/folder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  final TextEditingController _folderNameController = TextEditingController();
  SortType _sortType = SortType.name;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await DatabaseHelper().getFolders();
    setState(() {
      _folders = folders;
      _sortFolders();
    });
  }

  void _sortFolders() {
    if (_sortType == SortType.name) {
      _folders.sort((a, b) => a.name.compareTo(b.name));
    } else {
      _folders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Future<void> _addFolder() async {
    if (_folderNameController.text.isNotEmpty) {
      final newFolder = Folder(
        name: _folderNameController.text,
        cover: 'assets/folder.png',
        createdAt: DateTime.now(),
      );
      await DatabaseHelper().insertFolder(newFolder);
      _folderNameController.clear();
      _loadFolders();
    }
  }

  Future<void> _renameFolder(Folder folder) async {
    _folderNameController.text = folder.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            controller: _folderNameController,
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
                if (_folderNameController.text.isNotEmpty) {
                  folder.name = _folderNameController.text;
                  await DatabaseHelper().updateFolder(folder);
                  _folderNameController.clear();
                  _loadFolders();
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
    _loadFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kivixa'),
        actions: [
          PopupMenuButton<SortType>(
            onSelected: (SortType result) {
              setState(() {
                _sortType = result;
                _sortFolders();
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
        itemCount: _folders.length,
        itemBuilder: (BuildContext ctx, index) {
          final folder = _folders[index];
          return GestureDetector(
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
                image: DecorationImage(
                  image: AssetImage(folder.cover),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                folder.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('New Folder'),
                content: TextField(
                  controller: _folderNameController,
                  decoration:
                      const InputDecoration(hintText: 'Enter folder name'),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum SortType { name, date }