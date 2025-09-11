import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class FileStorage {
  static Future<Directory> getStorageDirectory() async {
    if (Platform.isAndroid) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      return await getApplicationSupportDirectory();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  static Future<String> computeSha256(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Asset deduplication: returns existing file path or saves new asset
  static Future<String> saveAsset(File file, String extension) async {
    final dir = await getStorageDirectory();
    final hash = await computeSha256(file);
    final filePath = join(dir.path, '$hash.$extension');
    final outFile = File(filePath);
    if (!await outFile.exists()) {
      await outFile.writeAsBytes(await file.readAsBytes());
    }
    return filePath;
  }
}
