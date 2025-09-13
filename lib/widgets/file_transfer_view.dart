import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/services/export_manager.dart';
import 'package:kivixa/services/import_manager.dart';

class FileTransferView extends StatefulWidget {
  final ImportManager importManager;
  final ExportManager exportManager;

  const FileTransferView({
    super.key,
    required this.importManager,
    required this.exportManager,
  });

  @override
  State<FileTransferView> createState() => _FileTransferViewState();
}

class _FileTransferViewState extends State<FileTransferView>
    with SingleTickerProviderStateMixin {
  bool _isDragOver = false;
  double _progress = 0.0;
  String _status = '';
  bool _isComplete = false;

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showCompletion() {
    setState(() {
      _isComplete = true;
    });
    _animationController.forward(from: 0.0);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isComplete = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import & Export'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              children: [
                // Drag and drop import zone
                Expanded(
                  child: DropTarget(
                    onDragDone: (details) async {
                      final files = details.files;
                      if (files.isNotEmpty) {
                        setState(() {
                          _status = 'Importing ${files.first.name}...';
                          _progress = 0.0;
                        });
                        try {
                          await widget.importManager.importFile(
                            files.first.path,
                            onProgress: (progress) {
                              setState(() {
                                _progress = progress;
                              });
                            },
                          );
                          setState(() {
                            _status =
                                'Successfully imported ${files.first.name}';
                            _progress = 1.0;
                          });
                          _showCompletion();
                        } catch (e) {
                          setState(() {
                            _status = 'Error importing ${files.first.name}';
                            _progress = 0.0;
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
                  onPressed: () async {
                    final result = await FilePicker.platform.saveFile(
                      dialogTitle: 'Save Kivixa Export',
                      fileName: 'export.kivixa',
                    );
                    if (result != null) {
                      setState(() {
                        _status = 'Exporting...';
                        _progress = 0.0;
                      });
                      try {
                        await widget.exportManager.exportToKivixaZip(
                          'dummy_document_id', // Replace with actual document ID
                          result,
                          onProgress: (progress) {
                            setState(() {
                              _progress = progress;
                            });
                          },
                        );
                        setState(() {
                          _status = 'Successfully exported to $result';
                          _progress = 1.0;
                        });
                        _showCompletion();
                      } catch (e) {
                        setState(() {
                          _status = 'Error exporting document';
                          _progress = 0.0;
                        });
                      }
                    }
                  },
                  child: const Text('Export Documents'),
                ),
                const SizedBox(height: 24),
                // Progress indicator section
                Text(_status),
                LinearProgressIndicator(value: _progress),
              ],
            ),
            if (_isComplete)
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FileTransferView extends StatefulWidget {
  final ImportManager importManager;
  final ExportManager exportManager;

  const FileTransferView({
    super.key,
    required this.importManager,
    required this.exportManager,
  });

  @override
  State<FileTransferView> createState() => _FileTransferViewState();
}

class _FileTransferViewState extends State<FileTransferView> {
  bool _isDragOver = false;
  double _progress = 0.0;
  String _status = '';

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
                      _status = 'Importing ${files.first.name}...';
                      _progress = 0.0;
                    });
                    try {
                      await widget.importManager.importFile(
                        files.first.path,
                        onProgress: (progress) {
                          setState(() {
                            _progress = progress;
                          });
                        },
                      );
                      setState(() {
                        _status = 'Successfully imported ${files.first.name}';
                        _progress = 1.0;
                      });
                    } catch (e) {
                      setState(() {
                        _status = 'Error importing ${files.first.name}';
                        _progress = 0.0;
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
              onPressed: () async {
                final result = await FilePicker.platform.saveFile(
                  dialogTitle: 'Save Kivixa Export',
                  fileName: 'export.kivixa',
                );
                if (result != null) {
                  setState(() {
                    _status = 'Exporting...';
                    _progress = 0.0;
                  });
                  try {
                    await widget.exportManager.exportToKivixaZip(
                      'dummy_document_id', // Replace with actual document ID
                      result,
                      onProgress: (progress) {
                        setState(() {
                          _progress = progress;
                        });
                      },
                    );
                    setState(() {
                      _status = 'Successfully exported to $result';
                      _progress = 1.0;
                    });
                  } catch (e) {
                    setState(() {
                      _status = 'Error exporting document';
                      _progress = 0.0;
                    });
                  }
                }
              },
              child: const Text('Export Documents'),
            ),
            const SizedBox(height: 24),
            // Progress indicator section
            Text(_status),
            LinearProgressIndicator(value: _progress),
          ],
        ),
      ),
    );
  }
}
