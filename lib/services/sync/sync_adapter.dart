// lib/services/sync/sync_adapter.dart

/// Defines the interface for a cloud sync provider.
///
/// This allows for a modular approach to implementing different cloud
/// storage services like Google Drive, OneDrive, etc.
abstract class SyncAdapter {
  /// Returns true if the sync provider is enabled and configured.
  bool get isEnabled;

  /// Initiates the authentication flow with the sync provider.
  ///
  /// This should handle all the necessary steps to get an authenticated
  /// client that can make API requests.
  Future<void> authenticate();

  /// Uploads a file to the sync provider.
  ///
  /// [localPath] is the path to the file on the local device.
  /// [remotePath] is the desired path in the cloud storage.
  Future<void> uploadFile(String localPath, String remotePath);

  /// Downloads a file from the sync provider.
  ///
  /// [remotePath] is the path of the file in the cloud storage.
  /// [localPath] is the destination path on the local device.
  Future<void> downloadFile(String remotePath, String localPath);

  /// Deletes a file from the sync provider.
  Future<void> deleteFile(String remotePath);


  /// Lists files in a remote directory.
  Future<List<String>> listFiles(String remotePath);
}

/// A stub implementation for Google Drive sync.
///
/// This is disabled by default. To enable, developers must provide their
/// own API keys as described in the README.md file in this directory.
class GoogleDriveSyncAdapter implements SyncAdapter {
  @override
  bool get isEnabled => false; // Disabled by default

  @override
  Future<void> authenticate() {
    if (!isEnabled) {
      throw UnimplementedError("Google Drive Sync is not enabled. See lib/services/sync/README.md");
    }
    // Implementation would go here.
    return Future.value();
  }

  @override
  Future<void> downloadFile(String remotePath, String localPath) {
     if (!isEnabled) {
      throw UnimplementedError("Google Drive Sync is not enabled. See lib/services/sync/README.md");
    }
    // Implementation would go here.
    return Future.value();
  }

  @override
  Future<void> uploadFile(String localPath, String remotePath) {
     if (!isEnabled) {
      throw UnimplementedError("Google Drive Sync is not enabled. See lib/services/sync/README.md");
    }
    // Implementation would go here.
    return Future.value();
  }

  @override
  Future<void> deleteFile(String remotePath) {
    if (!isEnabled) {
      throw UnimplementedError("Google Drive Sync is not enabled. See lib/services/sync/README.md");
    }
    // Implementation would go here.
    return Future.value();
  }

    @override
  Future<List<String>> listFiles(String remotePath) {
     if (!isEnabled) {
      throw UnimplementedError("Google Drive Sync is not enabled. See lib/services/sync/README.md");
    }
    // Implementation would go here.
    return Future.value([]);
  }
}

/// A stub implementation for OneDrive sync.
///
/// This is disabled by default. To enable, developers must provide their
/// own API keys as described in the README.md file in this directory.
class OneDriveSyncAdapter implements SyncAdapter {
  @override
  bool get isEnabled => false; // Disabled by default

  @override
  Future<void> authenticate() {
    if (!isEnabled) {
      throw UnimplementedError("OneDrive Sync is not enabled. See lib/services/sync/README.md");
    }
    // Implementation would go here.
    return Future.value();
  }

  @override
  Future<void> downloadFile(String remotePath, String localPath) {
     if (!isEnabled) {
      throw UnimplementedError("OneDrive Sync is not enabled. See lib/services/sync/README.md");
    }
    // Implementation would go here.
    return Future.value();
  }

  @override
  Future<void> uploadFile(String localPath, String remotePath) {
     if (!isEnabled) {
      throw UnimplementedError("OneDrive Sync is not enabled. See lib/services/sync/README.md");
    }
    // Implementation would go here.
    return Future.value();
  }

   @override
  Future<void> deleteFile(String remotePath) {
    if (!isEnabled) {
      throw UnimplementedError("OneDrive Sync is not enabled. See lib/services/sync/README.md");
    }
    // Implementation would go here.
    return Future.value();
  }

  @override
  Future<List<String>> listFiles(String remotePath) {
     if (!isEnabled) {
      throw UnimplementedError("OneDrive Sync is not enabled. See lib/services/sync/README.md");
    }
    // Implementation would go here.
    return Future.value([]);
  }
}

/// A sync manager that guards against running sync operations when offline
/// or when no provider is enabled. This ensures the app remains fully
/// functional offline.
class SyncManager {
  final SyncAdapter? _adapter;

  SyncManager({SyncAdapter? adapter}) : _adapter = adapter;

  bool get isSyncEnabled => _adapter?.isEnabled ?? false;

  Future<void> uploadFile(String localPath, String remotePath) {
    if (!isSyncEnabled) return Future.value();
    return _adapter!.uploadFile(localPath, remotePath);
  }

  Future<void> downloadFile(String remotePath, String localPath) {
    if (!isSyncEnabled) return Future.value();
    return _adapter!.downloadFile(remotePath, localPath);
  }

  Future<void> deleteFile(String remotePath) {
    if (!isSyncEnabled) return Future.value();
    return _adapter!.deleteFile(remotePath);
  }

  Future<List<String>> listFiles(String remotePath) {
    if (!isSyncEnabled) return Future.value([]);
    return _adapter!.listFiles(remotePath);
  }
}
