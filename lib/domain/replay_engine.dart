import 'dart:async';
import 'dart:typed_data'; // Added this line

import 'package:sqflite/sqflite.dart';

import '../services/stroke_store.dart';

class ReplayEngine {
  final Database db;

  ReplayEngine(this.db);

  Stream<Stroke> getStrokes({
    required int layerId,
    int? startTime,
    int? endTime,
  }) async* {
    String? where = 'layer_id = ?';
    List<dynamic> whereArgs = [layerId];

    if (startTime != null) {
      where += ' AND ts >= ?';
      whereArgs.add(startTime);
    }

    if (endTime != null) {
      where += ' AND ts <= ?';
      whereArgs.add(endTime);
    }

    final cursor = await db.queryCursor(
      'strokes',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'ts, chunk_index',
    );

    while (await cursor.moveNext()) {
      final row = cursor.current;
      yield Stroke(
        layerId: row['layer_id'] as int,
        strokeId: row['stroke_id'] as String,
        chunkIndex: row['chunk_index'] as int,
        data: row['data'] as Uint8List,
        timestamp: row['ts'] as int,
      );
    }
  }

  Stream<Stroke> getStrokesForPage(int pageId) async* {
    final layers = await db.query('layers', where: 'page_id = ?', whereArgs: [pageId]);
    for (final layer in layers) {
      yield* getStrokes(layerId: layer['id'] as int);
    }
  }
}