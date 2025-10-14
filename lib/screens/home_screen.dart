import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import '../screens/pdf_viewer_screen.dart';

/// Home screen with PDF file selection
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  /// Load recently opened PDF files
  Future<void> _loadRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentFilesJson = prefs.getStringList('recent_pdf_files') ?? [];

      setState(() {
        _recentFiles = recentFilesJson;
      });
    } catch (e) {
      debugPrint('Error loading recent files: $e');
      setState(() {
        _recentFiles = [];
      });
    }
  }

  /// Save a file to recent files list
  Future<void> _saveToRecentFiles(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentFilesJson = prefs.getStringList('recent_pdf_files') ?? [];

      // Remove if already exists to avoid duplicates
      recentFilesJson.remove(filePath);

      // Add to beginning of list
      recentFilesJson.insert(0, filePath);

      // Keep only last 10 files
      if (recentFilesJson.length > 10) {
        recentFilesJson.removeRange(10, recentFilesJson.length);
      }

      await prefs.setStringList('recent_pdf_files', recentFilesJson);

      setState(() {
        _recentFiles = recentFilesJson;
      });
    } catch (e) {
      debugPrint('Error saving recent file: $e');
    }
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
        await _saveToRecentFiles(pdfPath);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kivixa '),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              Icon(
                Icons.picture_as_pdf,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // App title
              Text(
                'Kivixa ',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                kIsWeb
                    ? 'Try the annotation demo (PDF viewing not available on web)'
                    : 'Annotate PDFs with smooth, vector-based strokes',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Open PDF button (now works on web and desktop)
              ElevatedButton.icon(
                onPressed: _pickAndOpenPDF,
                icon: const Icon(Icons.file_open, size: 24),
                label: const Text('Open PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),

              // Demo canvas button (always available)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/demo');
                },
                icon: const Icon(Icons.draw),
                label: const Text('Try Demo Canvas'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Recent files section
              if (_recentFiles.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Recent Files',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _recentFiles.length,
                    itemBuilder: (context, index) {
                      final file = _recentFiles[index];
                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: Text(_getFileName(file)),
                        subtitle: Text(file),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => kIsWeb
                                  ? PDFViewerScreen(pdfPath: file)
                                  : PDFViewerScreen.file(pdfPath: file),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getFileName(String path) {
    if (kIsWeb) {
      return path.split('/').last;
    }
    return path.split(Platform.pathSeparator).last;
  }
}
