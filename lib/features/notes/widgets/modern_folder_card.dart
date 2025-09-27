import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/widgets/animated_progress_ring.dart';
import 'package:mix/mix.dart';

class ModernFolderCard extends StatefulWidget {
  const ModernFolderCard({
    super.key,
    required this.folder,
    this.onTap,
    this.onDelete,
    this.onMove,
    this.onRename,
    this.onFavorite,
    this.isSelected = false,
  });

  final Folder folder;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMove;
  final VoidCallback? onRename;
  final VoidCallback? onFavorite;
  final bool isSelected;

  @override
  State<ModernFolderCard> createState() => _ModernFolderCardState();
}

class _ModernFolderCardState extends State<ModernFolderCard> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimaryContainer = theme.colorScheme.onPrimaryContainer;

    final containerStyle = Style(
      $box.borderRadius.all(16),
      $box.padding.all(16),
      $box.shadow(
        color: widget.folder.color.withAlpha((255 * 0.3).round()),
        blurRadius: 20,
        spreadRadius: -5,
        offset: const Offset(0, 8),
      ),
      $flex.mainAxisAlignment.spaceBetween(),
      $flex.crossAxisAlignment.start(),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? [
                      widget.folder.color.withAlpha((255 * 0.4).round()),
                      widget.folder.color.withAlpha((255 * 0.3).round()),
                    ]
                  : [
                      widget.folder.color.withAlpha((255 * 0.2).round()),
                      widget.folder.color.withAlpha((255 * 0.1).round()),
                    ],
              stops: const [0.1, 1],
            ),
            border: Border.all(
              width: 1.5,
              color: _isHovered
                  ? Colors.white.withAlpha((255 * 0.7).round())
                  : Colors.white.withAlpha((255 * 0.5).round()),
            ),
          ),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 90,
            borderRadius: 16,
            blur: 10,
            border: 0, // Border is handled by the AnimatedContainer
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.transparent, Colors.transparent],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.transparent, Colors.transparent],
            ),
            child: VBox(
              style: containerStyle,
              children: [
                _buildHeader(onPrimaryContainer),
                const Spacer(),
                _buildFooter(theme, onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color iconColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(widget.folder.icon, color: iconColor, size: 40),
        _buildNoteCountBadge(),
      ],
    );
  }

  Widget _buildNoteCountBadge() {
    final progress = widget.folder.capacity > 0
        ? widget.folder.size / widget.folder.capacity
        : 0.0;

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedProgressRing(
            progress: progress,
            progressColor: widget.folder.color,
            backgroundColor: Colors.white.withAlpha((255 * 0.1).round()),
          ),
          GlassmorphicContainer(
            width: 40,
            height: 40,
            borderRadius: 20,
            blur: 10,
            alignment: Alignment.center,
            border: 0.5,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha((255 * 0.1).round()),
                Colors.white.withAlpha((255 * 0.05).round()),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha((255 * 0.3).round()),
                Colors.white.withAlpha((255 * 0.1).round()),
              ],
            ),
            child: Text(
              '${widget.folder.noteCount}',
              style: TextStyle(
                color: Colors.white.withAlpha((255 * 0.8).round()),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.folder.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Last modified: 24',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withAlpha((255 * 0.7).round()),
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') {
              widget.onRename?.call();
            } else if (value == 'move') {
              widget.onMove?.call();
            } else if (value == 'delete') {
              widget.onDelete?.call();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'rename',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Rename'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'move',
              child: ListTile(
                leading: Icon(Icons.drive_file_move),
                title: Text('Move'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}