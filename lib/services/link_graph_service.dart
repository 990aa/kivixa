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
