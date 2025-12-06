import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kivixa/components/overlay/floating_window.dart';
import 'package:kivixa/services/browser_service.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// A floating browser window for quick web access.
///
/// Uses InAppWebView for real web browsing capabilities.
class BrowserWindow extends StatefulWidget {
  const BrowserWindow({super.key});

  @override
  State<BrowserWindow> createState() => _BrowserWindowState();
}

class _BrowserWindowState extends State<BrowserWindow> {
  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();
  InAppWebViewController? _webViewController;

  var _progress = 0.0;
  var _isLoading = false;
  var _canGoBack = false;
  var _canGoForward = false;
  var _isSecure = false;
  var _currentUrl = 'https://www.google.com';

  /// Whether we're on a desktop platform
  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    OverlayController.instance.addListener(_onOverlayChanged);
    _urlController.text = _currentUrl;
    _initBrowserService();
  }

  Future<void> _initBrowserService() async {
    await BrowserService.instance.init();
    if (mounted) setState(() {});
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
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                iconSize: 18,
                tooltip: 'Back',
                onPressed: _canGoBack ? _goBack : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                iconSize: 18,
                tooltip: 'Forward',
                onPressed: _canGoForward ? _goForward : null,
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
                  height: 32,
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
                        _isSecure ? Icons.lock : Icons.lock_open,
                        size: 14,
                        color: _isSecure
                            ? colorScheme.primary
                            : colorScheme.error,
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
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            hintText: 'Search or enter URL',
                          ),
                          onSubmitted: _navigateTo,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.content_copy_rounded),
                        iconSize: 14,
                        tooltip: 'Copy URL',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
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
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded),
                iconSize: 18,
                tooltip: 'Open in system browser',
                onPressed: _openInSystemBrowser,
              ),
              // Menu button
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                iconSize: 18,
                tooltip: 'More options',
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'bookmark',
                    child: ListTile(
                      leading: Icon(Icons.bookmark_border),
                      title: Text('Bookmark'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Share'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copy_url',
                    child: ListTile(
                      leading: Icon(Icons.content_copy),
                      title: Text('Copy URL'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'bookmarks',
                    child: ListTile(
                      leading: Icon(Icons.bookmark),
                      title: Text('Bookmarks'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'history',
                    child: ListTile(
                      leading: Icon(Icons.history),
                      title: Text('History'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'clear_data',
                    child: ListTile(
                      leading: Icon(Icons.delete_sweep),
                      title: Text('Clear browsing data'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Progress indicator
        if (_isLoading)
          LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            minHeight: 2,
          ),

        // WebView content
        Expanded(child: _buildWebView()),
      ],
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        supportZoom: true,
        builtInZoomControls: !_isDesktop,
        displayZoomControls: false,
        useHybridComposition: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        transparentBackground: false,
        useShouldOverrideUrlLoading: true,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStart: (controller, url) {
        setState(() {
          _isLoading = true;
          _currentUrl = url?.toString() ?? '';
          _isSecure = url?.scheme == 'https';
          if (!_urlFocusNode.hasFocus) {
            _urlController.text = _currentUrl;
          }
        });
      },
      onLoadStop: (controller, url) async {
        setState(() {
          _isLoading = false;
          _currentUrl = url?.toString() ?? '';
          if (!_urlFocusNode.hasFocus) {
            _urlController.text = _currentUrl;
          }
        });
        await _updateNavigationState();
      },
      onProgressChanged: (controller, progress) {
        setState(() {
          _progress = progress / 100;
        });
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url;
        if (url == null) return NavigationActionPolicy.CANCEL;

        // Handle special URL schemes
        final scheme = url.scheme;
        if (scheme == 'mailto' || scheme == 'tel' || scheme == 'sms') {
          await launchUrl(url);
          return NavigationActionPolicy.CANCEL;
        }

        return NavigationActionPolicy.ALLOW;
      },
    );
  }

  Future<void> _updateNavigationState() async {
    if (_webViewController != null) {
      final canGoBack = await _webViewController!.canGoBack();
      final canGoForward = await _webViewController!.canGoForward();
      if (mounted) {
        setState(() {
          _canGoBack = canGoBack;
          _canGoForward = canGoForward;
        });
      }
    }
  }

  void _navigateTo(String input) {
    _urlFocusNode.unfocus();

    String url = input.trim();
    if (url.isEmpty) return;

    // Check if it's a valid URL or a search query
    if (_isValidUrl(url)) {
      // Add scheme if missing
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
    } else {
      // Treat as search query
      final encodedQuery = Uri.encodeQueryComponent(url);
      url = 'https://www.google.com/search?q=$encodedQuery';
    }

    setState(() {
      _currentUrl = url;
    });

    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  bool _isValidUrl(String input) {
    final urlPattern = RegExp(
      r'^(https?:\/\/)?'
      r'([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}'
      r'(\/[^\s]*)?$',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(input) ||
        input.startsWith('http://') ||
        input.startsWith('https://');
  }

  void _goBack() {
    _webViewController?.goBack();
  }

  void _goForward() {
    _webViewController?.goForward();
  }

  void _stopLoading() {
    _webViewController?.stopLoading();
    setState(() => _isLoading = false);
  }

  void _refresh() {
    _webViewController?.reload();
  }

  Future<void> _openInSystemBrowser() async {
    final uri = Uri.tryParse(_currentUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Handle menu item selection
  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'bookmark':
        await _addBookmark();
      case 'share':
        await _shareUrl();
      case 'copy_url':
        _copyUrl();
      case 'bookmarks':
        _showBookmarks();
      case 'history':
        _showHistory();
      case 'clear_data':
        await _clearBrowsingData();
    }
  }

  Future<void> _addBookmark() async {
    final browserService = BrowserService.instance;
    final title = _urlController.text.split('/').last;
    final pageTitle = title.isNotEmpty ? title : 'Bookmark';

    await browserService.addBookmark(title: pageTitle, url: _currentUrl);

    if (mounted) {
      _showMessage('Bookmark added');
    }
  }

  Future<void> _shareUrl() async {
    await SharePlus.instance.share(ShareParams(text: _currentUrl));
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _currentUrl));
    if (mounted) {
      _showMessage('URL copied to clipboard');
    }
  }

  /// Show a message using ScaffoldMessenger if available, or fallback to overlay
  void _showMessage(String message) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
    } else {
      // Fallback: Show a temporary overlay message
      final overlay = Overlay.maybeOf(context);
      if (overlay != null) {
        late OverlayEntry entry;
        entry = OverlayEntry(
          builder: (context) => Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.inverseSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        overlay.insert(entry);
        Future.delayed(const Duration(seconds: 2), () {
          entry.remove();
        });
      }
    }
  }

  void _showBookmarks() {
    final browserService = BrowserService.instance;
    final bookmarks = browserService.bookmarks;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bookmarks'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: bookmarks.isEmpty
              ? const Center(child: Text('No bookmarks yet'))
              : ListView.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text(
                        bookmark.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        bookmark.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _navigateTo(bookmark.url);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await browserService.removeBookmarkById(bookmark.id);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            _showBookmarks(); // Refresh
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHistory() {
    final browserService = BrowserService.instance;
    final history = browserService.history;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('History'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: history.isEmpty
              ? const Center(child: Text('No history yet'))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (_, index) {
                    final url = history[index];
                    // Extract domain from URL for display
                    final uri = Uri.tryParse(url);
                    final displayTitle = uri?.host ?? url;
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _navigateTo(url);
                      },
                    );
                  },
                ),
        ),
        actions: [
          if (history.isNotEmpty)
            TextButton(
              onPressed: () async {
                await browserService.clearHistory();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Clear History'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearBrowsingData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Browsing Data'),
        content: const Text(
          'This will clear all browsing data including:\n'
          '• History\n'
          '• Bookmarks\n'
          '• Cache & Cookies\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final browserService = BrowserService.instance;
      await browserService.clearAll();
      await InAppWebViewController.clearAllCache();
      await CookieManager.instance().deleteAllCookies();

      if (mounted) {
        _showMessage('Browsing data cleared');
      }
    }
  }
}
