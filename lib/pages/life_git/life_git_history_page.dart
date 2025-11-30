import 'package:flutter/material.dart';
import 'package:kivixa/services/life_git/life_git.dart';

/// Page showing the full commit history
class LifeGitHistoryPage extends StatefulWidget {
  const LifeGitHistoryPage({super.key, this.filePath});

  /// If provided, show history for a specific file only
  final String? filePath;

  @override
  State<LifeGitHistoryPage> createState() => _LifeGitHistoryPageState();
}

class _LifeGitHistoryPageState extends State<LifeGitHistoryPage> {
  var _commits = <LifeGitCommit>[];
  var _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadStats();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      List<LifeGitCommit> commits;
      if (widget.filePath != null) {
        commits = await LifeGitService.instance.getFileHistory(
          widget.filePath!,
          limit: 100,
        );
      } else {
        commits = await LifeGitService.instance.getHistory(limit: 100);
      }

      setState(() {
        _commits = commits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _commits = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    final stats = await LifeGitService.instance.getStorageStats();
    if (mounted) {
      setState(() => _stats = stats);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filePath != null ? 'File History' : 'Life Git History',
        ),
        actions: [
          if (_stats != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_stats!['commitCount']} commits • ${_stats!['objectsSizeFormatted']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'backup':
                  await _createBackup();
                case 'gc':
                  await _runGarbageCollection();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    Icon(Icons.backup, size: 20),
                    SizedBox(width: 8),
                    Text('Create Full Backup'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'gc',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, size: 20),
                    SizedBox(width: 8),
                    Text('Clean Up Storage'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _commits.isEmpty
          ? _buildEmptyState(colorScheme)
          : _buildCommitList(colorScheme),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'History will appear as you edit notes',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _createBackup,
            icon: const Icon(Icons.backup),
            label: const Text('Create Backup Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitList(ColorScheme colorScheme) {
    // Group commits by date
    final groupedCommits = <String, List<LifeGitCommit>>{};
    for (final commit in _commits) {
      final dateKey = _formatDate(commit.timestamp);
      groupedCommits.putIfAbsent(dateKey, () => []).add(commit);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedCommits.length,
      itemBuilder: (context, index) {
        final dateKey = groupedCommits.keys.elementAt(index);
        final commits = groupedCommits[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            // Commits for this date
            ...commits.map((commit) => _buildCommitTile(commit, colorScheme)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildCommitTile(LifeGitCommit commit, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showCommitDetails(commit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Commit indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    commit.shortHash.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'FiraMono',
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Commit details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            commit.shortHash,
                            style: TextStyle(
                              fontFamily: 'FiraMono',
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(commit.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      commit.message,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${commit.snapshots.length} file${commit.snapshots.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommitDetails(LifeGitCommit commit) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          commit.shortHash,
                          style: TextStyle(
                            fontFamily: 'FiraMono',
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        commit.ageString,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    commit.message,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(commit.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Files list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: commit.snapshots.length,
                itemBuilder: (context, index) {
                  final snapshot = commit.snapshots[index];
                  return ListTile(
                    leading: Icon(
                      snapshot.exists ? Icons.insert_drive_file : Icons.delete,
                      color: snapshot.exists
                          ? colorScheme.primary
                          : colorScheme.error,
                    ),
                    title: Text(
                      snapshot.path,
                      style: const TextStyle(
                        fontFamily: 'FiraMono',
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      snapshot.exists
                          ? 'Modified ${_formatDateTime(snapshot.modifiedAt)}'
                          : 'Deleted',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    try {
      final commit = await LifeGitService.instance.createFullBackup(
        message: 'Manual backup',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup created: ${commit.snapshots.length} files saved',
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _loadHistory();
        await _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runGarbageCollection() async {
    try {
      final removed = await LifeGitService.instance.garbageCollect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleaned up $removed unused objects'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleanup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final commitDate = DateTime(date.year, date.month, date.day);

    if (commitDate == today) {
      return 'Today';
    } else if (commitDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
  }
}
