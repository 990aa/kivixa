import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kivixa/services/life_git/life_git.dart';

/// A time travel slider widget that allows navigating through file history
class TimeTravelSlider extends StatefulWidget {
  const TimeTravelSlider({
    super.key,
    required this.filePath,
    required this.onHistoryContent,
    required this.onExitTimeTravel,
    this.showCommitDetails = true,
  });

  /// The path of the file to show history for
  final String filePath;

  /// Called when user navigates to a historical version
  final void Function(Uint8List content, LifeGitCommit commit) onHistoryContent;

  /// Called when user exits time travel mode
  final VoidCallback onExitTimeTravel;

  /// Whether to show commit details below the slider
  final bool showCommitDetails;

  @override
  State<TimeTravelSlider> createState() => _TimeTravelSliderState();
}

class _TimeTravelSliderState extends State<TimeTravelSlider> {
  var _commits = <LifeGitCommit>[];
  var _currentIndex = 0;
  var _isLoading = true;
  LifeGitCommit? _selectedCommit;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(TimeTravelSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final commits = await LifeGitService.instance.getFileHistory(
        widget.filePath,
        limit: 100,
      );

      setState(() {
        _commits = commits;
        _currentIndex = 0;
        _selectedCommit = commits.isNotEmpty ? commits.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _commits = [];
        _isLoading = false;
      });
    }
  }

  void _onSliderChanged(double value) {
    final index = value.round();
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
      _selectedCommit = _commits.isNotEmpty ? _commits[index] : null;
    });

    // Debounce the content loading
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _loadContentAtIndex(index);
    });
  }

  Future<void> _loadContentAtIndex(int index) async {
    if (_commits.isEmpty || index >= _commits.length) return;

    final commit = _commits[index];
    final content = await LifeGitService.instance.getFileAtCommit(
      widget.filePath,
      commit.hash,
    );

    if (content != null && mounted) {
      widget.onHistoryContent(content, commit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading history...'),
          ],
        ),
      );
    }

    if (_commits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Text(
              'No history available',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.onExitTimeTravel,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Exit'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with title and exit button
          Row(
            children: [
              Icon(Icons.history, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Time Travel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (_selectedCommit != null)
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
                    _selectedCommit!.shortHash,
                    style: TextStyle(
                      fontFamily: 'FiraMono',
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onExitTimeTravel,
                tooltip: 'Exit Time Travel',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Slider with time labels
          Row(
            children: [
              Text(
                _commits.isNotEmpty ? _commits.last.ageString : '',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _currentIndex.toDouble(),
                  min: 0,
                  max: (_commits.length - 1).toDouble().clamp(
                    0,
                    double.infinity,
                  ),
                  divisions: _commits.length > 1 ? _commits.length - 1 : null,
                  onChanged: _onSliderChanged,
                ),
              ),
              Text(
                'Now',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // Commit details
          if (widget.showCommitDetails && _selectedCommit != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.commit,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedCommit!.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedCommit!.ageString,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Reset to current version
                    setState(() => _currentIndex = 0);
                    _loadContentAtIndex(0);
                  },
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Latest'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _selectedCommit != null && _currentIndex > 0
                      ? () => _showRestoreDialog(context)
                      : null,
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Restore This'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestoreDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will restore the file to this version:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCommit!.message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedCommit!.shortHash} • ${_selectedCommit!.ageString}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your current version will be saved before restoring.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && _selectedCommit != null) {
      await _restoreVersion();
    }
  }

  Future<void> _restoreVersion() async {
    if (_selectedCommit == null) return;

    // The parent widget should handle the actual restoration
    final content = await LifeGitService.instance.getFileAtCommit(
      widget.filePath,
      _selectedCommit!.hash,
    );

    if (content != null && mounted) {
      widget.onHistoryContent(content, _selectedCommit!);
      widget.onExitTimeTravel();
    }
  }
}

/// A compact time travel button that opens a dialog
class TimeTravelButton extends StatelessWidget {
  const TimeTravelButton({
    super.key,
    required this.filePath,
    required this.onEnterTimeTravel,
  });

  final String filePath;
  final VoidCallback onEnterTimeTravel;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.history),
      tooltip: 'Time Travel',
      onPressed: onEnterTimeTravel,
    );
  }
}

/// A widget that shows a timeline of commits for a file
class FileHistoryTimeline extends StatefulWidget {
  const FileHistoryTimeline({
    super.key,
    required this.filePath,
    required this.onCommitSelected,
  });

  final String filePath;
  final void Function(LifeGitCommit commit) onCommitSelected;

  @override
  State<FileHistoryTimeline> createState() => _FileHistoryTimelineState();
}

class _FileHistoryTimelineState extends State<FileHistoryTimeline> {
  var _commits = <LifeGitCommit>[];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final commits = await LifeGitService.instance.getFileHistory(
        widget.filePath,
      );
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_commits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No history available',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _commits.length,
      itemBuilder: (context, index) {
        final commit = _commits[index];
        final isFirst = index == 0;

        return InkWell(
          onTap: () => widget.onCommitSelected(commit),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline connector
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFirst
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                    ),
                    if (index < _commits.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: colorScheme.outlineVariant,
                      ),
                  ],
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
                            commit.ageString,
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
                        style: TextStyle(
                          fontWeight: isFirst ? FontWeight.bold : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
