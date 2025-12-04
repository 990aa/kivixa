import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kivixa/components/overlay/floating_window.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';
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
  String _currentUrl = 'https://www.google.com';

  /// Whether we're on a desktop platform
  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    OverlayController.instance.addListener(_onOverlayChanged);
    _urlController.text = _currentUrl;
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
}
