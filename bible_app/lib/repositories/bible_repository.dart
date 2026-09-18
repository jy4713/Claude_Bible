import '../models/source_info.dart';
import '../models/verse.dart';
import 'database_helper.dart';

class BibleRepository {
  BibleRepository._();
  static final BibleRepository instance = BibleRepository._();

  Future<List<Verse>> getChapter(SourceInfo source, int book, int chapter) async {
    final db = source.isBuiltIn
        ? await DatabaseHelper.instance.openAsset(source.assetPath)
        : await DatabaseHelper.instance.openExternal(source.docPath);

    final rows = await db.query(
      'Bible',
      where: 'book = ? AND chapter = ?',
      whereArgs: [book, chapter],
      orderBy: 'verse',
    );
    return rows.map((r) => Verse.fromMap(r, source.id)).toList();
  }

  Future<List<Verse>> search(SourceInfo source, String query, {int? book}) async {
    if (query.trim().isEmpty) return [];
    final db = source.isBuiltIn
        ? await DatabaseHelper.instance.openAsset(source.assetPath)
        : await DatabaseHelper.instance.openExternal(source.docPath);

    final where = book != null
        ? 'book = ? AND btext LIKE ?'
        : 'btext LIKE ?';
    final args = book != null ? [book, '%$query%'] : ['%$query%'];

    final rows = await db.query(
      'Bible',
      where: where,
      whereArgs: args,
      orderBy: 'book, chapter, verse',
      limit: 200,
    );
    return rows.map((r) => Verse.fromMap(r, source.id)).toList();
  }

  Future<Verse?> getVerse(SourceInfo source, int book, int chapter, int verse) async {
    final db = source.isBuiltIn
        ? await DatabaseHelper.instance.openAsset(source.assetPath)
        : await DatabaseHelper.instance.openExternal(source.docPath);

    final rows = await db.query(
      'Bible',
      where: 'book = ? AND chapter = ? AND verse = ?',
      whereArgs: [book, chapter, verse],
    );
    if (rows.isEmpty) return null;
    return Verse.fromMap(rows.first, source.id);
  }

  Future<int> maxVerse(SourceInfo source, int book, int chapter) async {
    final db = source.isBuiltIn
        ? await DatabaseHelper.instance.openAsset(source.assetPath)
        : await DatabaseHelper.instance.openExternal(source.docPath);

    final result = await db.rawQuery(
      'SELECT MAX(verse) as mv FROM Bible WHERE book=? AND chapter=?',
      [book, chapter],
    );
    return (result.first['mv'] as int?) ?? 1;
  }
}
