import '../models/source_info.dart';
import 'database_helper.dart';

/// Parsed entry from the Lexicon table.
class DicEntry {
  final String scode;      // e.g. 'H7225', 'G1'
  final String original;   // original Hebrew/Greek word (before '^')
  final String definition; // HTML-formatted definition text (after '^')

  const DicEntry({
    required this.scode,
    required this.original,
    required this.definition,
  });
}

class DicRepository {
  DicRepository._();
  static final instance = DicRepository._();

  Future<DicEntry?> getDefinition(SourceInfo dic, String scode) async {
    final db = await DatabaseHelper.instance.openAsset(dic.assetPath);
    if (db == null) return null;
    final rows = await db.query(
      'Lexicon',
      columns: ['scode', 'dtext'],
      where: 'scode = ?',
      whereArgs: [scode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final dtext = rows.first['dtext'] as String? ?? '';
    final sep = dtext.indexOf('^');
    final original   = sep > 0 ? dtext.substring(0, sep) : '';
    final definition = sep > 0 ? dtext.substring(sep + 1) : dtext;
    return DicEntry(scode: scode, original: original, definition: definition);
  }
}
