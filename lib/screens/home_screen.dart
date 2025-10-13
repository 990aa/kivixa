import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
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
    // TODO: Implement persistent storage of recent files
    // For now, just an empty list
    setState(() {
      _recentFiles = [];
    });
  }

  /// Pick a PDF file and open it
  Future<void> _pickAndOpenPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final pdfPath = result.files.single.path!;

        // Navigate to PDF viewer
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(pdfPath: pdfPath),
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
        title: const Text('Kivixa PDF Annotator'),
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
                'Kivixa PDF Annotator',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Annotate PDFs with smooth, vector-based strokes',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Open PDF button
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

              // Demo canvas button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/demo');
                },
                icon: const Icon(Icons.draw),
                label: const Text('Try Demo Canvas'),
                style: OutlinedButton.styleFrom(
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
                              builder: (context) =>
                                  PDFViewerScreen(pdfPath: file),
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
    return path.split(Platform.pathSeparator).last;
  }
}
