class BookInfo {
  final int number;      // 1-66
  final String korean;   // 창세기
  final String short;    // 창
  final String english;  // Genesis
  final int chapters;

  const BookInfo({
    required this.number,
    required this.korean,
    required this.short,
    required this.english,
    required this.chapters,
  });

  bool get isOT => number <= 39;
}

const List<BookInfo> bibleBooks = [
  // ── 구약 (Old Testament) ──
  BookInfo(number:  1, korean: '창세기',       short: '창',   english: 'Genesis',         chapters: 50),
  BookInfo(number:  2, korean: '출애굽기',      short: '출',   english: 'Exodus',          chapters: 40),
  BookInfo(number:  3, korean: '레위기',        short: '레',   english: 'Leviticus',       chapters: 27),
  BookInfo(number:  4, korean: '민수기',        short: '민',   english: 'Numbers',         chapters: 36),
  BookInfo(number:  5, korean: '신명기',        short: '신',   english: 'Deuteronomy',     chapters: 34),
  BookInfo(number:  6, korean: '여호수아',      short: '수',   english: 'Joshua',          chapters: 24),
  BookInfo(number:  7, korean: '사사기',        short: '삿',   english: 'Judges',          chapters: 21),
  BookInfo(number:  8, korean: '룻기',          short: '룻',   english: 'Ruth',            chapters:  4),
  BookInfo(number:  9, korean: '사무엘상',      short: '삼상', english: '1 Samuel',        chapters: 31),
  BookInfo(number: 10, korean: '사무엘하',      short: '삼하', english: '2 Samuel',        chapters: 24),
  BookInfo(number: 11, korean: '열왕기상',      short: '왕상', english: '1 Kings',         chapters: 22),
  BookInfo(number: 12, korean: '열왕기하',      short: '왕하', english: '2 Kings',         chapters: 25),
  BookInfo(number: 13, korean: '역대상',        short: '대상', english: '1 Chronicles',    chapters: 29),
  BookInfo(number: 14, korean: '역대하',        short: '대하', english: '2 Chronicles',    chapters: 36),
  BookInfo(number: 15, korean: '에스라',        short: '스',   english: 'Ezra',            chapters: 10),
  BookInfo(number: 16, korean: '느헤미야',      short: '느',   english: 'Nehemiah',        chapters: 13),
  BookInfo(number: 17, korean: '에스더',        short: '에',   english: 'Esther',          chapters: 10),
  BookInfo(number: 18, korean: '욥기',          short: '욥',   english: 'Job',             chapters: 42),
  BookInfo(number: 19, korean: '시편',          short: '시',   english: 'Psalms',          chapters: 150),
  BookInfo(number: 20, korean: '잠언',          short: '잠',   english: 'Proverbs',        chapters: 31),
  BookInfo(number: 21, korean: '전도서',        short: '전',   english: 'Ecclesiastes',    chapters: 12),
  BookInfo(number: 22, korean: '아가',          short: '아',   english: 'Song of Solomon', chapters:  8),
  BookInfo(number: 23, korean: '이사야',        short: '사',   english: 'Isaiah',          chapters: 66),
  BookInfo(number: 24, korean: '예레미야',      short: '렘',   english: 'Jeremiah',        chapters: 52),
  BookInfo(number: 25, korean: '예레미야애가',  short: '애',   english: 'Lamentations',    chapters:  5),
  BookInfo(number: 26, korean: '에스겔',        short: '겔',   english: 'Ezekiel',         chapters: 48),
  BookInfo(number: 27, korean: '다니엘',        short: '단',   english: 'Daniel',          chapters: 12),
  BookInfo(number: 28, korean: '호세아',        short: '호',   english: 'Hosea',           chapters: 14),
  BookInfo(number: 29, korean: '요엘',          short: '욜',   english: 'Joel',            chapters:  3),
  BookInfo(number: 30, korean: '아모스',        short: '암',   english: 'Amos',            chapters:  9),
  BookInfo(number: 31, korean: '오바댜',        short: '옵',   english: 'Obadiah',         chapters:  1),
  BookInfo(number: 32, korean: '요나',          short: '욘',   english: 'Jonah',           chapters:  4),
  BookInfo(number: 33, korean: '미가',          short: '미',   english: 'Micah',           chapters:  7),
  BookInfo(number: 34, korean: '나훔',          short: '나',   english: 'Nahum',           chapters:  3),
  BookInfo(number: 35, korean: '하박국',        short: '합',   english: 'Habakkuk',        chapters:  3),
  BookInfo(number: 36, korean: '스바냐',        short: '습',   english: 'Zephaniah',       chapters:  3),
  BookInfo(number: 37, korean: '학개',          short: '학',   english: 'Haggai',          chapters:  2),
  BookInfo(number: 38, korean: '스가랴',        short: '슥',   english: 'Zechariah',       chapters: 14),
  BookInfo(number: 39, korean: '말라기',        short: '말',   english: 'Malachi',         chapters:  4),
  // ── 신약 (New Testament) ──
  BookInfo(number: 40, korean: '마태복음',      short: '마',   english: 'Matthew',         chapters: 28),
  BookInfo(number: 41, korean: '마가복음',      short: '막',   english: 'Mark',            chapters: 16),
  BookInfo(number: 42, korean: '누가복음',      short: '눅',   english: 'Luke',            chapters: 24),
  BookInfo(number: 43, korean: '요한복음',      short: '요',   english: 'John',            chapters: 21),
  BookInfo(number: 44, korean: '사도행전',      short: '행',   english: 'Acts',            chapters: 28),
  BookInfo(number: 45, korean: '로마서',        short: '롬',   english: 'Romans',          chapters: 16),
  BookInfo(number: 46, korean: '고린도전서',    short: '고전', english: '1 Corinthians',   chapters: 16),
  BookInfo(number: 47, korean: '고린도후서',    short: '고후', english: '2 Corinthians',   chapters: 13),
  BookInfo(number: 48, korean: '갈라디아서',    short: '갈',   english: 'Galatians',       chapters:  6),
  BookInfo(number: 49, korean: '에베소서',      short: '엡',   english: 'Ephesians',       chapters:  6),
  BookInfo(number: 50, korean: '빌립보서',      short: '빌',   english: 'Philippians',     chapters:  4),
  BookInfo(number: 51, korean: '골로새서',      short: '골',   english: 'Colossians',      chapters:  4),
  BookInfo(number: 52, korean: '데살로니가전서', short: '살전', english: '1 Thessalonians', chapters:  5),
  BookInfo(number: 53, korean: '데살로니가후서', short: '살후', english: '2 Thessalonians', chapters:  3),
  BookInfo(number: 54, korean: '디모데전서',    short: '딤전', english: '1 Timothy',       chapters:  6),
  BookInfo(number: 55, korean: '디모데후서',    short: '딤후', english: '2 Timothy',       chapters:  4),
  BookInfo(number: 56, korean: '디도서',        short: '딛',   english: 'Titus',           chapters:  3),
  BookInfo(number: 57, korean: '빌레몬서',      short: '몬',   english: 'Philemon',        chapters:  1),
  BookInfo(number: 58, korean: '히브리서',      short: '히',   english: 'Hebrews',         chapters: 13),
  BookInfo(number: 59, korean: '야고보서',      short: '약',   english: 'James',           chapters:  5),
  BookInfo(number: 60, korean: '베드로전서',    short: '벧전', english: '1 Peter',         chapters:  5),
  BookInfo(number: 61, korean: '베드로후서',    short: '벧후', english: '2 Peter',         chapters:  3),
  BookInfo(number: 62, korean: '요한일서',      short: '요일', english: '1 John',          chapters:  5),
  BookInfo(number: 63, korean: '요한이서',      short: '요이', english: '2 John',          chapters:  1),
  BookInfo(number: 64, korean: '요한삼서',      short: '요삼', english: '3 John',          chapters:  1),
  BookInfo(number: 65, korean: '유다서',        short: '유',   english: 'Jude',            chapters:  1),
  BookInfo(number: 66, korean: '요한계시록',    short: '계',   english: 'Revelation',      chapters: 22),
];

BookInfo bookInfoOf(int bookNumber) =>
    bibleBooks.firstWhere((b) => b.number == bookNumber);
