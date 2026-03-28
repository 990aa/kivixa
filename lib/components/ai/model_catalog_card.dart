import 'package:flutter/material.dart';
import 'package:kivixa/services/ai/model_manager.dart';

/// Reusable card for displaying a downloadable AI model in the catalog.
class ModelCatalogCard extends StatelessWidget {
  final AIModel model;
  final bool isDownloaded;
  final bool isCurrentlyLoaded;
  final VoidCallback onDownload;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const ModelCatalogCard({
    super.key,
    required this.model,
    required this.isDownloaded,
    required this.isCurrentlyLoaded,
    required this.onDownload,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: isCurrentlyLoaded
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            model.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (model.isDefault) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: const Text('Default'),
                              backgroundColor: colorScheme.secondaryContainer,
                              labelStyle: TextStyle(
                                color: colorScheme.onSecondaryContainer,
                                fontSize: 10,
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                          if (isCurrentlyLoaded) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: const Text('Active'),
                              backgroundColor: colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 10,
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        model.sizeText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(model.displayDescription, style: theme.textTheme.bodyMedium),
            if (model.suggestionText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 16,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        model.suggestionText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: model.categories.map((category) {
                return Chip(
                  label: Text(category.displayName),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  labelStyle: theme.textTheme.labelSmall,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isDownloaded && !isCurrentlyLoaded)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                const SizedBox(width: 8),
                if (isDownloaded)
                  FilledButton.icon(
                    onPressed: isCurrentlyLoaded ? null : onLoad,
                    icon: Icon(
                      isCurrentlyLoaded ? Icons.check : Icons.play_arrow,
                    ),
                    label: Text(isCurrentlyLoaded ? 'Loaded' : 'Load'),
                  )
                else
                  FilledButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
