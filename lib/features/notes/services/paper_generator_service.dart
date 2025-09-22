import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/features/notes/models/paper_settings.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaperGeneratorService {
  WebViewController? _controller;
  final Map<String, Uint8List> _cache = {};
  final Completer<void> _webViewReadyCompleter = Completer<void>();

  PaperGeneratorService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PaperGeneratorChannel',
        onMessageReceived: (JavaScriptMessage message) {
          // Handle messages from JS. For now, we handle it in the generatePaper method.
        },
      )
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (!_webViewReadyCompleter.isCompleted) {
              _webViewReadyCompleter.complete();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            if (!_webViewReadyCompleter.isCompleted) {
              _webViewReadyCompleter.completeError(error);
            }
          },
        ),
      );

    try {
      final htmlContent = await rootBundle.loadString(
        'assets/paper.html',
      );
      await _controller!.loadHtmlString(
        htmlContent,
        baseUrl: 'https://flutter.dev',
      );
    } catch (e) {
      debugPrint('Error loading HTML file: $e');
      if (!_webViewReadyCompleter.isCompleted) {
        _webViewReadyCompleter.completeError(e);
      }
    }
  }

  Future<Uint8List> generatePaper({
    required PaperType paperType,
    required PaperSize paperSize,
    required PaperOptions options,
    bool useCache = true,
  }) async {
    final cacheKey =
        '${paperType.toString()}_${paperSize.width}x${paperSize.height}_${options.hashCode}';
    if (useCache && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    await _webViewReadyCompleter.future;

    final completer = Completer<Uint8List>();

    // Temporarily override the channel receiver to handle this specific request
    _controller!.addJavaScriptChannel(
      'PaperGeneratorChannel',
      onMessageReceived: (JavaScriptMessage message) {
        if (message.message.startsWith('ERROR:')) {
          completer.completeError(message.message);
        } else {
          final base64String = message.message.split(',').last;
          final imageBytes = base64Decode(base64String);
          if (useCache) {
            _cache[cacheKey] = imageBytes;
          }
          completer.complete(imageBytes);
        }
      },
    );

    final params = {
      'paperType': paperType.name,
      'width': paperSize.width,
      'height': paperSize.height,
      'options': options.toJson(),
    };
    final jsonParams = jsonEncode(params);

    // Execute JS
    await _controller!.runJavaScript('generate(`$jsonParams`)');

    return completer.future;
  }

  void dispose() {
    _controller = null;
    _cache.clear();
  }
}
