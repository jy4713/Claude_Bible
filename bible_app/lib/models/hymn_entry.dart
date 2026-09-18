class HymnEntry {
  final int id;
  final int chapter;    // hymn number (1-645)
  final String title;
  final String text;    // lyrics (HTML with <br>)

  const HymnEntry({
    required this.id,
    required this.chapter,
    required this.title,
    required this.text,
  });

  factory HymnEntry.fromMap(Map<String, dynamic> map) => HymnEntry(
        id: map['id'] as int? ?? 0,
        chapter: map['chapter'] as int? ?? 0,
        title: map['title'] as String? ?? '',
        text: map['htext'] as String? ?? '',
      );
}
