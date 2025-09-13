import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class BackupManager {
  Future<void> createBackup(String destinationPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(appDir.path, 'db.sqlite'));
    final assetsDir = Directory(p.join(appDir.path, 'assets'));

    final manifest = {
      'createdAt': DateTime.now().toIso8601String(),
      'files': [],
    };

    final encoder = ZipFileEncoder();
    encoder.create(destinationPath);

    // Add database
    final dbBytes = await dbFile.readAsBytes();
    final dbHash = sha256.convert(dbBytes).toString();
    manifest['files'].add({'path': 'db.sqlite', 'hash': dbHash});
    encoder.addArchiveFile(ArchiveFile('db.sqlite', dbBytes.length, dbBytes));

    // Add assets
    if (await assetsDir.exists()) {
      final files = await assetsDir.list(recursive: true).toList();
      for (final file in files) {
        if (file is File) {
          final relativePath = p.relative(file.path, from: appDir.path);
          final fileBytes = await file.readAsBytes();
          final fileHash = sha256.convert(fileBytes).toString();
          manifest['files'].add({'path': relativePath, 'hash': fileHash});
          encoder.addArchiveFile(ArchiveFile(relativePath, fileBytes.length, fileBytes));
        }
      }
    }

    // Add manifest
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    encoder.addArchiveFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    encoder.close();
  }

  Future<bool> validateBackup(String backupPath) async {
    final archive = ZipDecoder().decodeBytes(await File(backupPath).readAsBytes());
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      return false;
    }

    final manifest = jsonDecode(utf8.decode(manifestFile.content));
    for (final fileEntry in manifest['files']) {
      final file = archive.findFile(fileEntry['path']);
      if (file == null) {
        return false;
      }
      final hash = sha256.convert(file.content).toString();
      if (hash != fileEntry['hash']) {
        return false;
      }
    }

    return true;
  }

  Future<void> restoreBackup(String backupPath) async {
    if (!await validateBackup(backupPath)) {
      throw Exception('Backup is invalid');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final archive = ZipDecoder().decodeBytes(await File(backupPath).readAsBytes());

    for (final file in archive) {
      if (file.name != 'manifest.json') {
        final path = p.join(appDir.path, file.name);
        final outFile = File(path);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content);
      }
    }
  }
}