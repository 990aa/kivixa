import 'package:kivixa/data/database.dart';
import 'package:drift/drift.dart';

class SafeUndoRedoService {
  final AppDatabase _db;

  SafeUndoRedoService(this._db);

  Future<void> undo() async {
    final lastAction = await (_db.select(_db.redoLog)..orderBy([(t) => t.ts.desc()])).getSingleOrNull();
    if (lastAction == null) {
      return;
    }

    await _db.transaction(() async {
      // This is a placeholder for the undo logic.
      // A real implementation would have a switch statement or a map of handlers
      // to reverse different actions.
      print('Undoing action ${lastAction.action} for ${lastAction.entityType} ${lastAction.entityId}');

      await (_db.delete(_db.redoLog)..where((tbl) => tbl.id.equals(lastAction.id))).go();
    });
  }

  Future<void> redo() async {
    // Redo requires a separate log of undone actions, which is not implemented here.
    // This is a placeholder.
    print('Redo is not implemented.');
  }

  Future<void> logAction({
    required String entityType,
    required int entityId,
    required String action,
    String? data,
  }) async {
    final companion = RedoLogCompanion.insert(
      entityType: entityType,
      entityId: entityId,
      action: action,
      data: Value(data),
      ts: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.into(_db.redoLog).insert(companion);
  }
}
