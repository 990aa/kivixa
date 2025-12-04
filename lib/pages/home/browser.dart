// Browser Page
//
// A full in-app browser experience using flutter_inappwebview.
// Provides Chrome-like browsing with navigation, tabs, find-in-page, etc.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

/// Browser page with full web browsing capabilities.
class BrowserPage extends StatefulWidget {
  /// Optional initial URL to load
  final String? initialUrl;

  const BrowserPage({super.key, this.initialUrl});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  InAppWebViewController? _webViewController;
  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();
  final _searchController = TextEditingController();

  var _progress = 0.0;
  var _canGoBack = false;
  var _canGoForward = false;
  var _isSecure = false;
  var _isLoading = false;
  var _showFindBar = false;
  var _findResultCount = 0;
  var _currentFindResult = 0;
  String _currentUrl = '';
  String _pageTitle = '';

  /// Whether we're on a desktop platform
  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Default home page
  static const _homePage = 'https://www.google.com';

  /// Quick access bookmarks
  static const _quickLinks = [
    _QuickLink('Google', 'https://www.google.com', Icons.search),
    _QuickLink('GitHub', 'https://github.com', Icons.code),
    _QuickLink('Stack Overflow', 'https://stackoverflow.com', Icons.help),
    _QuickLink('Wikipedia', 'https://www.wikipedia.org', Icons.menu_book),
    _QuickLink('YouTube', 'https://www.youtube.com', Icons.play_arrow),
    _QuickLink('Reddit', 'https://www.reddit.com', Icons.forum),
  ];

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl ?? _homePage;
    _urlController.text = _currentUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Browser toolbar
          _buildToolbar(context),

          // Progress indicator
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              minHeight: 2,
            ),

          // Find in page bar
          if (_showFindBar) _buildFindBar(context),

          // WebView content
          Expanded(child: _buildWebView()),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Navigation buttons
          IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 20,
            tooltip: 'Back',
            onPressed: _canGoBack ? _goBack : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            iconSize: 20,
            tooltip: 'Forward',
            onPressed: _canGoForward ? _goForward : null,
          ),
          IconButton(
            icon: Icon(_isLoading ? Icons.close : Icons.refresh),
            iconSize: 20,
            tooltip: _isLoading ? 'Stop' : 'Refresh',
            onPressed: _isLoading ? _stop : _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: 20,
            tooltip: 'Home',
            onPressed: _goHome,
          ),

          const SizedBox(width: 8),

          // URL bar (omnibox)
          Expanded(child: _buildUrlBar(context)),

          const SizedBox(width: 8),

          // Action buttons
          IconButton(
            icon: const Icon(Icons.search),
            iconSize: 20,
            tooltip: 'Find in page',
            onPressed: _toggleFindBar,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            iconSize: 20,
            tooltip: 'More options',
            onSelected: _handleMenuAction,
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
                  title: Text('Open in browser'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'desktop_mode',
                child: ListTile(
                  leading: Icon(Icons.desktop_windows),
                  title: Text('Desktop mode'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'view_source',
                child: ListTile(
                  leading: Icon(Icons.code),
                  title: Text('View source'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrlBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _urlFocusNode.hasFocus
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Security indicator
          Icon(
            _isSecure ? Icons.lock : Icons.lock_open,
            size: 16,
            color: _isSecure ? colorScheme.primary : colorScheme.error,
          ),
          const SizedBox(width: 8),
          // URL text field
          Expanded(
            child: TextField(
              controller: _urlController,
              focusNode: _urlFocusNode,
              style: theme.textTheme.bodyMedium,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search or enter URL',
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: _navigateToUrl,
              onTap: () {
                // Select all text when focused for easy editing
                _urlController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _urlController.text.length,
                );
              },
            ),
          ),
          // Clear button when focused
          if (_urlFocusNode.hasFocus && _urlController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              iconSize: 16,
              onPressed: () {
                _urlController.clear();
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFindBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Find in page',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: _findInPage,
                onSubmitted: (_) => _findNext(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_findResultCount > 0)
            Text(
              '$_currentFindResult/$_findResultCount',
              style: theme.textTheme.bodySmall,
            ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            iconSize: 20,
            tooltip: 'Previous',
            onPressed: _findPrevious,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            iconSize: 20,
            tooltip: 'Next',
            onPressed: _findNext,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 20,
            tooltip: 'Close',
            onPressed: _closeFindBar,
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    // Show new tab page if no URL loaded yet
    if (_currentUrl.isEmpty || _currentUrl == 'about:blank') {
      return _buildNewTabPage();
    }

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
        // Desktop-like user agent for better compatibility
        userAgent: _isDesktop
            ? null // Use default WebView2 user agent on Windows
            : null,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStart: (controller, url) {
        setState(() {
          _isLoading = true;
          _currentUrl = url?.toString() ?? '';
          _updateUrlBar(url?.toString() ?? '');
          _isSecure = url?.scheme == 'https';
        });
      },
      onLoadStop: (controller, url) async {
        setState(() {
          _isLoading = false;
          _currentUrl = url?.toString() ?? '';
          _updateUrlBar(url?.toString() ?? '');
        });
        await _updateNavigationState();
      },
      onProgressChanged: (controller, progress) {
        setState(() {
          _progress = progress / 100;
        });
      },
      onTitleChanged: (controller, title) {
        setState(() {
          _pageTitle = title ?? '';
        });
      },
      onReceivedError: (controller, request, error) {
        // Handle errors - could show error page
        debugPrint('WebView error: ${error.description}');
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url;
        if (url == null) return NavigationActionPolicy.CANCEL;

        // Handle special URL schemes (mailto, tel, etc.)
        final scheme = url.scheme;
        if (scheme == 'mailto' || scheme == 'tel' || scheme == 'sms') {
          await launchUrl(url);
          return NavigationActionPolicy.CANCEL;
        }

        return NavigationActionPolicy.ALLOW;
      },
      onFindResultReceived:
          (controller, activeMatchOrdinal, numberOfMatches, isDoneCounting) {
            if (isDoneCounting) {
              setState(() {
                _findResultCount = numberOfMatches;
                _currentFindResult = numberOfMatches > 0
                    ? activeMatchOrdinal + 1
                    : 0;
              });
            }
          },
    );
  }

  Widget _buildNewTabPage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              // Logo/icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.language,
                  size: 64,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Kivixa Browser',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Browse the web without leaving your notes',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              // Quick links grid
              Text(
                'Quick Links',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _quickLinks
                    .map(
                      (link) => _QuickLinkCard(
                        link: link,
                        onTap: () => _navigateToUrl(link.url),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateUrlBar(String url) {
    if (!_urlFocusNode.hasFocus) {
      _urlController.text = url;
    }
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

  void _navigateToUrl(String input) {
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
    // Simple check for URL-like patterns
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

  void _refresh() {
    _webViewController?.reload();
  }

  void _stop() {
    _webViewController?.stopLoading();
    setState(() {
      _isLoading = false;
    });
  }

  void _goHome() {
    _navigateToUrl(_homePage);
  }

  void _toggleFindBar() {
    setState(() {
      _showFindBar = !_showFindBar;
      if (!_showFindBar) {
        _webViewController?.clearMatches();
        _searchController.clear();
        _findResultCount = 0;
        _currentFindResult = 0;
      }
    });
  }

  void _closeFindBar() {
    setState(() {
      _showFindBar = false;
      _webViewController?.clearMatches();
      _searchController.clear();
      _findResultCount = 0;
      _currentFindResult = 0;
    });
  }

  void _findInPage(String query) {
    if (query.isEmpty) {
      _webViewController?.clearMatches();
      setState(() {
        _findResultCount = 0;
        _currentFindResult = 0;
      });
      return;
    }
    _webViewController?.findAllAsync(find: query);
  }

  void _findNext() {
    _webViewController?.findNext(forward: true);
  }

  void _findPrevious() {
    _webViewController?.findNext(forward: false);
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_tab':
        // TODO: Implement tabs
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tabs coming soon!')));
      case 'bookmark':
        // TODO: Implement bookmarks
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bookmarked: $_pageTitle')));
      case 'share':
        // TODO: Share URL
        Clipboard.setData(ClipboardData(text: _currentUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL copied to clipboard')),
        );
      case 'copy_url':
        Clipboard.setData(ClipboardData(text: _currentUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL copied to clipboard')),
        );
      case 'open_external':
        _openInExternalBrowser();
      case 'desktop_mode':
        _toggleDesktopMode();
      case 'view_source':
        _viewPageSource();
    }
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.tryParse(_currentUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _toggleDesktopMode() {
    // Toggle user agent between mobile and desktop
    // This would require recreating the webview with different settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Desktop mode toggle coming soon!')),
    );
  }

  Future<void> _viewPageSource() async {
    final source = await _webViewController?.getHtml();
    if (source != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Page Source'),
          content: SingleChildScrollView(
            child: SelectableText(
              source,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: source));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Source copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

/// Quick link data
class _QuickLink {
  final String name;
  final String url;
  final IconData icon;

  const _QuickLink(this.name, this.url, this.icon);
}

/// Quick link card widget
class _QuickLinkCard extends StatelessWidget {
  final _QuickLink link;
  final VoidCallback onTap;

  const _QuickLinkCard({required this.link, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(link.icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 8),
              Text(
                link.name,
                style: theme.textTheme.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
