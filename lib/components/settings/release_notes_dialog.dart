import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/components/settings/app_info.dart';
import 'package:kivixa/components/settings/update_loading_page.dart';
import 'package:kivixa/components/settings/update_manager.dart';
import 'package:kivixa/components/theming/adaptive_alert_dialog.dart';
import 'package:kivixa/data/kivixa_version.dart';
import 'package:kivixa/data/version.dart' as version;
import 'package:url_launcher/url_launcher.dart';

/// A dialog that shows current version, latest version, and changelog.
/// Only shows "Update available" when there's actually a newer version.
class ReleaseNotesDialog extends StatefulWidget {
  const ReleaseNotesDialog({super.key});

  @override
  State<ReleaseNotesDialog> createState() => _ReleaseNotesDialogState();
}

class _ReleaseNotesDialogState extends State<ReleaseNotesDialog> {
  var _isLoading = true;
  String? _changelog;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      // Check for updates - this populates UpdateManager.newestVersion
      await UpdateManager.checkForUpdate();

      if (UpdateManager.newestVersion != null) {
        _changelog = await UpdateManager.getChangelog();
      }
    } catch (e) {
      _errorMessage = 'Could not check for updates';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _hasUpdate {
    final latestVersion = UpdateManager.newestVersion;
    if (latestVersion == null) return false;
    // Compare ignoring revision
    final current = KivixaVersion.fromNumber(
      version.buildNumber,
    ).copyWith(revision: 0);
    final latest = KivixaVersion.fromNumber(
      latestVersion,
    ).copyWith(revision: 0);
    return latest.buildNumber > current.buildNumber;
  }

  String get _currentVersionString => version.buildName;

  String? get _latestVersionString {
    final latestVersion = UpdateManager.newestVersion;
    if (latestVersion == null) return null;
    final ver = KivixaVersion.fromNumber(latestVersion);
    return ver.buildName;
  }

  Future<void> _startUpdate() async {
    final downloadUrl = await UpdateManager.getLatestDownloadUrl();
    if (downloadUrl == null) {
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
    final colorScheme = ColorScheme.of(context);

    return AdaptiveAlertDialog(
      title: const Text('Release Notes'),
      content: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Version info
                _VersionRow(
                  label: 'Current version',
                  version: _currentVersionString,
                ),
                const SizedBox(height: 8),
                _VersionRow(
                  label: 'Latest version',
                  version: _latestVersionString ?? 'Unknown',
                  isHighlighted: _hasUpdate,
                ),

                // Update status
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: colorScheme.error),
                  )
                else if (_hasUpdate)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.system_update,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Update available!',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('You\'re up to date!'),
                    ],
                  ),

                // Changelog
                if (_changelog != null && _changelog!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'What\'s New',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_changelog!),
                ],
              ],
            ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
        if (_hasUpdate)
          CupertinoDialogAction(
            onPressed: _startUpdate,
            child: const Text('Update'),
          ),
      ],
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.version,
    this.isHighlighted = false,
  });

  final String label;
  final String version;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlighted
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            version,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlighted
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
