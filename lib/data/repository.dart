import 'dart:async';
import 'package:kivixa/data/database.dart';

class DocumentRepository {
  DocumentRepository(this._db);

  final AppDatabase _db;

  Stream<List<DocumentData>> watchDocuments() {
    return _db.select(_db.documents).watch();
  }

  Future<DocumentData> getDocument(int id) {
    return (_db.select(_db.documents)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<DocumentData> createDocument(String title) {
    return _db.into(_db.documents).insertReturning(DocumentsCompanion.insert(title: title));
  }

  Future<bool> updateDocument(DocumentData entry) {
    return _db.update(_db.documents).replace(entry);
  }

  Future<int> deleteDocument(int id) {
    return (_db.delete(_db.documents)..where((tbl) => tbl.id.equals(id))).go();
  }
}
