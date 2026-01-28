import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:kivixa/components/settings/app_info.dart';
import 'package:kivixa/components/settings/update_manager.dart';
import 'package:kivixa/components/theming/adaptive_alert_dialog.dart';
import 'package:kivixa/data/kivixa_version.dart';
import 'package:kivixa/data/version.dart' as version;
import 'package:url_launcher/url_launcher.dart';

/// A dialog that shows current version, latest version, and changelog.
/// Renamed from ReleaseNotesDialog to UpdatesDialog for clarity.
/// Shows "Update available" when there's actually a newer version.
class UpdatesDialog extends StatefulWidget {
  const UpdatesDialog({super.key});

  @override
  State<UpdatesDialog> createState() => _UpdatesDialogState();
}

class _UpdatesDialogState extends State<UpdatesDialog> {
  var _isLoading = true;
  String? _changelog;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
    // Listen to background download state changes
    UpdateManager.backgroundState.addListener(_onBackgroundStateChanged);
    UpdateManager.downloadProgress.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    UpdateManager.backgroundState.removeListener(_onBackgroundStateChanged);
    UpdateManager.downloadProgress.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onBackgroundStateChanged() {
    if (mounted) setState(() {});
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadVersionInfo() async {
    try {
      // Force fresh check - clear cached version first
      UpdateManager.newestVersion = null;

      // Check for updates - this fetches from GitHub and populates UpdateManager fields
      await UpdateManager.checkForUpdate();

      // Get changelog (uses release body from GitHub if available)
      _changelog = await UpdateManager.getChangelog();
    } catch (e) {
      _errorMessage = 'Could not check for updates: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Manual refresh - clear cache and re-fetch
  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _changelog = null;
    });
    await _loadVersionInfo();
  }

  /// Check if an update is truly available using semantic version comparison.
  /// Returns false if versions are equal or current is newer.
  bool get _hasUpdate => UpdateManager.isUpdateAvailable();
  bool get _isAndroid => Platform.isAndroid;

  String get _currentVersionString => version.buildName;

  String? get _latestVersionString {
    // Use the version name from GitHub API if available
    if (UpdateManager.latestVersionName != null) {
      return UpdateManager.latestVersionName;
    }
    // Fallback to build number conversion
    if (UpdateManager.newestVersion == null) return null;
    final ver = KivixaVersion.fromNumber(UpdateManager.newestVersion!);
    return ver.buildName;
  }

  Future<void> _startUpdate() async {
    final downloadUrl = await UpdateManager.getLatestDownloadUrl();
    if (downloadUrl == null) {
      launchUrl(AppInfo.releasesUrl);
      return;
    }
    if (!mounted) return;

    // Start background download instead of blocking UI
    UpdateManager.startBackgroundUpdate();
  }

  Future<void> _installUpdate() async {
    await UpdateManager.installUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final backgroundState = UpdateManager.backgroundState.value;
    final downloadProgress = UpdateManager.downloadProgress.value;

    return AdaptiveAlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Updates')),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Check for updates',
            ),
        ],
      ),
      content: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400, maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
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
                    else if (backgroundState ==
                        BackgroundUpdateState.downloading)
                      _buildDownloadProgress(context, downloadProgress)
                    else if (backgroundState ==
                        BackgroundUpdateState.readyToInstall)
                      _buildReadyToInstall(context)
                    else if (backgroundState ==
                        BackgroundUpdateState.installing)
                      _buildInstalling(context)
                    else if (backgroundState == BackgroundUpdateState.error)
                      _buildDownloadError(context)
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Update available!',
                                    style: TextStyle(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_isAndroid)
                                    Text(
                                      'Get the latest version from F-Droid',
                                      style: TextStyle(
                                        color: colorScheme.onPrimaryContainer
                                            .withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
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
                      MarkdownBody(
                        data: _changelog!,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          h1: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          h2: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          h3: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          p: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                          listBullet: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      actions: _buildActions(context, backgroundState),
    );
  }

  Widget _buildDownloadProgress(BuildContext context, double progress) {
    final colorScheme = ColorScheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Downloading update... ${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.onPrimaryContainer.withValues(
              alpha: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can close this dialog and continue working.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToInstall(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.download_done, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Update downloaded! Ready to install.',
              style: TextStyle(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstalling(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Installing update...',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadError(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Download failed. Please try again.',
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  List<CupertinoDialogAction> _buildActions(
    BuildContext context,
    BackgroundUpdateState state,
  ) {
    final actions = <CupertinoDialogAction>[
      CupertinoDialogAction(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).closeButtonLabel),
      ),
    ];

    switch (state) {
      case BackgroundUpdateState.idle:
        if (_hasUpdate) {
          if (_isAndroid) {
            // On Android, direct users to F-Droid for updates
            actions.add(
              CupertinoDialogAction(
                onPressed: () => launchUrl(
                  Uri.parse('https://990aa.github.io/kivixa/repo'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('Get from F-Droid'),
              ),
            );
          } else {
            // On Windows/other platforms, allow direct download
            actions.add(
              CupertinoDialogAction(
                onPressed: _startUpdate,
                child: const Text('Download Update'),
              ),
            );
          }
        }
      case BackgroundUpdateState.downloading:
        actions.add(
          CupertinoDialogAction(
            onPressed: () {
              UpdateManager.cancelBackgroundUpdate();
            },
            isDestructiveAction: true,
            child: const Text('Cancel'),
          ),
        );
      case BackgroundUpdateState.readyToInstall:
        actions.add(
          CupertinoDialogAction(
            onPressed: _installUpdate,
            child: const Text('Install & Restart'),
          ),
        );
      case BackgroundUpdateState.installing:
        // No actions while installing
        break;
      case BackgroundUpdateState.error:
        actions.add(
          CupertinoDialogAction(
            onPressed: () {
              UpdateManager.cancelBackgroundUpdate();
              _startUpdate();
            },
            child: const Text('Retry'),
          ),
        );
    }

    return actions;
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

/// Backwards-compatible alias for UpdatesDialog
@Deprecated('Use UpdatesDialog instead')
typedef ReleaseNotesDialog = UpdatesDialog;
