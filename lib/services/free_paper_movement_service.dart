import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }

  static Point fromMap(Map<String, dynamic> map) {
    return Point(map['x'], map['y']);
  }
}

class FreePaperMovementService {
  final Database db;
  final String userId;

  FreePaperMovementService(this.db, this.userId);

  Future<Point> getAdjustedOrigin(int pageId, String deviceProfile) async {
    final String key = 'edge_comfort_${pageId}_$deviceProfile';
    final List<Map<String, dynamic>> results = await db.query(
      'user_settings',
      where: 'user_id = ? AND key = ?',
      whereArgs: [userId, key],
    );

    if (results.isNotEmpty) {
      final value = results.first['value'] as String;
      return Point.fromMap(jsonDecode(value));
    }

    return Point(0, 0);
  }

  Future<void> saveOffsets(int pageId, String deviceProfile, Point offsets) async {
    final String key = 'edge_comfort_${pageId}_$deviceProfile';
    final String value = jsonEncode(offsets.toMap());

    await db.insert(
      'user_settings',
      {
        'user_id': userId,
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}