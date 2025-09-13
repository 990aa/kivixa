// Platform-specific storage paths for DB and assets.
// Android: applicationDocumentsDirectory
// Windows: getApplicationSupportDirectory
// Subfolders: db/, assets_original/, assets_cache/, exports/, backups/
// Only relative paths are stored in SQLite.

import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StoragePaths {
  static Future<Directory> getBaseDir() async {
    if (Platform.isAndroid) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      return await getApplicationSupportDirectory();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static Future<Directory> getDbDir() async {
    final base = await getBaseDir();
    final dir = Directory('${base.path}/db');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> getAssetsOriginalDir() async {
    final base = await getBaseDir();
    final dir = Directory('${base.path}/assets_original');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> getAssetsCacheDir() async {
    final base = await getBaseDir();
    final dir = Directory('${base.path}/assets_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> getExportsDir() async {
    final base = await getBaseDir();
    final dir = Directory('${base.path}/exports');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> getBackupsDir() async {
    final base = await getBaseDir();
    final dir = Directory('${base.path}/backups');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
