import 'package:sqflite/sqflite.dart';

class ColorPalettesService {
  final Database db;
  ColorPalettesService(this.db);

  Future<void> savePalette(
    String name,
    List<int> colors, {
    bool starred = false,
  }) async {
    await db.insert('color_palettes', {
      'name': name,
      'colors': colors.join(','),
      'starred': starred ? 1 : 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPalettes() async {
    return await db.query('color_palettes');
  }

  Future<void> updatePalette(int id, List<int> colors) async {
    await db.update(
      'color_palettes',
      {'colors': colors.join(',')},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePalette(int id) async {
    await db.delete('color_palettes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> starPalette(int id, bool star) async {
    await db.update(
      'color_palettes',
      {'starred': star ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
