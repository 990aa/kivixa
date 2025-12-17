import 'dart:io';

import 'package:flutter/material.dart';

/// Overlay widget for displaying and editing comments on media.
///
/// Behavior:
/// - **Windows/Desktop**: Shows on mouse hover after 500ms delay
/// - **Android/Mobile**: Shows tap icon in corner, tap to display
class MediaCommentOverlay extends StatefulWidget {
  const MediaCommentOverlay({
    super.key,
    required this.comment,
    required this.onCommentChanged,
    required this.child,
    this.enabled = true,
  });

  /// The current comment text
  final String? comment;

  /// Callback when comment is edited
  final ValueChanged<String?> onCommentChanged;

  /// The child widget to wrap
  final Widget child;

  /// Whether the comment feature is enabled
  final bool enabled;

  @override
  State<MediaCommentOverlay> createState() => _MediaCommentOverlayState();
}

class _MediaCommentOverlayState extends State<MediaCommentOverlay> {
  var _isHovering = false;
  var _showComment = false;
  var _isEditing = false;
  final _commentController = TextEditingController();
  final _hoverDelay = const Duration(milliseconds: 500);

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  bool get _hasComment => widget.comment != null && widget.comment!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.comment ?? '';
  }

  @override
  void didUpdateWidget(MediaCommentOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment != widget.comment) {
      _commentController.text = widget.comment ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    if (!_isDesktop || !widget.enabled) return;
    setState(() => _isHovering = true);

    // Show after delay
    Future.delayed(_hoverDelay, () {
      if (_isHovering && mounted) {
        setState(() => _showComment = true);
      }
    });
  }

  void _onHoverEnd() {
    if (!_isDesktop) return;
    setState(() {
      _isHovering = false;
      if (!_isEditing) {
        _showComment = false;
      }
    });
  }

  void _toggleComment() {
    setState(() => _showComment = !_showComment);
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _saveComment() {
    final newComment = _commentController.text.trim();
    widget.onCommentChanged(newComment.isEmpty ? null : newComment);
    setState(() {
      _isEditing = false;
      if (!_isHovering) {
        _showComment = false;
      }
    });
  }

  void _deleteComment() {
    widget.onCommentChanged(null);
    _commentController.clear();
    setState(() {
      _isEditing = false;
      _showComment = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Mouse region for hover detection on desktop
        if (_isDesktop)
          MouseRegion(
            onEnter: (_) => _onHoverStart(),
            onExit: (_) => _onHoverEnd(),
            child: widget.child,
          )
        else
          widget.child,

        // Comment icon for mobile
        if (!_isDesktop && _hasComment)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _toggleComment,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.comment,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),

        // Add comment button (when no comment exists)
        if (!_hasComment && _showComment)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              icon: const Icon(Icons.add_comment, size: 16),
              onPressed: () {
                setState(() => _isEditing = true);
              },
              tooltip: 'Add comment',
              visualDensity: VisualDensity.compact,
            ),
          ),

        // Comment overlay
        if (_showComment && (_hasComment || _isEditing))
          Positioned(top: 40, right: 8, child: _buildCommentBox(context)),
      ],
    );
  }

  Widget _buildCommentBox(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: _isEditing
            ? _buildEditMode(colorScheme)
            : _buildViewMode(colorScheme),
      ),
    );
  }

  Widget _buildViewMode(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Comment',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _startEditing,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              InkWell(
                onTap: _deleteComment,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete, size: 14, color: colorScheme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.comment ?? '',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _commentController,
            autofocus: true,
            maxLines: 4,
            minLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter comment...',
              isDense: true,
              contentPadding: const EdgeInsets.all(8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _commentController.text = widget.comment ?? '';
                  setState(() => _isEditing = false);
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _saveComment, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}
