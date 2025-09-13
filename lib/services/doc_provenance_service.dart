import 'package:kivixa/data/database.dart';

enum ProvenanceType {
  merge,
  split,
  raster,
}

class DocProvenanceService {
  final AppDatabase _db;

  DocProvenanceService(this._db);

  Future<void> recordProvenance({
    required String newDocumentId,
    required ProvenanceType type,
    required List<String> sourceDocumentIds,
  }) async {
    final companion = DocProvenanceCompanion.insert(
      newDocumentId: newDocumentId,
      type: type.toString(),
      sourceDocumentIds: sourceDocumentIds.join(','),
    );
    await _db.into(_db.docProvenance).insert(companion);
  }

  Future<List<DocProvenanceData>> getProvenance(String documentId) async {
    return (_db.select(_db.docProvenance)..where((tbl) => tbl.newDocumentId.equals(documentId))).get();
  }
}
