import 'package:kivixa/services/import_manager.dart';
import 'package:kivixa/data/database.dart';
import 'package:drift/drift.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

class ShareImportService {
  final ImportManager _importManager;
  final AppDatabase _db;

  ShareImportService(this._importManager, this._db);

  Future<void> importFromUri(String uri) async {
    // This is a placeholder for the logic to copy the file from the URI
    // to a temporary location.
    final tempPath = await _copyFromUri(uri);

    final documentId = await _importManager.importFile(tempPath);

    final file = File(tempPath);
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    final size = await file.length();

    final companion = AssetsCompanion.insert(
      path: p.join('assets_original', documentId, p.basename(tempPath)),
      size: size,
      hash: hash,
      mime: 'application/octet-stream', // Placeholder
      sourceUri: Value(uri),
    );
    await _db.into(_db.assets).insert(companion);
  }

  Future<String> _copyFromUri(String uri) async {
    // In a real app, you would use a package like `receive_sharing_intent`
    // to get the file path from the URI.
    return uri;
  }
}
