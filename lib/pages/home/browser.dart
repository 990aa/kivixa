// Browser Page
//
// A full in-app browser experience using flutter_inappwebview.
// Provides Chrome-like browsing with navigation, tabs, find-in-page, etc.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kivixa/services/browser_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Console log entry for developer tools
class ConsoleLogEntry {
  final String message;
  final ConsoleMessageLevel level;
  final DateTime timestamp;

  ConsoleLogEntry({
    required this.message,
    required this.level,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Color get color {
    switch (level) {
      case ConsoleMessageLevel.ERROR:
        return Colors.red;
      case ConsoleMessageLevel.WARNING:
        return Colors.orange;
      case ConsoleMessageLevel.DEBUG:
        return Colors.blue;
      case ConsoleMessageLevel.LOG:
      case ConsoleMessageLevel.TIP:
      default:
        return Colors.grey;
    }
  }

  String get levelName {
    switch (level) {
      case ConsoleMessageLevel.ERROR:
        return 'ERROR';
      case ConsoleMessageLevel.WARNING:
        return 'WARN';
      case ConsoleMessageLevel.DEBUG:
        return 'DEBUG';
      case ConsoleMessageLevel.LOG:
        return 'LOG';
      case ConsoleMessageLevel.TIP:
        return 'TIP';
      default:
        return 'LOG';
    }
  }
}

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
  FindInteractionController? _findInteractionController;
  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();
  final _searchController = TextEditingController();

  var _progress = 0.0;
  var _canGoBack = false;
  var _canGoForward = false;
  var _isSecure = false;
  var _isLoading = false;
  var _showFindBar = false;
  var _showConsole = false;
  var _findResultCount = 0;
  var _currentFindResult = 0;
  var _currentUrl = '';
  var _pageTitle = '';
  var _desktopModeEnabled = false;
  final _showTabBar = true;

  /// Console log entries
  final _consoleLogs = <ConsoleLogEntry>[];

  /// Whether we're on a desktop platform
  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Desktop user agent for desktop mode toggle
  static const _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// Mobile user agent for mobile mode
  static const _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

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
    _initBrowserService();
    BrowserService.instance.addListener(_onBrowserServiceChanged);
  }

  void _onBrowserServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initBrowserService() async {
    await BrowserService.instance.init();
    // Load current tab URL
    final currentTab = BrowserService.instance.currentTab;
    if (currentTab != null && currentTab.url.isNotEmpty) {
      _currentUrl = currentTab.url;
      _pageTitle = currentTab.title;
      _urlController.text = _currentUrl;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BrowserService.instance.removeListener(_onBrowserServiceChanged);
    _urlController.dispose();
    _urlFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Handle Android back button
  Future<bool> _onWillPop() async {
    if (_showFindBar) {
      _closeFindBar();
      return false;
    }
    if (_showConsole) {
      setState(() => _showConsole = false);
      return false;
    }
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      _webViewController!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard shortcuts for desktop
    return Shortcuts(
      shortcuts: _isDesktop
          ? <ShortcutActivator, Intent>{
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.keyL,
              ): const _FocusUrlBarIntent(),
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.keyF,
              ): const _ToggleFindBarIntent(),
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.keyR,
              ): const _RefreshIntent(),
              // F5 for refresh
              const SingleActivator(LogicalKeyboardKey.f5):
                  const _RefreshIntent(),
              LogicalKeySet(LogicalKeyboardKey.escape): const _EscapeIntent(),
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.shift,
                LogicalKeyboardKey.keyJ,
              ): const _ToggleConsoleIntent(),
              // Ctrl+T for new tab
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.keyT,
              ): const _NewTabIntent(),
              // Ctrl+W to close tab
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.keyW,
              ): const _CloseTabIntent(),
              // Ctrl+Tab for next tab
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.tab):
                  const _NextTabIntent(),
              // Ctrl+Shift+Tab for previous tab
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.shift,
                LogicalKeyboardKey.tab,
              ): const _PreviousTabIntent(),
            }
          : <ShortcutActivator, Intent>{},
      child: Actions(
        actions: <Type, Action<Intent>>{
          _FocusUrlBarIntent: CallbackAction<_FocusUrlBarIntent>(
            onInvoke: (_) => _focusUrlBar(),
          ),
          _ToggleFindBarIntent: CallbackAction<_ToggleFindBarIntent>(
            onInvoke: (_) => _toggleFindBar(),
          ),
          _RefreshIntent: CallbackAction<_RefreshIntent>(
            onInvoke: (_) => _refresh(),
          ),
          _EscapeIntent: CallbackAction<_EscapeIntent>(
            onInvoke: (_) => _handleEscape(),
          ),
          _ToggleConsoleIntent: CallbackAction<_ToggleConsoleIntent>(
            onInvoke: (_) => _toggleConsole(),
          ),
          _NewTabIntent: CallbackAction<_NewTabIntent>(
            onInvoke: (_) => _openNewTab(),
          ),
          _CloseTabIntent: CallbackAction<_CloseTabIntent>(
            onInvoke: (_) => _closeCurrentTab(),
          ),
          _NextTabIntent: CallbackAction<_NextTabIntent>(
            onInvoke: (_) => _nextTab(),
          ),
          _PreviousTabIntent: CallbackAction<_PreviousTabIntent>(
            onInvoke: (_) => _previousTab(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              body: Column(
                children: [
                  // Tab bar
                  if (_showTabBar) _buildTabBar(context),

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

                  // Console panel
                  if (_showConsole) _buildConsolePanel(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _focusUrlBar() {
    _urlFocusNode.requestFocus();
    _urlController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _urlController.text.length,
    );
  }

  void _handleEscape() {
    if (_showFindBar) {
      _closeFindBar();
    } else if (_showConsole) {
      setState(() => _showConsole = false);
    } else if (_urlFocusNode.hasFocus) {
      _urlFocusNode.unfocus();
    }
  }

  void _toggleConsole() {
    setState(() => _showConsole = !_showConsole);
  }

  /// Build the tab bar showing all open tabs
  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tabs = BrowserService.instance.tabs;
    final currentIndex = BrowserService.instance.currentTabIndex;

    return Container(
      height: 40,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: MediaQuery.of(context).padding.top,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Tab list
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = index == currentIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Material(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () => _switchToTab(index),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 180,
                          minWidth: 100,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.isLoading
                                  ? Icons.hourglass_empty
                                  : Icons.language,
                              size: 14,
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tab.title.isEmpty ? 'New Tab' : tab.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _closeTab(index),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // New tab button
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: 20,
            tooltip: 'New Tab (Ctrl+T)',
            onPressed: _openNewTab,
          ),
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
        top: _showTabBar ? 8 : MediaQuery.of(context).padding.top + 8,
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
              const PopupMenuItem(
                value: 'view_source',
                child: ListTile(
                  leading: Icon(Icons.code),
                  title: Text('View source'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'console',
                child: ListTile(
                  leading: Icon(Icons.terminal),
                  title: Text('Developer console'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'inject_dark_mode',
                child: ListTile(
                  leading: Icon(Icons.dark_mode),
                  title: Text('Toggle dark mode'),
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
        allowFileAccess: true,
        allowContentAccess: true,
        // Desktop-like user agent for better compatibility
        userAgent: _isDesktop
            ? null // Use default WebView2 user agent on Windows
            : null,
        // FindInteractionController is not supported on desktop platforms
        isFindInteractionEnabled: !_isDesktop,
      ),
      // FindInteractionController is only supported on mobile platforms
      findInteractionController: _isDesktop
          ? null
          : (_findInteractionController = FindInteractionController(
              onFindResultReceived:
                  (
                    controller,
                    activeMatchOrdinal,
                    numberOfMatches,
                    isDoneCounting,
                  ) {
                    if (isDoneCounting) {
                      setState(() {
                        _findResultCount = numberOfMatches;
                        _currentFindResult = numberOfMatches > 0
                            ? activeMatchOrdinal + 1
                            : 0;
                      });
                    }
                  },
            )),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStart: (controller, url) {
        final urlString = url?.toString() ?? '';
        setState(() {
          _isLoading = true;
          _currentUrl = urlString;
          _updateUrlBar(urlString);
          _isSecure = url?.scheme == 'https';
        });
        // Update current tab loading state
        final currentTab = BrowserService.instance.currentTab;
        if (currentTab != null) {
          BrowserService.instance.updateTabLoading(
            currentTab.id,
            isLoading: true,
          );
        }
      },
      onLoadStop: (controller, url) async {
        final urlString = url?.toString() ?? '';
        setState(() {
          _isLoading = false;
          _currentUrl = urlString;
          _updateUrlBar(urlString);
        });
        await _updateNavigationState();
        // Update current tab info
        final currentTab = BrowserService.instance.currentTab;
        if (currentTab != null) {
          BrowserService.instance.updateTabLoading(
            currentTab.id,
            isLoading: false,
          );
          BrowserService.instance.updateTabInfo(
            currentTab.id,
            url: urlString,
            title: _pageTitle,
          );
        }
        // Add to history
        if (urlString.isNotEmpty && !urlString.startsWith('about:')) {
          await BrowserService.instance.addToHistory(urlString);
        }
      },
      onProgressChanged: (controller, progress) {
        setState(() {
          _progress = progress / 100;
        });
        // Update tab progress
        final currentTab = BrowserService.instance.currentTab;
        if (currentTab != null) {
          BrowserService.instance.updateTabLoading(
            currentTab.id,
            progress: progress / 100,
          );
        }
      },
      onTitleChanged: (controller, title) {
        setState(() {
          _pageTitle = title ?? '';
        });
        // Update current tab title
        final currentTab = BrowserService.instance.currentTab;
        if (currentTab != null && title != null && title.isNotEmpty) {
          BrowserService.instance.updateTabInfo(currentTab.id, title: title);
        }
      },
      onReceivedError: (controller, request, error) {
        // Handle errors - could show error page
        debugPrint('WebView error: ${error.description}');
        _addConsoleLog(
          'Error: ${error.description}',
          ConsoleMessageLevel.ERROR,
        );
      },
      // Console message logging
      onConsoleMessage: (controller, consoleMessage) {
        _addConsoleLog(consoleMessage.message, consoleMessage.messageLevel);
      },
      // JavaScript alert dialog
      onJsAlert: (controller, jsAlertRequest) async {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Alert'),
            content: Text(jsAlertRequest.message ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return JsAlertResponse(handledByClient: true);
      },
      // JavaScript confirm dialog
      onJsConfirm: (controller, jsConfirmRequest) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(jsConfirmRequest.message ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return JsConfirmResponse(
          handledByClient: true,
          action: (result ?? false)
              ? JsConfirmResponseAction.CONFIRM
              : JsConfirmResponseAction.CANCEL,
        );
      },
      // JavaScript prompt dialog
      onJsPrompt: (controller, jsPromptRequest) async {
        final textController = TextEditingController(
          text: jsPromptRequest.defaultValue,
        );
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Prompt'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (jsPromptRequest.message != null)
                  Text(jsPromptRequest.message!),
                const SizedBox(height: 8),
                TextField(controller: textController),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(textController.text),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return JsPromptResponse(
          handledByClient: true,
          action: result != null
              ? JsPromptResponseAction.CONFIRM
              : JsPromptResponseAction.CANCEL,
          value: result,
        );
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
      // Android/iOS permission request handling with native permission requests
      onPermissionRequest: (controller, request) async {
        return await _handlePermissionRequest(request);
      },
      // Download handling
      onDownloadStartRequest: (controller, downloadStartRequest) async {
        final url = downloadStartRequest.url.toString();
        final filename = downloadStartRequest.suggestedFilename ?? 'download';

        // Ask user if they want to download
        final shouldDownload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download'),
            content: Text('Download "$filename"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Download'),
              ),
            ],
          ),
        );

        if (shouldDownload ?? false) {
          // Open in external browser for download
          final uri = Uri.tryParse(url);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
    );
  }

  /// Handle web permission requests with native permission handling
  Future<PermissionResponse> _handlePermissionRequest(
    PermissionRequest request,
  ) async {
    // Request native permissions based on the web permission request
    final permissions = <Permission>[];
    final resourceNames = <String>[];

    for (final resource in request.resources) {
      final resourceName = resource.toString().split('.').last;
      resourceNames.add(resourceName);

      // Map web permissions to native permissions
      if (resourceName.contains('CAMERA')) {
        permissions.add(Permission.camera);
      }
      if (resourceName.contains('MICROPHONE')) {
        permissions.add(Permission.microphone);
      }
      if (resourceName.contains('GEOLOCATION') ||
          resourceName.contains('LOCATION')) {
        permissions.add(Permission.location);
      }
    }

    // If we have native permissions to request, do that first
    if (permissions.isNotEmpty && !_isDesktop) {
      // Check current permission status
      final statuses = await Future.wait(permissions.map((p) => p.status));

      // Check if any permissions are denied
      final needsRequest = statuses.any(
        (s) => s.isDenied || s.isPermanentlyDenied,
      );

      if (needsRequest) {
        // Request permissions
        final results = await permissions.request();

        // Check if all permissions were granted
        final allGranted = results.values.every(
          (status) => status.isGranted || status.isLimited,
        );

        if (!allGranted) {
          // Show dialog explaining permissions are needed
          if (!mounted) {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.DENY,
            );
          }
          final tryAgain = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Permissions Required'),
              content: Text(
                'This website needs access to: ${resourceNames.join(", ")}.\n\n'
                'Please grant the required permissions in your device settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Deny'),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );

          if (tryAgain != true) {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.DENY,
            );
          }
        }
      }
    }

    // Show web permission dialog
    if (!mounted) {
      return PermissionResponse(
        resources: request.resources,
        action: PermissionResponseAction.DENY,
      );
    }
    final granted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Website Permission'),
        content: Text(
          'This website wants to access:\n• ${resourceNames.join("\n• ")}\n\n'
          'Do you want to allow this?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return PermissionResponse(
      resources: request.resources,
      action: (granted ?? false)
          ? PermissionResponseAction.GRANT
          : PermissionResponseAction.DENY,
    );
  }

  void _addConsoleLog(String message, ConsoleMessageLevel level) {
    setState(() {
      _consoleLogs.add(ConsoleLogEntry(message: message, level: level));
      // Keep only last 100 logs
      if (_consoleLogs.length > 100) {
        _consoleLogs.removeAt(0);
      }
    });
  }

  Widget _buildConsolePanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Console header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Console',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 18,
                  tooltip: 'Clear console',
                  onPressed: () => setState(() => _consoleLogs.clear()),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  tooltip: 'Close console',
                  onPressed: () => setState(() => _showConsole = false),
                ),
              ],
            ),
          ),
          // Console logs
          Expanded(
            child: _consoleLogs.isEmpty
                ? Center(
                    child: Text(
                      'No console messages',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _consoleLogs.length,
                    itemBuilder: (context, index) {
                      final log = _consoleLogs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: log.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                log.levelName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: log.color,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                log.message,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
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

  /// Load a URL in the browser
  void _loadUrl(String url) {
    _navigateToUrl(url);
  }

  void _toggleFindBar() {
    setState(() {
      _showFindBar = !_showFindBar;
      if (!_showFindBar) {
        if (_isDesktop) {
          // Clear JavaScript-based find highlighting
          _webViewController?.evaluateJavascript(source: '''
            (function() {
              if (window.__kivixaFindHighlight) {
                window.__kivixaFindHighlight.clear();
              }
            })();
          ''');
        } else {
          _findInteractionController?.clearMatches();
        }
        _searchController.clear();
        _findResultCount = 0;
        _currentFindResult = 0;
      }
    });
  }

  void _closeFindBar() {
    setState(() {
      _showFindBar = false;
      if (_isDesktop) {
        // Clear JavaScript-based find highlighting
        _webViewController?.evaluateJavascript(source: '''
          (function() {
            if (window.__kivixaFindHighlight) {
              window.__kivixaFindHighlight.clear();
            }
          })();
        ''');
      } else {
        _findInteractionController?.clearMatches();
      }
      _searchController.clear();
      _findResultCount = 0;
      _currentFindResult = 0;
    });
  }

  void _findInPage(String query) {
    if (query.isEmpty) {
      if (_isDesktop) {
        _webViewController?.evaluateJavascript(source: '''
          (function() {
            if (window.__kivixaFindHighlight) {
              window.__kivixaFindHighlight.clear();
            }
          })();
        ''');
      } else {
        _findInteractionController?.clearMatches();
      }
      setState(() {
        _findResultCount = 0;
        _currentFindResult = 0;
      });
      return;
    }
    if (_isDesktop) {
      _findInPageDesktop(query);
    } else {
      _findInteractionController?.findAll(find: query);
    }
  }

  /// JavaScript-based find in page for desktop platforms
  Future<void> _findInPageDesktop(String query) async {
    final escapedQuery = query.replaceAll("'", "\\'").replaceAll('"', '\\"');
    final result = await _webViewController?.evaluateJavascript(source: '''
      (function() {
        // Initialize find highlight helper
        if (!window.__kivixaFindHighlight) {
          window.__kivixaFindHighlight = {
            matches: [],
            currentIndex: -1,
            originalStyles: [],
            clear: function() {
              for (var i = 0; i < this.matches.length; i++) {
                var match = this.matches[i];
                if (match.parentNode) {
                  match.parentNode.replaceChild(document.createTextNode(match.textContent), match);
                }
              }
              this.matches = [];
              this.currentIndex = -1;
            },
            highlight: function(query) {
              this.clear();
              if (!query) return { count: 0, current: 0 };
              
              var body = document.body;
              var walker = document.createTreeWalker(body, NodeFilter.SHOW_TEXT, null, false);
              var nodes = [];
              while (walker.nextNode()) {
                if (walker.currentNode.textContent.toLowerCase().indexOf(query.toLowerCase()) !== -1) {
                  nodes.push(walker.currentNode);
                }
              }
              
              for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i];
                var text = node.textContent;
                var lowerText = text.toLowerCase();
                var lowerQuery = query.toLowerCase();
                var idx = lowerText.indexOf(lowerQuery);
                while (idx !== -1) {
                  var before = text.substring(0, idx);
                  var match = text.substring(idx, idx + query.length);
                  var after = text.substring(idx + query.length);
                  
                  var span = document.createElement('span');
                  span.style.backgroundColor = '#ffeb3b';
                  span.style.color = 'black';
                  span.textContent = match;
                  span.className = '__kivixa_find_match';
                  this.matches.push(span);
                  
                  var parent = node.parentNode;
                  parent.insertBefore(document.createTextNode(before), node);
                  parent.insertBefore(span, node);
                  node.textContent = after;
                  text = after;
                  lowerText = text.toLowerCase();
                  idx = lowerText.indexOf(lowerQuery);
                }
              }
              
              if (this.matches.length > 0) {
                this.currentIndex = 0;
                this.matches[0].style.backgroundColor = '#ff9800';
                this.matches[0].scrollIntoView({ block: 'center', behavior: 'smooth' });
              }
              
              return { count: this.matches.length, current: this.matches.length > 0 ? 1 : 0 };
            },
            next: function() {
              if (this.matches.length === 0) return { count: 0, current: 0 };
              this.matches[this.currentIndex].style.backgroundColor = '#ffeb3b';
              this.currentIndex = (this.currentIndex + 1) % this.matches.length;
              this.matches[this.currentIndex].style.backgroundColor = '#ff9800';
              this.matches[this.currentIndex].scrollIntoView({ block: 'center', behavior: 'smooth' });
              return { count: this.matches.length, current: this.currentIndex + 1 };
            },
            prev: function() {
              if (this.matches.length === 0) return { count: 0, current: 0 };
              this.matches[this.currentIndex].style.backgroundColor = '#ffeb3b';
              this.currentIndex = (this.currentIndex - 1 + this.matches.length) % this.matches.length;
              this.matches[this.currentIndex].style.backgroundColor = '#ff9800';
              this.matches[this.currentIndex].scrollIntoView({ block: 'center', behavior: 'smooth' });
              return { count: this.matches.length, current: this.currentIndex + 1 };
            }
          };
        }
        return JSON.stringify(window.__kivixaFindHighlight.highlight('$escapedQuery'));
      })();
    ''');
    
    if (result != null) {
      try {
        final jsonStr = result.toString().replaceAll('"', '').replaceAll("'", '"');
        if (jsonStr.contains('count')) {
          final match = RegExp(r'count:\s*(\d+)').firstMatch(jsonStr);
          final currentMatch = RegExp(r'current:\s*(\d+)').firstMatch(jsonStr);
          if (match != null) {
            setState(() {
              _findResultCount = int.tryParse(match.group(1) ?? '0') ?? 0;
              _currentFindResult = int.tryParse(currentMatch?.group(1) ?? '0') ?? 0;
            });
          }
        }
      } catch (e) {
        debugPrint('Find parse error: $e');
      }
    }
  }

  void _findNext() {
    if (_isDesktop) {
      _findNextDesktop(forward: true);
    } else {
      _findInteractionController?.findNext(forward: true);
    }
  }

  void _findPrevious() {
    if (_isDesktop) {
      _findNextDesktop(forward: false);
    } else {
      _findInteractionController?.findNext(forward: false);
    }
  }

  Future<void> _findNextDesktop({required bool forward}) async {
    final method = forward ? 'next' : 'prev';
    final result = await _webViewController?.evaluateJavascript(source: '''
      (function() {
        if (window.__kivixaFindHighlight) {
          return JSON.stringify(window.__kivixaFindHighlight.$method());
        }
        return '{"count":0,"current":0}';
      })();
    ''');
    
    if (result != null) {
      try {
        final jsonStr = result.toString();
        final match = RegExp(r'count[":]\s*(\d+)').firstMatch(jsonStr);
        final currentMatch = RegExp(r'current[":]\s*(\d+)').firstMatch(jsonStr);
        if (match != null) {
          setState(() {
            _findResultCount = int.tryParse(match.group(1) ?? '0') ?? 0;
            _currentFindResult = int.tryParse(currentMatch?.group(1) ?? '0') ?? 0;
          });
        }
      } catch (e) {
        debugPrint('Find next parse error: $e');
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_tab':
        _openNewTab();
      case 'bookmark':
        _toggleBookmark();
      case 'bookmarks':
        _showBookmarksSheet();
      case 'share':
        _shareUrl();
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
      case 'console':
        _toggleConsole();
      case 'inject_dark_mode':
        _injectDarkMode();
      case 'history':
        _showHistorySheet();
      case 'clear_data':
        _showClearDataDialog();
    }
  }

  /// Open a new tab
  Future<void> _openNewTab() async {
    final tab = await BrowserService.instance.createTab();
    if (mounted) {
      setState(() {
        _currentUrl = tab.url;
        _urlController.text = _currentUrl;
        _pageTitle = 'New Tab';
      });
      // Load the new tab page
      _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(_currentUrl)),
      );
    }
  }

  /// Switch to a specific tab
  Future<void> _switchToTab(int index) async {
    final tabs = BrowserService.instance.tabs;
    if (index >= 0 && index < tabs.length) {
      await BrowserService.instance.switchTab(index);
      final tab = tabs[index];
      if (mounted) {
        setState(() {
          _currentUrl = tab.url;
          _urlController.text = tab.url;
          _pageTitle = tab.title;
        });
        // Load the tab's URL
        _webViewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri(tab.url)),
        );
      }
    }
  }

  /// Close a specific tab
  Future<void> _closeTab(int index) async {
    await BrowserService.instance.closeTab(index);
    final currentTab = BrowserService.instance.currentTab;
    if (currentTab != null && mounted) {
      setState(() {
        _currentUrl = currentTab.url;
        _urlController.text = currentTab.url;
        _pageTitle = currentTab.title;
      });
      _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(currentTab.url)),
      );
    }
  }

  /// Close the current tab
  Future<void> _closeCurrentTab() async {
    final currentIndex = BrowserService.instance.currentTabIndex;
    await _closeTab(currentIndex);
  }

  /// Switch to next tab
  Future<void> _nextTab() async {
    final tabs = BrowserService.instance.tabs;
    final currentIndex = BrowserService.instance.currentTabIndex;
    if (tabs.length > 1) {
      final nextIndex = (currentIndex + 1) % tabs.length;
      await _switchToTab(nextIndex);
    }
  }

  /// Switch to previous tab
  Future<void> _previousTab() async {
    final tabs = BrowserService.instance.tabs;
    final currentIndex = BrowserService.instance.currentTabIndex;
    if (tabs.length > 1) {
      final prevIndex = (currentIndex - 1 + tabs.length) % tabs.length;
      await _switchToTab(prevIndex);
    }
  }

  /// Toggle bookmark for current page
  Future<void> _toggleBookmark() async {
    final service = BrowserService.instance;
    if (service.isBookmarked(_currentUrl)) {
      await service.removeBookmark(_currentUrl);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bookmark removed')));
      }
    } else {
      await service.addBookmark(
        title: _pageTitle.isNotEmpty ? _pageTitle : _currentUrl,
        url: _currentUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bookmarked: $_pageTitle')));
      }
    }
    setState(() {}); // Refresh UI
  }

  /// Show bookmarks bottom sheet
  void _showBookmarksSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _BookmarksSheet(
          scrollController: scrollController,
          onBookmarkTap: (url) {
            Navigator.of(context).pop();
            _loadUrl(url);
          },
        ),
      ),
    );
  }

  /// Show history bottom sheet
  void _showHistorySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _HistorySheet(
          scrollController: scrollController,
          onHistoryTap: (url) {
            Navigator.of(context).pop();
            _loadUrl(url);
          },
        ),
      ),
    );
  }

  /// Share the current URL
  Future<void> _shareUrl() async {
    if (_currentUrl.isEmpty) return;

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: _pageTitle.isNotEmpty
              ? '$_pageTitle\n$_currentUrl'
              : _currentUrl,
        ),
      );
    } catch (e) {
      // Fallback to clipboard if share fails
      await Clipboard.setData(ClipboardData(text: _currentUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL copied to clipboard')),
        );
      }
    }
  }

  /// Show clear browsing data dialog
  void _showClearDataDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Browsing Data'),
        content: const Text(
          'This will clear your browsing history, cookies, and cache.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearBrowsingData();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  /// Clear all browsing data
  Future<void> _clearBrowsingData() async {
    // Clear WebView data
    await InAppWebViewController.clearAllCache();
    await CookieManager.instance().deleteAllCookies();

    // Clear history
    await BrowserService.instance.clearHistory();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Browsing data cleared')));
    }
  }

  Future<void> _injectDarkMode() async {
    const darkModeCSS = '''
      html {
        filter: invert(1) hue-rotate(180deg);
      }
      img, video, picture, canvas, iframe {
        filter: invert(1) hue-rotate(180deg);
      }
    ''';
    await _webViewController?.evaluateJavascript(
      source:
          '''
      (function() {
        var style = document.getElementById('kivixa-dark-mode');
        if (style) {
          style.remove();
        } else {
          style = document.createElement('style');
          style.id = 'kivixa-dark-mode';
          style.textContent = `$darkModeCSS`;
          document.head.appendChild(style);
        }
      })();
    ''',
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dark mode toggled')));
    }
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.tryParse(_currentUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Toggle between desktop and mobile user agent
  Future<void> _toggleDesktopMode() async {
    setState(() {
      _desktopModeEnabled = !_desktopModeEnabled;
    });

    final userAgent = _desktopModeEnabled
        ? _desktopUserAgent
        : _mobileUserAgent;

    // Update the user agent via JavaScript
    await _webViewController?.evaluateJavascript(
      source:
          '''
        Object.defineProperty(navigator, 'userAgent', {
          get: function() { return '$userAgent'; }
        });
      ''',
    );

    // Reload page with new user agent setting
    await _webViewController?.reload();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _desktopModeEnabled
                ? 'Desktop mode enabled'
                : 'Mobile mode enabled',
          ),
        ),
      );
    }
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

// Keyboard shortcut intents
class _FocusUrlBarIntent extends Intent {
  const _FocusUrlBarIntent();
}

class _ToggleFindBarIntent extends Intent {
  const _ToggleFindBarIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

class _ToggleConsoleIntent extends Intent {
  const _ToggleConsoleIntent();
}

class _NewTabIntent extends Intent {
  const _NewTabIntent();
}

class _CloseTabIntent extends Intent {
  const _CloseTabIntent();
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}

class _PreviousTabIntent extends Intent {
  const _PreviousTabIntent();
}

/// Bookmarks bottom sheet
class _BookmarksSheet extends StatelessWidget {
  final ScrollController scrollController;
  final void Function(String url) onBookmarkTap;

  const _BookmarksSheet({
    required this.scrollController,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bookmarks = BrowserService.instance.bookmarks;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.bookmark, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Bookmarks', style: theme.textTheme.titleLarge),
                const Spacer(),
                if (bookmarks.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All Bookmarks'),
                          content: const Text(
                            'Are you sure you want to delete all bookmarks?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed ?? false) {
                        await BrowserService.instance.clearBookmarks();
                      }
                    },
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),
          const Divider(),
          // Bookmarks list
          Expanded(
            child: bookmarks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No bookmarks yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the bookmark icon to save pages',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
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
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await BrowserService.instance.removeBookmarkById(
                              bookmark.id,
                            );
                          },
                        ),
                        onTap: () => onBookmarkTap(bookmark.url),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// History bottom sheet
class _HistorySheet extends StatelessWidget {
  final ScrollController scrollController;
  final void Function(String url) onHistoryTap;

  const _HistorySheet({
    required this.scrollController,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final history = BrowserService.instance.history;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.history, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('History', style: theme.textTheme.titleLarge),
                const Spacer(),
                if (history.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear History'),
                          content: const Text(
                            'Are you sure you want to clear your browsing history?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed ?? false) {
                        await BrowserService.instance.clearHistory();
                      }
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          const Divider(),
          // History list
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No history yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pages you visit will appear here',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final url = history[index];
                      return ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(
                          url,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onHistoryTap(url),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
