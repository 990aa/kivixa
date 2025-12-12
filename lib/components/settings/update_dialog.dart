import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/components/settings/app_info.dart';
import 'package:kivixa/components/settings/update_loading_page.dart';
import 'package:kivixa/components/settings/update_manager.dart';
import 'package:kivixa/components/theming/adaptive_alert_dialog.dart';
import 'package:kivixa/components/theming/adaptive_linear_progress_indicator.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  String? directDownloadLink;
  var downloadNotAvailableYet = false;

  /// Null if not started yet, or the [TaskStatus] of the download.
  TaskStatus? directDownloadStatus;

  /// Null if not started yet, or the progress (0.0 to 1.0) of the download.
  final directDownloadProgress = ValueNotifier<double?>(null);

  // English-only: no locale switching needed
  String? englishChangelog;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    directDownloadProgress.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    directDownloadLink = await UpdateManager.getLatestDownloadUrl();
    if (!mounted) return;
    downloadNotAvailableYet =
        UpdateManager.platformFileRegex.containsKey(defaultTargetPlatform) &&
        directDownloadLink == null;

    englishChangelog = await UpdateManager.getChangelog();
    if (!mounted) return;
    setState(() {});
  }

  bool get _canStartDownload {
    if (downloadNotAvailableYet) return false;
    if (directDownloadStatus?.isNotFinalState ?? false) return false;
    return true;
  }

  Future<void> _startDownload() async {
    if (!_canStartDownload) return;
    if (directDownloadLink == null) {
      launchUrl(AppInfo.releasesUrl);
      return;
    }
    if (!mounted) return;

    Navigator.of(context).pop();
    if (!mounted) return;
    await UpdateLoadingPage.open(context);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveAlertDialog(
      title: Text(t.update.updateAvailable),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.update.updateAvailableDescription),

          if (englishChangelog != null) Text(englishChangelog!),

          if (downloadNotAvailableYet)
            Text(
              t.update.downloadNotAvailableYet,
              style: TextStyle(color: ColorScheme.of(context).error),
            ),

          ValueListenableBuilder(
            valueListenable: directDownloadProgress,
            builder: (context, progress, _) {
              if (progress == null) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: AdaptiveLinearProgressIndicator(value: progress),
              );
            },
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
          ),
        ),
        CupertinoDialogAction(
          onPressed: _canStartDownload ? _startDownload : null,
          child: Text(t.update.update),
        ),
      ],
    );
  }
}
