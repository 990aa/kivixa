// To enable sync, contributors can enable their own keys locally.
// The app is fully functional offline by default.

abstract class SyncAdapter {
  Future<void> sync();
}

class GoogleDriveSyncAdapter implements SyncAdapter {
  @override
  Future<void> sync() {
    throw UnimplementedError('Google Drive sync is not enabled. See sync_adapter.dart for details.');
  }
}

class OneDriveSyncAdapter implements SyncAdapter {
  @override
  Future<void> sync() {
    throw UnimplementedError('OneDrive sync is not enabled. See sync_adapter.dart for details.');
  }
}