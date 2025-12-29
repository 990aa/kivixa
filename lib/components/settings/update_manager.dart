import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
import 'package:path_provider/path_provider.dart';

abstract class UpdateManager {
  static final log = Logger('UpdateManager');

  /// GitHub releases API endpoint - fetches from actual releases
  static final Uri apiUrl = Uri.parse(
    'https://api.github.com/repos/990aa/kivixa/releases/latest',
  );

  /// The availability of an update.
  static final ValueNotifier<UpdateStatus> status = ValueNotifier(
    UpdateStatus.upToDate,
  );

  /// Cached latest version info
  static int? newestVersion;
  static String? latestVersionName;
  static String? latestReleaseBody;

  /// Background download state
  static final ValueNotifier<BackgroundUpdateState> backgroundState =
      ValueNotifier(BackgroundUpdateState.idle);
  static final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  static String? downloadedFilePath;

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
      final versionInfo = await fetchLatestVersionFromGitHub();
      newestVersion = versionInfo.$1;
      latestVersionName = versionInfo.$2;
      latestReleaseBody = versionInfo.$3;
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

  /// Fetches the latest release from GitHub API and returns (buildNumber, versionName, releaseBody)
  static Future<(int?, String?, String?)> fetchLatestVersionFromGitHub([
    String? apiResponse,
  ]) async {
    if (apiResponse == null) {
      final http.Response response;
      try {
        response = await http.get(
          apiUrl,
          headers: {'Accept': 'application/vnd.github.v3+json'},
        );
      } catch (e) {
        throw SocketException('Failed to fetch latest release: $e');
      }
      if (response.statusCode >= 400) {
        throw SocketException(
          'Failed to fetch latest release, HTTP status code ${response.statusCode}',
        );
      }
      apiResponse = response.body;
    }

    final Map<String, dynamic> json = jsonDecode(apiResponse);

    // Get tag_name (e.g., "v0.1.3+1003")
    final String? tagName = json['tag_name'] as String?;
    final String? releaseBody = json['body'] as String?;

    if (tagName == null) {
      return (null, null, null);
    }

    // Parse version from tag (format: "v0.1.3+1003" where 1003 is build number)
    final match = RegExp(
      r'v?(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?',
    ).firstMatch(tagName);
    if (match == null) {
      return (null, null, null);
    }

    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);

    // The build number is specified directly in the tag (e.g., +1003)
    // If not present, calculate from version components as fallback
    final int buildNumber;
    if (match.group(4) != null) {
      buildNumber = int.parse(match.group(4)!);
    } else {
      buildNumber = KivixaVersion(major, minor, patch, 0).buildNumber;
    }
    final versionName = '$major.$minor.$patch';

    log.info(
      'Fetched latest version from GitHub: $versionName (build $buildNumber)',
    );

    return (buildNumber, versionName, releaseBody);
  }

  /// Returns the version number hosted on GitHub.
  /// If you provide a [latestVersionFile] (i.e. for testing),
  /// it will be used instead of downloading from GitHub.
  @visibleForTesting
  static Future<int?> getNewestVersion([String? latestVersionFile]) async {
    if (latestVersionFile != null) {
      // Parse test data
      final trimmed = latestVersionFile.trimLeft();
      if (trimmed.startsWith('{')) {
        final result = await fetchLatestVersionFromGitHub(latestVersionFile);
        return result.$1;
      }
      // Fallback to version.dart format
      final buildNumberMatch = RegExp(
        r'const\s+buildNumber\s*=\s*(\d+)\s*;',
      ).firstMatch(latestVersionFile);
      return int.tryParse(buildNumberMatch?.group(1) ?? '0');
    }

    final result = await fetchLatestVersionFromGitHub();
    return result.$1;
  }

  @visibleForTesting
  static UpdateStatus getUpdateStatus(
    int currentVersionNumber,
    int newestVersionNumber,
  ) {
    final currentVersion = KivixaVersion.fromNumber(currentVersionNumber);
    final newestVersion = KivixaVersion.fromNumber(newestVersionNumber);

    // Proper semantic version comparison: major.minor.patch
    // Compare major first, then minor, then patch
    final comparison = compareVersions(currentVersion, newestVersion);

    if (comparison >= 0) {
      // Current version is equal to or newer than latest
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

  /// Compare two versions semantically.
  /// Returns negative if v1 < v2, zero if v1 == v2, positive if v1 > v2
  @visibleForTesting
  static int compareVersions(KivixaVersion v1, KivixaVersion v2) {
    // Compare major version
    if (v1.major != v2.major) {
      return v1.major - v2.major;
    }
    // Compare minor version
    if (v1.minor != v2.minor) {
      return v1.minor - v2.minor;
    }
    // Compare patch version
    if (v1.patch != v2.patch) {
      return v1.patch - v2.patch;
    }
    // Compare revision (ignore for update comparison - treat as equal)
    return 0;
  }

  /// Check if an update is available (latest > current)
  static bool isUpdateAvailable() {
    if (newestVersion == null) return false;
    final current = KivixaVersion.fromNumber(version.buildNumber);
    final latest = KivixaVersion.fromNumber(newestVersion!);
    return compareVersions(current, latest) < 0;
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
    final assets = json['assets'] as List;

    // For Android, try to find the APK matching the device architecture
    if (platform == TargetPlatform.android) {
      final archSuffix = await _getAndroidArchSuffix();
      if (archSuffix != null) {
        // Try to find architecture-specific APK first (e.g., Kivixa-Android-0.1.2-arm64.apk)
        final archAsset = assets.firstWhere(
          (asset) =>
              (asset['name'] as String).toLowerCase().contains(archSuffix) &&
              (asset['name'] as String).endsWith('.apk') &&
              !(asset['name'] as String).toLowerCase().contains('foss'),
          orElse: () => null,
        );
        if (archAsset != null) {
          return archAsset['browser_download_url'];
        }
      }
    }

    // Fallback to generic pattern matching
    final RegExp platformFileRegex = UpdateManager.platformFileRegex[platform]!;
    final Map<String, dynamic>? asset = assets.firstWhere(
      (asset) => platformFileRegex.hasMatch(asset['name']),
      orElse: () => null,
    );
    return asset?['browser_download_url'];
  }

  /// Gets the Android architecture suffix for the current device
  static Future<String?> _getAndroidArchSuffix() async {
    if (!Platform.isAndroid) return null;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final abis = androidInfo.supportedAbis;

      // Map ABIs to our naming convention
      if (abis.contains('arm64-v8a')) return 'arm64';
      if (abis.contains('armeabi-v7a')) return 'armv7';
      if (abis.contains('x86_64')) return 'x86_64';

      return null;
    } catch (e) {
      log.warning('Failed to get Android architecture: $e');
      return null;
    }
  }

  static final Map<TargetPlatform, RegExp> platformFileRegex = {
    // e.g. Kivixa-Setup-0.1.2.exe
    TargetPlatform.windows: RegExp(
      r'Kivixa-Setup-[\d.]+\.exe',
      caseSensitive: false,
    ),

    // e.g. Kivixa-Android-0.1.2-arm64.apk (not FOSS)
    TargetPlatform.android: RegExp(
      r'^Kivixa-Android-[\d.]+-(?:arm64|armv7|x86_64)\.apk$',
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

  /// Start downloading update in the background.
  /// User can continue working while the download happens.
  static Future<void> startBackgroundUpdate() async {
    if (backgroundState.value == BackgroundUpdateState.downloading) {
      log.info('Background download already in progress');
      return;
    }

    final downloadUrl = await getLatestDownloadUrl();
    if (downloadUrl == null) {
      log.warning('No download URL available for this platform');
      backgroundState.value = BackgroundUpdateState.error;
      return;
    }

    backgroundState.value = BackgroundUpdateState.downloading;
    downloadProgress.value = 0.0;
    downloadedFilePath = null;

    final fileName = downloadUrl.substring(downloadUrl.lastIndexOf('/') + 1);

    // Get the downloads/temp directory
    final tempDir = await getTemporaryDirectory();
    final updateDir = Directory('${tempDir.path}/kivixa_updates');
    if (!await updateDir.exists()) {
      await updateDir.create(recursive: true);
    }

    final task = DownloadTask(
      url: downloadUrl,
      filename: fileName,
      directory: updateDir.path,
    );

    log.info('Starting background download: $downloadUrl');

    final result = await FileDownloader().download(
      task,
      onStatus: (status) {
        log.info('Background download status: $status');
        if (status == TaskStatus.failed || status == TaskStatus.canceled) {
          backgroundState.value = BackgroundUpdateState.error;
        }
      },
      onProgress: (progress) {
        downloadProgress.value = progress;
      },
    );

    if (result.status == TaskStatus.complete) {
      downloadedFilePath = await task.filePath();
      backgroundState.value = BackgroundUpdateState.readyToInstall;
      log.info('Background download complete: $downloadedFilePath');
    } else {
      backgroundState.value = BackgroundUpdateState.error;
      log.severe(
        'Background download failed: ${result.status} ${result.exception}',
      );
    }
  }

  /// Install the downloaded update.
  /// On Windows, this will close the app to avoid installer conflicts.
  static Future<void> installUpdate() async {
    if (downloadedFilePath == null) {
      log.warning('No downloaded file to install');
      return;
    }

    backgroundState.value = BackgroundUpdateState.installing;
    log.info('Installing update from: $downloadedFilePath');

    await OpenFile.open(downloadedFilePath!);

    // On Windows, exit the app to avoid conflicts with the installer
    if (defaultTargetPlatform == TargetPlatform.windows) {
      exit(0);
    }
  }

  /// Cancel any ongoing background download
  static void cancelBackgroundUpdate() {
    backgroundState.value = BackgroundUpdateState.idle;
    downloadProgress.value = 0.0;
    downloadedFilePath = null;
    // Note: FileDownloader doesn't expose a direct cancel method for our use case
  }

  static Future<String?> getChangelog({
    String localeCode = 'en-US',
    @visibleForTesting int? newestVersion,
  }) async {
    newestVersion ??= UpdateManager.newestVersion;

    // If we have release body from GitHub API, use that
    if (latestReleaseBody != null && latestReleaseBody!.isNotEmpty) {
      return latestReleaseBody;
    }

    // Fallback to metadata file
    if (newestVersion == null) return null;

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

/// State of the background update download
enum BackgroundUpdateState {
  /// No update in progress
  idle,

  /// Update is downloading in background
  downloading,

  /// Download complete, ready to install
  readyToInstall,

  /// Installing the update
  installing,

  /// An error occurred
  error,
}

enum UpdateStatus {
  /// The app is up to date, or I failed to check for an update.
  upToDate,

  /// An update is available, but the user doesn't need to be notified
  updateOptional,

  /// An update is available and the user should be notified
  updateRecommended,
}
