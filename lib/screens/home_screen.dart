import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/markdown_editor_screen.dart';
import '../screens/infinite_canvas_screen.dart';
import '../screens/advanced_drawing_screen.dart';
import '../database/folder_repository.dart';
import '../database/document_repository.dart';
import '../models/folder.dart';
import '../models/drawing_document.dart';
import '../widgets/folder_tree_view.dart';
import '../widgets/document_grid_view.dart';

/// Home screen with file browser and creation options
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final folderRepo = FolderRepository();
  final documentRepo = DocumentRepository();

  List<Folder> _folders = [];
  List<DrawingDocument> _documents = [];
  Folder? _selectedFolder;
  bool _isLoading = true;
  final int _gridColumns = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _folders = await folderRepo.getFolderHierarchy();
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
      _documents = await documentRepo.getByFolder(
        _selectedFolder?.id,
        sortBy: DocumentSortBy.dateModifiedDesc,
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading documents: $e')));
      }
    }
  }

  Future<String?> _showNameDialog(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: hint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createMarkdown() async {
    final name = await _showNameDialog('New Markdown', 'Document name');
    if (name == null) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = 'documents/${_selectedFolder?.id ?? 'root'}/$timestamp.md';

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

    await documentRepo.insert(document);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MarkdownEditorScreen()),
    ).then((_) => _loadDocuments());
  }

  Future<void> _createCanvas(bool isInfinite) async {
    final name = await _showNameDialog(
      isInfinite ? 'New Infinite Canvas' : 'New Canvas',
      'Canvas name',
    );
    if (name == null) return;

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

    await documentRepo.insert(document);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => isInfinite
            ? const InfiniteCanvasScreen()
            : const AdvancedDrawingScreen(),
      ),
    ).then((_) => _loadDocuments());
  }

  /// Pick a PDF file and open it
  Future<void> _pickAndOpenPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: kIsWeb, // ensure bytes on web
      );

      if (result == null) return;

      if (kIsWeb) {
        // Open using memory bytes
        final bytes = result.files.single.bytes;
        if (bytes != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen.memory(pdfBytes: bytes),
            ),
          );
        }
        return;
      }

      // Desktop/Mobile path
      if (result.files.single.path != null) {
        final pdfPath = result.files.single.path!;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen.file(pdfPath: pdfPath),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening PDF: $e')));
      }
    }
  }

  void _showCanvasTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Canvas Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_out),
              title: const Text('Infinite Canvas'),
              subtitle: const Text('Unlimited drawing space'),
              onTap: () {
                Navigator.pop(context);
                _createCanvas(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_square),
              title: const Text('Custom Size Canvas'),
              subtitle: const Text('Fixed size drawing area'),
              onTap: () {
                Navigator.pop(context);
                _createCanvas(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kivixa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Quick action buttons at top
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickAndOpenPDF,
                          icon: const Icon(Icons.picture_as_pdf, size: 20),
                          label: const Text('Import PDF'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _createMarkdown,
                          icon: const Icon(Icons.edit_document, size: 20),
                          label: const Text('Markdown'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showCanvasTypeDialog,
                          icon: const Icon(Icons.brush, size: 20),
                          label: const Text('Canvas'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // File browser content
                Expanded(
                  child: Row(
                    children: [
                      // Left panel: Folder tree
                      SizedBox(
                        width: 300,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
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
                                    onPressed: () async {
                                      final name = await _showNameDialog(
                                        'New Folder',
                                        'Folder name',
                                      );
                                      if (name != null) {
                                        final folder = Folder(
                                          name: name,
                                          parentFolderId: _selectedFolder?.id,
                                          createdAt: DateTime.now(),
                                          modifiedAt: DateTime.now(),
                                        );
                                        await folderRepo.insert(folder);
                                        _loadData();
                                      }
                                    },
                                    tooltip: 'New folder',
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: FolderTreeView(
                                folders: _folders,
                                selectedFolder: _selectedFolder,
                                onFolderSelected: (folder) {
                                  setState(() => _selectedFolder = folder);
                                  _loadDocuments();
                                },
                                onFolderLongPress: null,
                              ),
                            ),
                          ],
                        ),
                      ),

                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Colors.grey.shade300,
                      ),

                      // Right panel: Documents
                      Expanded(
                        child: Column(
                          children: [
                            if (_selectedFolder != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.folder,
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
                            Expanded(
                              child: (_documents.isEmpty)
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.folder_open,
                                            size: 64,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No documents yet',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Create a new document using the buttons above',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : DocumentGridView(
                                      documents: _documents,
                                      crossAxisCount: _gridColumns,
                                      onDocumentTap: (document) async {
                                        await documentRepo.updateLastOpened(
                                          document.id!,
                                        );
                                        
                                        if (!mounted) return;
                                        
                                        // Navigate to appropriate viewer based on document type
                                        Widget screen;
                                        switch (document.type) {
                                          case DocumentType.pdf:
                                            screen = PDFViewerScreen.file(
                                              pdfPath: document.filePath,
                                            );
                                            break;
                                          case DocumentType.image:
                                            // For images, use the advanced drawing screen
                                            screen = const AdvancedDrawingScreen();
                                            break;
                                          case DocumentType.canvas:
                                            // Check if it's a markdown file by extension
                                            if (document.filePath.endsWith('.md')) {
                                              screen = const MarkdownEditorScreen();
                                            } else {
                                              // Default to canvas screen
                                              screen = const InfiniteCanvasScreen();
                                            }
                                            break;
                                        }
                                        
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => screen),
                                        ).then((_) => _loadDocuments());
                                      },
                                      onDocumentLongPress: null,
                                      onFavoriteToggle:
                                          (document, isFavorite) async {
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
                ),
              ],
            ),
    );
  }
}
