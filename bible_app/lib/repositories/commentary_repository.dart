import '../models/source_info.dart';
import 'database_helper.dart';

class CommentaryEntry {
  final int book;
  final int chapter;
  final int verse;
  final String html;

  const CommentaryEntry({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.html,
  });
}

class CommentaryRepository {
  CommentaryRepository._();
  static final CommentaryRepository instance = CommentaryRepository._();

  Future<List<CommentaryEntry>> getChapter(
      SourceInfo source, int book, int chapter) async {
    final db = source.isBuiltIn
        ? await DatabaseHelper.instance.openAsset(source.assetPath)
        : await DatabaseHelper.instance.openExternal(source.docPath);

    final rows = await db.query(
      'Bible',
      where: 'book = ? AND chapter = ?',
      whereArgs: [book, chapter],
      orderBy: 'verse',
    );
    return rows
        .map((r) => CommentaryEntry(
              book: r['book'] as int,
              chapter: r['chapter'] as int,
              verse: r['verse'] as int,
              html: r['btext'] as String? ?? '',
            ))
        .toList();
  }

  Future<CommentaryEntry?> getVerse(
      SourceInfo source, int book, int chapter, int verse) async {
    final db = source.isBuiltIn
        ? await DatabaseHelper.instance.openAsset(source.assetPath)
        : await DatabaseHelper.instance.openExternal(source.docPath);

    final rows = await db.query(
      'Bible',
      where: 'book = ? AND chapter = ? AND verse = ?',
      whereArgs: [book, chapter, verse],
    );
    if (rows.isEmpty) return null;
    return CommentaryEntry(
      book: book,
      chapter: chapter,
      verse: verse,
      html: rows.first['btext'] as String? ?? '',
    );
  }
}
