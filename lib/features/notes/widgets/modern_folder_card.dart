import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:intl/intl.dart';
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
    this.onFavorite,
    this.isSelected = false,
  });

  final Folder folder;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMove;
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

  void _showContextMenu(BuildContext context) {
    // In a real app, you'd show a more advanced context menu.
    HapticFeedback.vibrate();
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
        onLongPress: () => _showContextMenu(context),
        child: Dismissible(
          key: Key(widget.folder.id),
          background: _buildDismissibleBackground(
            context,
            'Delete',
            Icons.delete,
            Colors.red,
            Alignment.centerLeft,
          ),
          secondaryBackground: _buildDismissibleBackground(
            context,
            'Move',
            Icons.move_to_inbox,
            Colors.blue,
            Alignment.centerRight,
          ),
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              widget.onDelete?.call();
            } else {
              widget.onMove?.call();
            }
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
            backgroundColor: Colors.white.withOpacity(0.1),
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
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            child: Text(
              '${widget.folder.noteCount}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, Color textColor) {
    return Column(
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
          'Last modified: ${DateFormat.yMMMd().format(widget.folder.lastModified)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDismissibleBackground(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    Alignment alignment,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
