class Verse {
  final int id;
  final int book;
  final int chapter;
  final int verse;
  final String text;
  final String translationId;

  const Verse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.translationId,
  });

  static String _stripHtml(String raw) =>
      raw.replaceAll(RegExp(r'<[^>]+>'), '');

  factory Verse.fromMap(Map<String, dynamic> map, String translationId) => Verse(
        id: map['id'] as int? ?? 0,
        book: map['book'] as int? ?? 0,
        chapter: map['chapter'] as int? ?? 0,
        verse: map['verse'] as int? ?? 0,
        text: _stripHtml(map['btext'] as String? ?? ''),
        translationId: translationId,
      );
}
