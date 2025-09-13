import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class FileTransferView extends StatefulWidget {
  const FileTransferView({super.key});

  @override
  State<FileTransferView> createState() => _FileTransferViewState();
}

class _FileTransferViewState extends State<FileTransferView> {
  bool _isDragOver = false;

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
                onDragDone: (details) {
                  // TODO: Handle file import
                  print('Files dropped: ${details.files.map((f) => f.path).join(', ')}');
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
            const Text(''),
            const LinearProgressIndicator(value: 0),
          ],
        ),
      ),
    );
  }
}
