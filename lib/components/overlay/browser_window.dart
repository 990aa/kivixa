import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kivixa/components/overlay/floating_window.dart';
import 'package:kivixa/pages/home/browser.dart';
import 'package:kivixa/services/browser_service.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// A tab in the floating browser (independent from main browser tabs).
class FloatingBrowserTab {
  FloatingBrowserTab({
    required this.id,
    required this.url,
    this.title = 'New Tab',
    this.isLoading = false,
  });

  final String id;
  String url;
  String title;
  bool isLoading;
  InAppWebViewController? controller;
}

/// A floating browser window for quick web access.
///
/// Uses InAppWebView for real web browsing capabilities.
/// Has its own independent tab system.
class BrowserWindow extends StatefulWidget {
  const BrowserWindow({super.key});

  /// Current URL in the floating browser (for transfer to main browser).
  static String? get currentUrl =>
      _BrowserWindowState._currentInstance?._currentUrl;

  /// Current tab's URL for transfer
  static String? get currentTabUrl {
    final instance = _BrowserWindowState._currentInstance;
    if (instance == null) return null;
    final tabs = instance._tabs;
    final index = instance._currentTabIndex;
    if (index >= 0 && index < tabs.length) {
      return tabs[index].url;
    }
    return null;
  }

  @override
  State<BrowserWindow> createState() => _BrowserWindowState();
}

class _BrowserWindowState extends State<BrowserWindow> {
  static _BrowserWindowState? _currentInstance;

  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();

  // Independent tab system for floating browser
  final List<FloatingBrowserTab> _tabs = [];
  var _currentTabIndex = 0;

  var _progress = 0.0;
  var _isLoading = false;
  var _canGoBack = false;
  var _canGoForward = false;
  var _isSecure = false;
  var _desktopModeEnabled = false;
  String get _currentUrl => _currentTab?.url ?? 'https://www.google.com';

  FloatingBrowserTab? get _currentTab =>
      _tabs.isNotEmpty && _currentTabIndex < _tabs.length
      ? _tabs[_currentTabIndex]
      : null;

  /// Whether we're on a desktop platform
  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    _currentInstance = this;
    OverlayController.instance.addListener(_onOverlayChanged);
    _initBrowserService();
    // Create initial tab
    _createNewTab('https://www.google.com');
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
    _currentInstance = null;
    OverlayController.instance.removeListener(_onOverlayChanged);
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _createNewTab([String url = 'https://www.google.com']) {
    final tab = FloatingBrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      title: 'New Tab',
    );
    setState(() {
      _tabs.add(tab);
      _currentTabIndex = _tabs.length - 1;
      _urlController.text = url;
    });
  }

  void _closeTab(int index) {
    if (_tabs.length <= 1) return; // Keep at least one tab
    setState(() {
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
      _urlController.text = _currentTab?.url ?? '';
    });
  }

  void _switchToTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() {
      _currentTabIndex = index;
      _urlController.text = _currentTab?.url ?? '';
    });
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
              minWidth: 450,
              minHeight: 350,
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

    final content = Column(
      children: [
        // Tab bar
        if (_tabs.length > 1) _buildTabBar(context),

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
                        onPressed: _copyUrl,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.add),
                iconSize: 18,
                tooltip: 'New Tab',
                onPressed: () => _createNewTab(),
              ),
              // Menu button with all options
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                iconSize: 18,
                tooltip: 'More options',
                onSelected: _handleMenuAction,
                position: PopupMenuPosition.under,
                clipBehavior: Clip.none,
                constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'new_tab',
                    child: ListTile(
                      leading: Icon(Icons.add),
                      title: Text('New tab'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'bookmark',
                    child: ListTile(
                      leading: Icon(Icons.bookmark_border),
                      title: Text('Bookmark'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
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
                  const PopupMenuItem(
                    value: 'open_external',
                    child: ListTile(
                      leading: Icon(Icons.open_in_new),
                      title: Text('Open in system browser'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'transfer_to_main',
                    child: ListTile(
                      leading: Icon(Icons.open_in_browser),
                      title: Text('Open in main browser'),
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
                  PopupMenuItem(
                    value: 'desktop_mode',
                    child: ListTile(
                      leading: Icon(
                        _desktopModeEnabled
                            ? Icons.phone_android
                            : Icons.desktop_windows,
                      ),
                      title: Text(
                        _desktopModeEnabled ? 'Mobile mode' : 'Desktop mode',
                      ),
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

    // Wrap in Overlay to ensure PopupMenu displays correctly within the floating window
    return Overlay(
      initialEntries: [OverlayEntry(builder: (context) => content)],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = index == _currentTabIndex;
          return GestureDetector(
            onTap: () => _switchToTab(index),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 150, minWidth: 80),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerLow,
                border: Border(
                  right: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tab.isLoading ? Icons.hourglass_empty : Icons.language,
                    size: 12,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tab.title.isEmpty ? 'New Tab' : tab.title,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_tabs.length > 1)
                    InkWell(
                      onTap: () => _closeTab(index),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebView() {
    final tab = _currentTab;
    if (tab == null) return const Center(child: Text('No tab'));

    return InAppWebView(
      key: ValueKey(tab.id),
      initialUrlRequest: URLRequest(url: WebUri(tab.url)),
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
        tab.controller = controller;
      },
      onLoadStart: (controller, url) {
        setState(() {
          _isLoading = true;
          tab.url = url?.toString() ?? '';
          tab.isLoading = true;
          _isSecure = url?.scheme == 'https';
          if (!_urlFocusNode.hasFocus) {
            _urlController.text = tab.url;
          }
        });
      },
      onLoadStop: (controller, url) async {
        setState(() {
          _isLoading = false;
          tab.url = url?.toString() ?? '';
          tab.isLoading = false;
          if (!_urlFocusNode.hasFocus) {
            _urlController.text = tab.url;
          }
        });
        await _updateNavigationState();
      },
      onTitleChanged: (controller, title) {
        setState(() {
          tab.title = title ?? '';
        });
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
    final controller = _currentTab?.controller;
    if (controller != null) {
      final canGoBack = await controller.canGoBack();
      final canGoForward = await controller.canGoForward();
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

    final tab = _currentTab;
    if (tab != null) {
      setState(() => tab.url = url);
      tab.controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
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

  void _goBack() => _currentTab?.controller?.goBack();
  void _goForward() => _currentTab?.controller?.goForward();
  void _stopLoading() {
    _currentTab?.controller?.stopLoading();
    setState(() => _isLoading = false);
  }

  void _refresh() => _currentTab?.controller?.reload();

  Future<void> _openInSystemBrowser() async {
    final uri = Uri.tryParse(_currentUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Handle menu item selection
  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'new_tab':
        _createNewTab();
      case 'bookmark':
        await _addBookmark();
      case 'share':
        await _shareUrl();
      case 'copy_url':
        _copyUrl();
      case 'open_external':
        await _openInSystemBrowser();
      case 'transfer_to_main':
        await _transferToMainBrowser();
      case 'bookmarks':
        _showBookmarks();
      case 'history':
        _showHistory();
      case 'desktop_mode':
        _toggleDesktopMode();
      case 'clear_data':
        await _clearBrowsingData();
    }
  }

  void _toggleDesktopMode() {
    setState(() => _desktopModeEnabled = !_desktopModeEnabled);
    _showMessage(
      _desktopModeEnabled ? 'Desktop mode enabled' : 'Mobile mode enabled',
    );
    _refresh();
  }

  Future<void> _transferToMainBrowser() async {
    final url = _currentUrl;
    if (url.isEmpty) return;

    // Add to main browser's tabs via BrowserService
    final browserService = BrowserService.instance;
    await browserService.createTab(url: url);

    _showMessage('Opened in main browser');

    // Navigate to browser page
    if (mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BrowserPage()));
    }
  }

  Future<void> _addBookmark() async {
    final browserService = BrowserService.instance;
    final tab = _currentTab;
    final pageTitle = tab?.title.isNotEmpty ?? false ? tab!.title : 'Bookmark';

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
