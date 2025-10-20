import 'package:flutter/material.dart';
import '../database/folder_repository.dart';
import '../database/document_repository.dart';
import '../database/tag_repository.dart';
import '../models/folder.dart';
import '../models/drawing_document.dart';
import '../widgets/folder_tree_view.dart';
import '../widgets/search_filter_panel.dart';
import '../widgets/document_grid_view.dart';

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
  bool _isLoading = true;
  bool _showFilters = false;
  int _gridColumns = 3;

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
            return ListTile(
              title: Text('$size columns'),
              leading: Radio<int>(
                value: size,
                groupValue: _gridColumns,
                onChanged: (value) {
                  setState(() => _gridColumns = value!);
                  Navigator.pop(context);
                },
              ),
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
    // TODO: Implement document creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document creation not implemented yet')),
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
    // TODO: Navigate to document editor
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening: ${document.name}')));
  }

  void _renameFolder(Folder folder) {
    // TODO: Implement folder rename
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

    if (confirmed == true && folder.id != null) {
      await folderRepo.delete(folder.id!);
      _loadData();
    }
  }

  void _createSubfolder(Folder parentFolder) {
    // TODO: Implement subfolder creation
  }

  void _renameDocument(DrawingDocument document) {
    // TODO: Implement document rename
  }

  void _moveDocument(DrawingDocument document) {
    // TODO: Implement document move
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

    if (confirmed == true && document.id != null) {
      await documentRepo.delete(document.id!);
      _loadDocuments();
    }
  }
}
