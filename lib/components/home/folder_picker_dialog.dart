import 'package:flutter/material.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/i18n/strings.g.dart';

class FolderPickerDialog extends StatefulWidget {
  const FolderPickerDialog({super.key, this.currentPath});

  final String? currentPath;

  @override
  State<FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<FolderPickerDialog> {
  var _currentFolder = '/';
  List<String> _folders = [];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final children = await FileManager.getChildrenOfDirectory(_currentFolder);

      setState(() {
        _folders = children?.directories ?? [];
        _folders.sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _folders = [];
        _isLoading = false;
      });
    }
  }

  void _navigateToFolder(String folderName) {
    setState(() {
      if (_currentFolder == '/') {
        _currentFolder = '/$folderName';
      } else {
        _currentFolder = '$_currentFolder/$folderName';
      }
    });
    _loadFolders();
  }

  void _navigateUp() {
    if (_currentFolder == '/') return;

    final parts = _currentFolder.split('/');
    parts.removeLast();
    setState(() {
      _currentFolder = parts.isEmpty || parts.join('/').isEmpty
          ? '/'
          : parts.join('/');
    });
    _loadFolders();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Select Destination Folder',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Current path
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentFolder == '/' ? 'Root Folder' : _currentFolder,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Back button
            if (_currentFolder != '/')
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('.. (Parent folder)'),
                onTap: _navigateUp,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

            // Folder list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _folders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subfolders',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _folders.length,
                      itemBuilder: (context, index) {
                        final folder = _folders[index];
                        return ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(folder),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _navigateToFolder(folder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.common.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(_currentFolder),
                  icon: const Icon(Icons.check),
                  label: const Text('Move Here'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
