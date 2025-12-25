import 'package:flutter/material.dart';
import 'package:kivixa/components/settings/settings_dropdown.dart';
import 'package:kivixa/components/settings/settings_subtitle.dart';
import 'package:kivixa/components/settings/settings_switch.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/services/media_service.dart';

/// Settings widget for media-related preferences.
///
/// Includes settings for:
/// - Web image download mode (download locally vs fetch on demand)
/// - Delete media with notes
/// - Preview container size for large images
class MediaSettingsWidget extends StatefulWidget {
  const MediaSettingsWidget({super.key});

  @override
  State<MediaSettingsWidget> createState() => _MediaSettingsWidgetState();
}

class _MediaSettingsWidgetState extends State<MediaSettingsWidget> {
  var _webCacheSize = 0;
  var _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await MediaService.instance.getWebCacheSize();
    if (mounted) {
      setState(() => _webCacheSize = size);
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);
    await MediaService.instance.clearWebCache();
    if (mounted) {
      setState(() {
        _webCacheSize = 0;
        _isClearing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web image cache cleared')),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSubtitle(title: 'Media Settings'),

        // Web image mode
        SettingsDropdown<int>(
          title: 'Web Image Mode',
          subtitle: 'How to handle images from web URLs',
          value: stows.webImageMode.value,
          items: const [
            DropdownMenuItem(
              value: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Download Locally'),
                  Text(
                    'Cache images for offline access',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Fetch on Demand'),
                  Text(
                    'Load from web each time (saves storage)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                stows.webImageMode.value = value;
              });
            }
          },
        ),

        // Web cache info and clear button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Web Image Cache',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      _formatSize(_webCacheSize),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _isClearing || _webCacheSize == 0
                    ? null
                    : _clearCache,
                icon: _isClearing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),

        const Divider(),

        // Delete media with notes
        SettingsSwitch(
          title: 'Delete Media with Notes',
          subtitle: 'Remove uploaded media files when their note is deleted',
          value: stows.deleteMediaWithNote.value,
          onChanged: (value) {
            setState(() {
              stows.deleteMediaWithNote.value = value;
            });
          },
        ),

        const Divider(),

        // Preview container size
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.aspect_ratio,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Large Image Preview Size',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          'Default container size for scrollable image preview',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${stows.mediaPreviewMaxSize.value.toInt()}px',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: stows.mediaPreviewMaxSize.value,
                min: 100,
                max: 500,
                divisions: 8,
                label: '${stows.mediaPreviewMaxSize.value.toInt()}px',
                onChanged: (value) {
                  setState(() {
                    stows.mediaPreviewMaxSize.value = value;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '100px',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '500px',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(),

        // Help text
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Media Tips',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Click on any image to select it and show resize handles\n'
                  '• Drag corner handles to resize (hold Shift for aspect ratio)\n'
                  '• Use the rotation handle at the top to rotate images\n'
                  '• Use the center move handle to reposition media\n'
                  '• Double-click large images to toggle preview mode\n'
                  '• Hover over media on desktop to see/add comments',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
