import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/components/overlay/floating_window.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

/// A floating browser window for quick web access.
///
/// This is a placeholder implementation that will be expanded
/// with actual web browsing capabilities.
class BrowserWindow extends StatefulWidget {
  const BrowserWindow({super.key});

  @override
  State<BrowserWindow> createState() => _BrowserWindowState();
}

class _BrowserWindowState extends State<BrowserWindow> {
  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();
  String? _currentUrl;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    OverlayController.instance.addListener(_onOverlayChanged);
    _urlController.text = 'https://www.google.com';
  }

  void _onOverlayChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    OverlayController.instance.removeListener(_onOverlayChanged);
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = OverlayController.instance;

    if (!controller.browserOpen) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Clamp window to screen bounds
        final clampedRect = controller.clampToScreen(
          controller.browserWindowRect,
          screenSize,
        );

        // FloatingWindow returns a Positioned widget, which must be inside a Stack
        return Stack(
          children: [
            FloatingWindow(
              rect: clampedRect,
              onRectChanged: (newRect) {
                controller.updateBrowserRect(
                  controller.clampToScreen(newRect, screenSize),
                );
              },
              onClose: controller.closeBrowser,
              title: 'Browser',
              icon: Icons.language_rounded,
              minWidth: 400,
              minHeight: 300,
              child: _buildBrowserContent(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrowserContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // URL bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              // Navigation buttons
              const IconButton(
                icon: Icon(Icons.arrow_back_rounded),
                iconSize: 18,
                tooltip: 'Back',
                onPressed: null, // Disabled placeholder
              ),
              const IconButton(
                icon: Icon(Icons.arrow_forward_rounded),
                iconSize: 18,
                tooltip: 'Forward',
                onPressed: null, // Disabled placeholder
              ),
              IconButton(
                icon: Icon(
                  _isLoading ? Icons.close_rounded : Icons.refresh_rounded,
                ),
                iconSize: 18,
                tooltip: _isLoading ? 'Stop' : 'Refresh',
                onPressed: _isLoading ? _stopLoading : _refresh,
              ),
              const SizedBox(width: 8),
              // URL text field
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          focusNode: _urlFocusNode,
                          style: theme.textTheme.bodySmall,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: _navigateTo,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.content_copy_rounded),
                        iconSize: 14,
                        tooltip: 'Copy URL',
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _urlController.text),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('URL copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded),
                iconSize: 18,
                tooltip: 'Open in system browser',
                onPressed: _openInSystemBrowser,
              ),
            ],
          ),
        ),
        // Browser content placeholder
        Expanded(child: _buildPlaceholderContent(context)),
      ],
    );
  }

  Widget _buildPlaceholderContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.web_rounded, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Browser Preview',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Web browsing will be available in a future update',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Quick links
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _QuickLinkChip(
                  label: 'Google',
                  url: 'https://www.google.com',
                  icon: Icons.search_rounded,
                  onTap: () => _navigateTo('https://www.google.com'),
                ),
                _QuickLinkChip(
                  label: 'GitHub',
                  url: 'https://github.com',
                  icon: Icons.code_rounded,
                  onTap: () => _navigateTo('https://github.com'),
                ),
                _QuickLinkChip(
                  label: 'Stack Overflow',
                  url: 'https://stackoverflow.com',
                  icon: Icons.help_outline_rounded,
                  onTap: () => _navigateTo('https://stackoverflow.com'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(String url) {
    setState(() {
      _currentUrl = url;
      _urlController.text = url;
      _isLoading = true;
    });

    // Simulate loading
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _stopLoading() {
    setState(() => _isLoading = false);
  }

  void _refresh() {
    if (_currentUrl != null) {
      _navigateTo(_currentUrl!);
    }
  }

  void _openInSystemBrowser() {
    // TODO: Implement system browser opening with url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${_urlController.text} in system browser...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _QuickLinkChip extends StatelessWidget {
  const _QuickLinkChip({
    required this.label,
    required this.url,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String url;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
