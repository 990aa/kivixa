import 'package:kivixa/data/database.dart';
import 'package:drift/drift.dart';

class Link {
  final int fromPageId;
  final int toPageId;

  Link({required this.fromPageId, required this.toPageId});
}

class LinkGraphService {
  final AppDatabase _db;

  LinkGraphService(this._db);

  Future<void> addLink(Link link) async {
    // In a real app, you would use the actual table classes from database.g.dart
    // For now, we use a placeholder. This will be updated once the schema is updated.
    final companion = LinksCompanion.insert(
      fromPageId: link.fromPageId,
      toPageId: link.toPageId,
      type: 'manual', // default type
    );
    await _db.into(_db.links).insert(companion);
  }

  Future<void> removeLink(Link link) async {
    await (_db.delete(_db.links)
          ..where((tbl) => tbl.fromPageId.equals(link.fromPageId) & tbl.toPageId.equals(link.toPageId)))
        .go();
  }

  Future<List<int>> getBacklinks(int pageId) async {
    final query = _db.select(_db.links)..where((tbl) => tbl.toPageId.equals(pageId));
    final links = await query.get();
    return links.map((link) => link.fromPageId).toList();
  }

  Future<List<int>> getForwardLinks(int pageId) async {
    final query = _db.select(_db.links)..where((tbl) => tbl.fromPageId.equals(pageId));
    final links = await query.get();
    return links.map((link) => link.toPageId).toList();
  }
}

// Placeholder for the generated Links table class
class Links extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromPageId => integer()();
  IntColumn get toPageId => integer()();
  TextColumn get type => text()();
}

// Placeholder for the generated LinksCompanion
class LinksCompanion extends UpdateCompanion<dynamic> {
  final Value<int> fromPageId;
  final Value<int> toPageId;
  final Value<String> type;

  const LinksCompanion({
    required this.fromPageId,
    required this.toPageId,
    required this.type,
  });

  factory LinksCompanion.insert({
    required int fromPageId,
    required int toPageId,
    required String type,
  }) {
    return LinksCompanion(
      fromPageId: Value(fromPageId),
      toPageId: Value(toPageId),
      type: Value(type),
    );
  }
}
