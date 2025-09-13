import 'dart:async';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

class Stroke {
  final int layerId;
  final String strokeId;
  final int chunkIndex;
  final Uint8List data;
  final int timestamp;

  Stroke({
    required this.layerId,
    required this.strokeId,
    required this.chunkIndex,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'layer_id': layerId,
      'stroke_id': strokeId,
      'chunk_index': chunkIndex,
      'data': data,
      'ts': timestamp,
    };
  }
}

class StrokeStore {
  final Database db;

  StrokeStore(this.db);

  Future<void> writeStrokeChunk(Stroke stroke) async {
    await db.insert(
      'strokes',
      stroke.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> writeStrokeChunks(List<Stroke> strokes) async {
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final stroke in strokes) {
        batch.insert(
          'strokes',
          stroke.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }
}