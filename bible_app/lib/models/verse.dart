/// A single word from an SDB (Strong's Bible Database) verse.
/// [word] is the display word; [codes] are Strong's codes (e.g. 'H7225', 'G1').
class StrongWord {
  final String word;
  final List<String> codes;
  const StrongWord(this.word, this.codes);
  bool get hasCode => codes.isNotEmpty;
}

class Verse {
  final int id;
  final int book;
  final int chapter;
  final int verse;
  final String text;
  final String translationId;
  // Non-empty only for SDB-format bibles.
  final List<StrongWord> strongWords;

  Verse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.translationId,
    this.strongWords = const [],
  });

  bool get hasSdbAnnotations => strongWords.isNotEmpty;

  // ── Strong-code parsing ───────────────────────────────────────────────────
  static final _strongTagAll = RegExp(r'<W[HG]\d+>');
  static final _wordStrongRe = RegExp(r'([^\s<]+)((?:<W[HG]\d+>)*)(\s*)');
  static final _codeExtract  = RegExp(r'<W([HG]\d+)>');

  static List<StrongWord> _parseStrong(String raw) {
    if (!raw.contains('<W')) return const [];
    final result = <StrongWord>[];
    for (final m in _wordStrongRe.allMatches(raw)) {
      final word = m.group(1)!;
      final tags = m.group(2) ?? '';
      final codes = _codeExtract.allMatches(tags).map((c) => c.group(1)!).toList();
      result.add(StrongWord(word, codes));
    }
    return result;
  }

  // ── Text cleaning ─────────────────────────────────────────────────────────
  static String _clean(String raw) {
    final noStrong = raw.replaceAll(_strongTagAll, '');
    final noHtml   = noStrong.replaceAll(RegExp(r'<[^>]+>'), '');
    return _decodeEntities(noHtml.trim());
  }

  static String _decodeEntities(String s) => s
      .replaceAll('&amp;',  '&')
      .replaceAll('&lt;',   '<')
      .replaceAll('&gt;',   '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;',  "'");

  factory Verse.fromMap(Map<String, dynamic> map, String translationId) {
    final raw = map['btext'] as String? ?? '';
    return Verse(
      id:            map['id']      as int? ?? 0,
      book:          map['book']    as int? ?? 0,
      chapter:       map['chapter'] as int? ?? 0,
      verse:         map['verse']   as int? ?? 0,
      text:          _clean(raw),
      translationId: translationId,
      strongWords:   _parseStrong(raw),
    );
  }
}
