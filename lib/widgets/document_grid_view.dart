import 'package:flutter/material.dart';
import '../models/drawing_document.dart';

/// Grid view widget for displaying documents with thumbnails
///
/// Features:
/// - Grid layout with customizable columns
/// - Document thumbnails
/// - Favorite toggle
/// - Long press for context menu
/// - Selection mode support
class DocumentGridView extends StatefulWidget {
  final List<DrawingDocument> documents;
  final Function(DrawingDocument) onDocumentTap;
  final Function(DrawingDocument)? onDocumentLongPress;
  final Function(DrawingDocument, bool)? onFavoriteToggle;
  final int crossAxisCount;
  final bool showThumbnails;
  final bool selectionMode;
  final Set<int>? selectedDocuments;
  final Function(int, bool)? onSelectionChanged;

  const DocumentGridView({
    super.key,
    required this.documents,
    required this.onDocumentTap,
    this.onDocumentLongPress,
    this.onFavoriteToggle,
    this.crossAxisCount = 3,
    this.showThumbnails = true,
    this.selectionMode = false,
    this.selectedDocuments,
    this.onSelectionChanged,
  });

  @override
  State<DocumentGridView> createState() => _DocumentGridViewState();
}

class _DocumentGridViewState extends State<DocumentGridView> {
  @override
  Widget build(BuildContext context) {
    if (widget.documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No documents found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: widget.documents.length,
      itemBuilder: (context, index) {
        return _buildDocumentCard(widget.documents[index]);
      },
    );
  }

  Widget _buildDocumentCard(DrawingDocument document) {
    final isSelected = widget.selectedDocuments?.contains(document.id) ?? false;

    return GestureDetector(
      onTap: () {
        if (widget.selectionMode && widget.onSelectionChanged != null) {
          widget.onSelectionChanged!(document.id!, !isSelected);
        } else {
          widget.onDocumentTap(document);
        }
      },
      onLongPress: () => widget.onDocumentLongPress?.call(document),
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Stack(
                children: [
                  // Thumbnail image or placeholder
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child:
                          widget.showThumbnails &&
                              document.thumbnailPath != null
                          ? Image.asset(
                              document.thumbnailPath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholder(document);
                              },
                            )
                          : _buildPlaceholder(document),
                    ),
                  ),

                  // Selection checkbox (selection mode)
                  if (widget.selectionMode)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            widget.onSelectionChanged?.call(
                              document.id!,
                              value ?? false,
                            );
                          },
                        ),
                      ),
                    ),

                  // Favorite star (non-selection mode)
                  if (!widget.selectionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            document.isFavorite
                                ? Icons.star
                                : Icons.star_border,
                            color: document.isFavorite
                                ? Colors.amber
                                : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => widget.onFavoriteToggle?.call(
                            document,
                            !document.isFavorite,
                          ),
                        ),
                      ),
                    ),

                  // Document type badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            document.typeIcon,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            document.typeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Document info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document name
                  Text(
                    document.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Modified time
                  Text(
                    document.modifiedRelative,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 4),

                  // File size
                  Text(
                    document.fileSizeFormatted,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),

                  // Tags
                  if (document.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: document.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tag.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag.name,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(DrawingDocument document) {
    return Center(
      child: Icon(document.typeIcon, size: 48, color: Colors.grey.shade400),
    );
  }
}

/// Document context menu options
class DocumentContextMenu extends StatelessWidget {
  final DrawingDocument document;
  final VoidCallback? onOpen;
  final VoidCallback? onRename;
  final VoidCallback? onMove;
  final VoidCallback? onDuplicate;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const DocumentContextMenu({
    super.key,
    required this.document,
    this.onOpen,
    this.onRename,
    this.onMove,
    this.onDuplicate,
    this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onOpen != null)
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open'),
            onTap: () {
              Navigator.pop(context);
              onOpen?.call();
            },
          ),
        if (onRename != null)
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              onRename?.call();
            },
          ),
        if (onMove != null)
          ListTile(
            leading: const Icon(Icons.drive_file_move),
            title: const Text('Move to Folder'),
            onTap: () {
              Navigator.pop(context);
              onMove?.call();
            },
          ),
        if (onDuplicate != null)
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Duplicate'),
            onTap: () {
              Navigator.pop(context);
              onDuplicate?.call();
            },
          ),
        if (onShare != null)
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              onShare?.call();
            },
          ),
        if (onDelete != null) const Divider(),
        if (onDelete != null)
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
      ],
    );
  }
}
