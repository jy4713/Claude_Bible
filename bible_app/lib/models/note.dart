class Note {
  final int? id;
  final int book;
  final int chapter;
  final int verseFrom;
  final int verseTo;
  final String text;
  final String createdAt;

  Note({
    this.id,
    required this.book,
    required this.chapter,
    required this.verseFrom,
    required this.verseTo,
    required this.text,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
    'id': id,
    'book': book,
    'chapter': chapter,
    'verse_from': verseFrom,
    'verse_to': verseTo,
    'text': text,
    'created_at': createdAt,
  };

  factory Note.fromMap(Map<String, dynamic> m) => Note(
    id: m['id'] as int?,
    book: m['book'] as int,
    chapter: m['chapter'] as int,
    verseFrom: m['verse_from'] as int,
    verseTo: m['verse_to'] as int,
    text: m['text'] as String,
    createdAt: m['created_at'] as String? ?? DateTime.now().toIso8601String(),
  );

  Note copyWith({String? text}) => Note(
    id: id,
    book: book,
    chapter: chapter,
    verseFrom: verseFrom,
    verseTo: verseTo,
    text: text ?? this.text,
    createdAt: createdAt,
  );
}
