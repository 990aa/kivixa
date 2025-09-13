import 'package_stream/stream.dart';
import 'package:kivixa/data/database.dart';

class DocumentRepository {
  DocumentRepository(this._db);

  final AppDatabase _db;

  Stream<List<DocumentData>> watchDocuments() {
    return _db.select(_db.documents).watch();
  }

  Future<int> createDocument(String title) {
    return _db.into(_db.documents).insert(DocumentsCompanion.insert(title: title));
  }
}