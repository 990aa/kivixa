// ignore_for_file: unused_field

class SyncConfig {
  final bool isEnabled;
  final String? apiKey;
  final String? apiSecret;

  SyncConfig({this.isEnabled = false, this.apiKey, this.apiSecret});
}

abstract class SyncAdapter {
  Future<void> initialize(SyncConfig config);
  Future<void> sync();
  Future<void> upload(String fileId);
  Future<void> download(String fileId);
}

// App functions correctly offline by default.
// Sync is an optional, opt-in feature.
class OfflineGuard {
  bool _isSyncEnabled = false;

  void setSyncEnabled(bool isEnabled) {
    _isSyncEnabled = isEnabled;
  }

  bool get isSyncEnabled => _isSyncEnabled;

  Future<T> performAction<T>(Future<T> Function() onlineAction, Future<T> Function() offlineAction) async {
    if (_isSyncEnabled) {
      try {
        return await onlineAction();
      } catch (e) {
        // Fallback to offline action if online fails
        return await offlineAction();
      }
    } else {
      return await offlineAction();
    }
  }
}


// --- STUBS FOR CLOUD PROVIDERS ---

class GoogleDriveSyncAdapter implements SyncAdapter {
  late SyncConfig _config;

  @override
  Future<void> initialize(SyncConfig config) async {
    _config = config;
    if (!_config.isEnabled) return;
    // Initialize Google Drive SDK with apiKey
  }

  @override
  Future<void> sync() async {
    if (!_config.isEnabled) return;
    print('Syncing with Google Drive...');
  }

  @override
  Future<void> upload(String fileId) async {
    if (!_config.isEnabled) return;
    print('Uploading $fileId to Google Drive...');
  }

  @override
  Future<void> download(String fileId) async {
    if (!_config.isEnabled) return;
    print('Downloading $fileId from Google Drive...');
  }
}

class OneDriveSyncAdapter implements SyncAdapter {
  late SyncConfig _config;

  @override
  Future<void> initialize(SyncConfig config) async {
    _config = config;
    if (!_config.isEnabled) return;
    // Initialize OneDrive SDK with apiKey
  }

  @override
  Future<void> sync() async {
    if (!_config.isEnabled) return;
    print('Syncing with OneDrive...');
  }

  @override
  Future<void> upload(String fileId) async {
    if (!_config.isEnabled) return;
    print('Uploading $fileId to OneDrive...');
  }

  @override
  Future<void> download(String fileId) async {
    if (!_config.isEnabled) return;
    print('Downloading $fileId from OneDrive...');
  }
}
