import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/components/settings/app_info.dart';
import 'package:kivixa/components/settings/update_manager.dart';
import 'package:kivixa/components/theming/adaptive_linear_progress_indicator.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

/// A full-screen page that handles app update downloads with progress display.
/// On Windows, closes the app after download completes to avoid installer conflicts.
class UpdateLoadingPage extends StatefulWidget {
  const UpdateLoadingPage({super.key});

  static Future<void> open(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const UpdateLoadingPage()));
  }

  @override
  State<UpdateLoadingPage> createState() => _UpdateLoadingPageState();
}

class _UpdateLoadingPageState extends State<UpdateLoadingPage> {
  String? _downloadUrl;
  TaskStatus? _status;
  final _progress = ValueNotifier<double?>(null);
  var _started = false;

  @override
  void initState() {
    super.initState();
    _loadAndStart();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _loadAndStart() async {
    _downloadUrl = await UpdateManager.getLatestDownloadUrl();
    if (!mounted) return;
    setState(() {});

    if (_downloadUrl == null) return;
    await _startDownload(_downloadUrl!);
  }

  Future<void> _startDownload(String downloadUrl) async {
    if (_started) return;
    _started = true;

    final fileName = downloadUrl.substring(downloadUrl.lastIndexOf('/') + 1);
    final task = DownloadTask(
      url: downloadUrl,
      filename: fileName,
      baseDirectory: BaseDirectory.temporary,
    );

    final result = await FileDownloader().download(
      task,
      onStatus: (status) {
        _status = status;
        if (mounted) setState(() {});
      },
      onProgress: (progress) {
        _progress.value = progress;
      },
    );

    if (result.status == TaskStatus.complete) {
      final path = await task.filePath();
      await OpenFile.open(path);

      // Avoid installer/update conflicts by closing the running app on Windows.
      if (defaultTargetPlatform == TargetPlatform.windows) {
        exit(0);
      }
    }

    if (mounted) setState(() {});
  }

  bool get _downloadNotAvailableYet {
    return UpdateManager.platformFileRegex.containsKey(defaultTargetPlatform) &&
        _downloadUrl == null;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress.value;
    final percent = progress == null ? null : (progress * 100).clamp(0, 100);

    return Scaffold(
      appBar: AppBar(title: Text(t.update.update)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.update.updateAvailable,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(t.update.updateAvailableDescription),
            const SizedBox(height: 16),
            if (_downloadNotAvailableYet)
              Text(
                t.update.downloadNotAvailableYet,
                style: TextStyle(color: ColorScheme.of(context).error),
              ),
            if (progress != null) ...[
              AdaptiveLinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text('${percent!.toStringAsFixed(0)}%'),
            ] else if (_downloadUrl != null) ...[
              const AdaptiveLinearProgressIndicator(value: null),
              const SizedBox(height: 8),
              Text(t.update.update),
            ],
            const SizedBox(height: 12),
            if (_status != null)
              Text(
                _status.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const Spacer(),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    MaterialLocalizations.of(context).modalBarrierDismissLabel,
                  ),
                ),
                const Spacer(),
                if (_downloadUrl == null)
                  FilledButton(
                    onPressed: () => launchUrl(AppInfo.releasesUrl),
                    child: Text(t.update.update),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
