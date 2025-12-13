import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kivixa/components/settings/update_dialog.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/kivixa_version.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/data/version.dart' as version;
import 'package:logging/logging.dart';
import 'package:open_file/open_file.dart';

abstract class UpdateManager {
  static final log = Logger('UpdateManager');

  static final Uri versionUrl = Uri.parse(
    'https://raw.githubusercontent.com/990aa/kivixa/refs/heads/main/lib/data/version.dart',
  );
  static final Uri apiUrl = Uri.parse(
    'https://api.github.com/repos/990aa/kivixa/releases/latest',
  );

  /// The availability of an update.
  static final ValueNotifier<UpdateStatus> status = ValueNotifier(
    UpdateStatus.upToDate,
  );
  static int? newestVersion;

  static var _hasShownUpdateDialog = false;
  static Future<void> showUpdateDialog(
    BuildContext context, {
    bool userTriggered = false,
  }) async {
    if (!userTriggered) {
      // Don't check for updates if disabled in preferences
      await stows.shouldCheckForUpdates.waitUntilRead();
      if (!stows.shouldCheckForUpdates.value) return;

      if (status.value == UpdateStatus.upToDate) {
        // check for updates if not already done
        status.value = await checkForUpdate();
      }
      if (status.value != UpdateStatus.updateRecommended)
        return; // no update available
      if (_hasShownUpdateDialog) return; // already shown
    }

    if (!context.mounted) return;
    _hasShownUpdateDialog = true;
    return await showDialog(
      context: context,
      builder: (context) => const UpdateDialog(),
    );
  }

  /// Checks for updates and populates [newestVersion].
  /// Returns the update status.
  static Future<UpdateStatus> checkForUpdate() async {
    const int currentVersion = version.buildNumber;

    try {
      newestVersion = await getNewestVersion();
    } catch (e) {
      log.info(
        'Unable to check for update (this is normal for development/forks): $e',
      );
      return UpdateStatus.upToDate;
    }

    if (newestVersion == null) {
      log.info('Could not determine newest version, assuming up to date');
      return UpdateStatus.upToDate;
    }

    return getUpdateStatus(currentVersion, newestVersion ?? 0);
  }

  /// Returns the version number hosted on GitHub (at [versionUrl]).
  /// If you provide a [latestVersionFile] (i.e. for testing),
  /// it will be used instead of downloading from GitHub.
  @visibleForTesting
  static Future<int?> getNewestVersion([String? latestVersionFile]) async {
    latestVersionFile ??= await _downloadLatestVersionFileFromGitHub();

    // Some tests (and potential callers) pass the GitHub Releases API JSON.
    // If this looks like JSON, try to parse tag_name (e.g. "v1.0.0").
    final trimmed = latestVersionFile.trimLeft();
    if (trimmed.startsWith('{')) {
      try {
        final Map<String, dynamic> json = jsonDecode(latestVersionFile);
        final String? tagName =
            (json['tag_name'] as String?) ?? (json['name'] as String?);
        if (tagName != null) {
          final match = RegExp(
            r'v?(\d+\.\d+\.\d+)(?:\+(\d+))?',
          ).firstMatch(tagName);
          final versionName = match?.group(1);
          final buildMeta = match?.group(2);
          if (versionName != null) {
            final revision = int.tryParse(buildMeta ?? '0') ?? 0;
            return KivixaVersion.fromName(
              versionName,
            ).copyWith(revision: revision).buildNumber;
          }
        }

        // Final fallback: parse from an asset download URL like
        // https://github.com/<org>/<repo>/releases/download/v100000/<asset>
        final assets = json['assets'];
        if (assets is List && assets.isNotEmpty) {
          for (final asset in assets) {
            if (asset is! Map) continue;
            final url = asset['browser_download_url'];
            if (url is! String) continue;
            final m = RegExp(r'releases/download/v(\d+)/').firstMatch(url);
            final v = int.tryParse(m?.group(1) ?? '');
            if (v != null && v > 0) return v;
          }
        }

        // Last resort: parse a numeric tag_name like "v1000".
        if (tagName != null) {
          final numericTag = RegExp(r'v(\d+)').firstMatch(tagName)?.group(1);
          final numericTagValue = int.tryParse(numericTag ?? '');
          if (numericTagValue != null && numericTagValue > 0) {
            return numericTagValue;
          }
        }
      } catch (_) {
        // Fall through to the version.dart parsing logic below.
      }
    }

    // Extract buildNumber from a version.dart-like file.
    final buildNumberMatch = RegExp(
      r'const\s+buildNumber\s*=\s*(\d+)\s*;',
    ).firstMatch(latestVersionFile);
    final int newestVersion =
        int.tryParse(buildNumberMatch?.group(1) ?? '0') ?? 0;
    if (newestVersion == 0) return null;
    return newestVersion;
  }

  static Future<String> _downloadLatestVersionFileFromGitHub() async {
    // download the latest version.dart
    final http.Response response;
    try {
      response = await http.get(versionUrl);
    } catch (e) {
      throw SocketException('Failed to download version.dart, ${e.toString()}');
    }
    if (response.statusCode >= 400)
      throw SocketException(
        'Failed to download version.dart, HTTP status code ${response.statusCode}',
      );

    return response.body;
  }

  @visibleForTesting
  static UpdateStatus getUpdateStatus(
    int currentVersionNumber,
    int newestVersionNumber,
  ) {
    final currentVersion = KivixaVersion.fromNumber(
      currentVersionNumber,
    ).copyWith(revision: 0);
    final newestVersion = KivixaVersion.fromNumber(
      newestVersionNumber,
    ).copyWith(revision: 0);

    // Check if we're up to date
    if (newestVersion.buildNumber <= currentVersion.buildNumber) {
      return UpdateStatus.upToDate;
    }

    // Check if the update is low priority
    if (!stows.shouldAlwaysAlertForUpdates.value) {
      // Only prompt user every second patch
      if (newestVersion.buildNumber - currentVersion.buildNumber <
          KivixaVersion.fromName('0.0.2').buildNumber) {
        return UpdateStatus.updateOptional;
      }

      // Don't prompt user when patch version is 0 (e.g. 0.15.0)
      // since there might still be bugs to fix
      if (newestVersion.patch == 0) {
        return UpdateStatus.updateOptional;
      }
    }

    return UpdateStatus.updateRecommended;
  }

  static Future<String?> getLatestDownloadUrl([
    String? apiResponse,
    TargetPlatform? platform,
  ]) async {
    platform ??= defaultTargetPlatform;

    if (platform == TargetPlatform.android) {
      if (FlavorConfig.flavor.isNotEmpty) return null;
    }

    if (!UpdateManager.platformFileRegex.containsKey(platform)) return null;

    if (apiResponse == null) {
      final http.Response response;
      try {
        response = await http.get(apiUrl);
      } catch (e) {
        throw const SocketException('Failed to fetch latest release');
      }
      if (response.statusCode >= 400)
        throw SocketException(
          'Failed to fetch latest release, HTTP status code ${response.statusCode}',
        );
      apiResponse = response.body;
    }

    final Map<String, dynamic> json = jsonDecode(apiResponse);
    final RegExp platformFileRegex = UpdateManager.platformFileRegex[platform]!;
    final Map<String, dynamic>? asset = (json['assets'] as List).firstWhere(
      (asset) => platformFileRegex.hasMatch(asset['name']),
      orElse: () => null,
    );
    return asset?['browser_download_url'];
  }

  static final Map<TargetPlatform, RegExp> platformFileRegex = {
    TargetPlatform.windows: RegExp(r'\.exe'),

    // e.g. kivixa_v0.9.8.apk not kivixa_FOSS_v0.9.8.apk
    TargetPlatform.android: RegExp(
      r'^(?!.*FOSS).*\.apk$',
      caseSensitive: false,
    ),
  };

  /// Downloads the update file from [downloadUrl] and installs it.
  static Future<void> directlyDownloadUpdate(
    String downloadUrl, {
    required void Function(TaskStatus)? onStatus,
    required void Function(double)? onProgress,
  }) async {
    final fileName = downloadUrl.substring(downloadUrl.lastIndexOf('/') + 1);
    final task = DownloadTask(
      url: downloadUrl,
      filename: fileName,
      baseDirectory: BaseDirectory.temporary,
    );
    final result = await FileDownloader().download(
      task,
      onStatus: onStatus,
      onProgress: onProgress,
    );
    if (result.status == TaskStatus.complete) {
      log.info('Update downloaded successfully: ${result.status}');
      await OpenFile.open(await task.filePath());
    } else {
      log.severe(
        'Failed to download update from $downloadUrl: '
        '${result.status} ${result.exception} ${result.responseBody}',
      );
    }
  }

  static Future<String?> getChangelog({
    String localeCode = 'en-US',
    @visibleForTesting int? newestVersion,
  }) async {
    newestVersion ??= UpdateManager.newestVersion;
    assert(newestVersion != null);

    final url =
        'https://raw.githubusercontent.com/990aa/kivixa/refs/heads/main/'
        'metadata/$localeCode/changelogs/$newestVersion.txt';
    log.info('Downloading changelog from $url');

    final http.Response response;
    try {
      response = await http.get(Uri.parse(url));
    } catch (e) {
      log.severe('Failed to download changelog: $e', e);
      return null;
    }
    if (response.statusCode >= 400) return null;

    if (response.body.isEmpty) return null;
    return response.body;
  }
}

enum UpdateStatus {
  /// The app is up to date, or I failed to check for an update.
  upToDate,

  /// An update is available, but the user doesn't need to be notified
  updateOptional,

  /// An update is available and the user should be notified
  updateRecommended,
}
