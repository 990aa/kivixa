import 'package:flutter/material.dart';
import 'package:kivixa/database/folder_repository.dart';
import 'package:kivixa/database/document_repository.dart';
import 'package:kivixa/database/tag_repository.dart';
import 'package:kivixa/models/folder.dart';
import 'package:kivixa/models/drawing_document.dart';
import 'package:kivixa/widgets/folder_tree_view.dart';
import 'package:kivixa/widgets/search_filter_panel.dart';
import 'package:kivixa/widgets/document_grid_view.dart';

/// Comprehensive file browser screen integrating all organization features
///
/// Features:
/// - Split view: Folder tree + Document grid
/// - Advanced search and filtering
/// - Document operations (rename, move, delete)
/// - Folder operations (create, rename, delete)
/// - Tag management
/// - Sort and view options
class FileBrowserScreen extends StatefulWidget {
  const FileBrowserScreen({super.key});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  final folderRepo = FolderRepository();
  final documentRepo = DocumentRepository();
  final tagRepo = TagRepository();

  List<Folder> _folders = [];
  List<DrawingDocument> _documents = [];
  Folder? _selectedFolder;
  SearchFilterCriteria? _filterCriteria;
  var _isLoading = true;
  var _showFilters = false;
  var _gridColumns = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load folder hierarchy
      _folders = await folderRepo.getFolderHierarchy();

      // Load documents
      await _loadDocuments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDocuments() async {
    try {
      if (_filterCriteria != null && _filterCriteria!.hasActiveFilters) {
        // Use advanced search with filters
        _documents = await documentRepo.searchDocuments(
          searchQuery: _filterCriteria!.searchQuery,
          types: _filterCriteria!.types,
          tagIds: _filterCriteria!.tagIds,
          folderId: _selectedFolder?.id,
          includeSubfolders: true,
          favoritesOnly: _filterCriteria!.favoritesOnly,
          sortBy: _filterCriteria!.sortBy,
        );
      } else {
        // Simple folder view
        _documents = await documentRepo.getByFolder(
          _selectedFolder?.id,
          sortBy: _filterCriteria?.sortBy ?? DocumentSortBy.dateModifiedDesc,
        );
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading documents: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Browser'),
        actions: [
          // Grid size toggle
          IconButton(
            icon: const Icon(Icons.view_module),
            onPressed: _showGridSizeDialog,
            tooltip: 'Grid size',
          ),

          // Filter toggle
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            tooltip: 'Filters',
          ),

          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left panel: Folder tree
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      // Folder tree header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Folders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.create_new_folder),
                              onPressed: _showCreateFolderDialog,
                              tooltip: 'New folder',
                            ),
                          ],
                        ),
                      ),

                      // Folder tree
                      Expanded(
                        child: FolderTreeView(
                          folders: _folders,
                          selectedFolder: _selectedFolder,
                          onFolderSelected: (folder) {
                            setState(() => _selectedFolder = folder);
                            _loadDocuments();
                          },
                          onFolderLongPress: (folder) {
                            _showFolderContextMenu(folder);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),

                // Right panel: Documents and filters
                Expanded(
                  child: Column(
                    children: [
                      // Breadcrumb
                      if (_selectedFolder != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedFolder!.subfolders.isEmpty
                                    ? Icons.folder
                                    : Icons.folder_open,
                                color: _selectedFolder!.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedFolder!.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_documents.length} document${_documents.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Filter panel (collapsible)
                      if (_showFilters)
                        Container(
                          height: 400,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: SearchFilterPanel(
                            initialCriteria: _filterCriteria,
                            onFilterChanged: (criteria) {
                              setState(() => _filterCriteria = criteria);
                              _loadDocuments();
                            },
                          ),
                        ),

                      // Document grid
                      Expanded(
                        child: DocumentGridView(
                          documents: _documents,
                          crossAxisCount: _gridColumns,
                          onDocumentTap: (document) {
                            _openDocument(document);
                          },
                          onDocumentLongPress: (document) {
                            _showDocumentContextMenu(document);
                          },
                          onFavoriteToggle: (document, isFavorite) async {
                            await documentRepo.toggleFavorite(
                              document.id!,
                              isFavorite,
                            );
                            _loadDocuments();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDocumentDialog,
        tooltip: 'New document',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showGridSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grid Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [2, 3, 4, 5].map((size) {
            final isSelected = _gridColumns == size;
            return ListTile(
              title: Text('$size columns'),
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
              selected: isSelected,
              onTap: () {
                setState(() => _gridColumns = size);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCreateFolderDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final folder = Folder(
                  name: name,
                  parentFolderId: _selectedFolder?.id,
                  createdAt: DateTime.now(),
                  modifiedAt: DateTime.now(),
                );

                await folderRepo.insert(folder);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateDocumentDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Document'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Document name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                // Generate file path for new document
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                final filePath =
                    'documents/${_selectedFolder?.id ?? 'root'}/$timestamp.canvas';

                final document = DrawingDocument(
                  name: name,
                  folderId: _selectedFolder?.id,
                  type: DocumentType.canvas,
                  filePath: filePath,
                  fileSize: 0,
                  createdAt: DateTime.now(),
                  modifiedAt: DateTime.now(),
                  lastOpenedAt: DateTime.now(),
                  isFavorite: false,
                );

                final id = await documentRepo.insert(document);
                if (!context.mounted) return;
                Navigator.pop(context);

                // Open the newly created document
                _openDocument(document.copyWith(id: id));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showFolderContextMenu(Folder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FolderContextMenu(
        folder: folder,
        onRename: () => _renameFolder(folder),
        onDelete: () => _deleteFolder(folder),
        onCreateSubfolder: () => _createSubfolder(folder),
      ),
    );
  }

  void _showDocumentContextMenu(DrawingDocument document) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DocumentContextMenu(
        document: document,
        onOpen: () => _openDocument(document),
        onRename: () => _renameDocument(document),
        onMove: () => _moveDocument(document),
        onDelete: () => _deleteDocument(document),
      ),
    );
  }

  Future<void> _openDocument(DrawingDocument document) async {
    await documentRepo.updateLastOpened(document.id!);

    if (!mounted) return;

    // Navigate to the drawing canvas screen
    // Note: Replace 'DrawingCanvasScreen' with your actual canvas screen widget
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(document.name)),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.draw, size: 64),
                const SizedBox(height: 16),
                Text('Canvas for: ${document.name}'),
                const SizedBox(height: 8),
                const Text(
                  'Replace this with your actual DrawingCanvasScreen widget',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _renameFolder(Folder folder) {
    final nameController = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty && name != folder.name) {
                final updatedFolder = folder.copyWith(
                  name: name,
                  modifiedAt: DateTime.now(),
                );

                await folderRepo.update(updatedFolder);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadData();
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Delete "${folder.name}" and all its contents?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false && folder.id != null) {
      await folderRepo.delete(folder.id!);
      _loadData();
    }
  }

  void _createSubfolder(Folder parentFolder) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Subfolder in "${parentFolder.name}"'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final folder = Folder(
                  name: name,
                  parentFolderId: parentFolder.id,
                  createdAt: DateTime.now(),
                  modifiedAt: DateTime.now(),
                );

                await folderRepo.insert(folder);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _renameDocument(DrawingDocument document) {
    final nameController = TextEditingController(text: document.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Document name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty && name != document.name) {
                final updatedDocument = document.copyWith(
                  name: name,
                  modifiedAt: DateTime.now(),
                );

                await documentRepo.update(updatedDocument);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadDocuments();
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _moveDocument(DrawingDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move Document'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FolderTreeView(
            folders: _folders,
            selectedFolder: _folders.firstWhere(
              (f) => f.id == document.folderId,
              orElse: () => _folders.first,
            ),
            onFolderSelected: (folder) async {
              // Move document to selected folder
              final updatedDocument = document.copyWith(
                folderId: folder.id,
                modifiedAt: DateTime.now(),
              );

              await documentRepo.update(updatedDocument);
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadDocuments();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Moved "${document.name}" to "${folder.name}"'),
                ),
              );
            },
            onFolderLongPress: null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _deleteDocument(DrawingDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false && document.id != null) {
      await documentRepo.delete(document.id!);
      _loadDocuments();
    }
  }
}
