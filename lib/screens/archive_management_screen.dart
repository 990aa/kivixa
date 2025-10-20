import 'package:flutter/material.dart';
import '../models/archived_document.dart';
import '../services/archive_service.dart';

/// Archive management screen
///
/// Displays archived documents with:
/// - List of all archived documents
/// - Storage statistics
/// - Manual unarchive
/// - Auto-archive configuration
/// - Cleanup invalid archives
class ArchiveManagementScreen extends StatefulWidget {
  const ArchiveManagementScreen({super.key});

  @override
  State<ArchiveManagementScreen> createState() =>
      _ArchiveManagementScreenState();
}

class _ArchiveManagementScreenState extends State<ArchiveManagementScreen> {
  final ArchiveService _archiveService = ArchiveService();

  List<ArchivedDocument> _archives = [];
  Map<String, String> _stats = {};
  bool _isLoading = true;
  int _autoArchiveDays = 90;
  bool _excludeFavorites = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final archives = await _archiveService.getAllArchivedWithDocuments();
      final stats = await _archiveService.getFormattedStorageStats();

      setState(() {
        _archives = archives;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading archives: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unarchiveDocument(ArchivedDocument archive) async {
    try {
      await _archiveService.unarchiveDocument(archive);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document unarchived successfully')),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error unarchiving: $e')));
      }
    }
  }

  Future<void> _deleteArchive(ArchivedDocument archive) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Archive'),
        content: const Text(
          'This will permanently delete the archived file. '
          'The original document will be lost. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _archiveService.deleteArchive(archive.id!);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Archive deleted')));
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  Future<void> _runAutoArchive() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Auto-Archive'),
        content: Text(
          'Archive documents not opened in $_autoArchiveDays days?\n'
          '${_excludeFavorites ? 'Favorites will be excluded.' : 'Favorites will be included.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Archiving documents...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final archived = await _archiveService.runAutoArchive(
        daysThreshold: _autoArchiveDays,
        excludeFavorites: _excludeFavorites,
      );

      if (mounted) {
        Navigator.pop(context); // Close progress dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archived ${archived.length} documents')),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cleanupInvalidArchives() async {
    try {
      final cleaned = await _archiveService.cleanupInvalidArchives();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleaned up $cleaned invalid archives')),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAutoArchiveSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Auto-Archive Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Archive documents not opened in:'),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: _autoArchiveDays,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                  DropdownMenuItem(value: 60, child: Text('60 days')),
                  DropdownMenuItem(value: 90, child: Text('90 days')),
                  DropdownMenuItem(value: 180, child: Text('180 days')),
                  DropdownMenuItem(value: 365, child: Text('1 year')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => _autoArchiveDays = value);
                    setState(() => _autoArchiveDays = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Exclude favorites'),
                value: _excludeFavorites,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => _excludeFavorites = value);
                    setState(() => _excludeFavorites = value);
                  }
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _runAutoArchive();
              },
              child: const Text('Run Now'),
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
        title: const Text('Archive Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showAutoArchiveSettings,
            tooltip: 'Auto-archive settings',
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _cleanupInvalidArchives,
            tooltip: 'Cleanup invalid archives',
          ),
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
                // Statistics Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage Statistics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Total Archives',
                          _stats['totalArchives'] ?? '0',
                        ),
                        _buildStatRow(
                          'Original Size',
                          _stats['totalOriginalSize'] ?? '0 B',
                        ),
                        _buildStatRow(
                          'Archived Size',
                          _stats['totalArchivedSize'] ?? '0 B',
                        ),
                        _buildStatRow(
                          'Space Saved',
                          _stats['totalSpaceSaved'] ?? '0 B',
                        ),
                        _buildStatRow(
                          'Avg. Compression',
                          _stats['avgCompressionRatio'] ?? '0%',
                        ),
                        _buildStatRow(
                          'Space Saving',
                          _stats['spaceSavingPercentage'] ?? '0%',
                        ),
                      ],
                    ),
                  ),
                ),

                // Archives List
                Expanded(
                  child: _archives.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.archive, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No archived documents'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _archives.length,
                          itemBuilder: (context, index) {
                            final archive = _archives[index];
                            return _buildArchiveItem(archive);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildArchiveItem(ArchivedDocument archive) {
    final document = archive.document;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          archive.autoArchived ? Icons.auto_awesome : Icons.archive,
          color: archive.autoArchived ? Colors.blue : Colors.grey,
        ),
        title: Text(document?.name ?? 'Unknown Document'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${archive.originalSizeFormatted} → ${archive.archivedSizeFormatted}',
            ),
            Text(
              'Saved ${archive.spaceSavedFormatted} (${archive.compressionPercentage})',
              style: TextStyle(color: Colors.green[700]),
            ),
            Text('Archived ${archive.archivedRelative}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'unarchive') {
              _unarchiveDocument(archive);
            } else if (value == 'delete') {
              _deleteArchive(archive);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'unarchive',
              child: ListTile(
                leading: Icon(Icons.unarchive),
                title: Text('Unarchive'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
