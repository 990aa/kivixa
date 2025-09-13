import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/services/import_manager.dart';

class FileTransferView extends StatefulWidget {
  final ImportManager importManager;

  const FileTransferView({super.key, required this.importManager});

  @override
  State<FileTransferView> createState() => _FileTransferViewState();
}

class _FileTransferViewState extends State<FileTransferView> {
  bool _isDragOver = false;
  double _importProgress = 0.0;
  String _importStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import & Export'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Drag and drop import zone
            Expanded(
              child: DropTarget(
                onDragDone: (details) async {
                  final files = details.files;
                  if (files.isNotEmpty) {
                    setState(() {
                      _importStatus = 'Importing ${files.first.name}...';
                      _importProgress = 0.0;
                    });
                    try {
                      await widget.importManager.importFile(
                        files.first.path,
                        onProgress: (progress) {
                          setState(() {
                            _importProgress = progress;
                          });
                        },
                      );
                      setState(() {
                        _importStatus = 'Successfully imported ${files.first.name}';
                        _importProgress = 1.0;
                      });
                    } catch (e) {
                      setState(() {
                        _importStatus = 'Error importing ${files.first.name}';
                        _importProgress = 0.0;
                      });
                    }
                  }
                },
                onDragEntered: (details) {
                  setState(() {
                    _isDragOver = true;
                  });
                },
                onDragExited: (details) {
                  setState(() {
                    _isDragOver = false;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isDragOver ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, size: 50),
                        SizedBox(height: 16),
                        Text('Drag and drop files here to import'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Export button
            ElevatedButton(
              onPressed: () {
                // TODO: Implement export functionality
              },
              child: const Text('Export Documents'),
            ),
            const SizedBox(height: 24),
            // Progress indicator section
            Text(_importStatus),
            LinearProgressIndicator(value: _importProgress),
          ],
        ),
      ),
    );
  }
}
