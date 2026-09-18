/// Lightweight in-app localization (Korean / English).
enum AppLang { ko, en }

class L10n {
  final AppLang lang;
  const L10n(this.lang);

  bool get isEn => lang == AppLang.en;

  static const L10n ko = L10n(AppLang.ko);
  static const L10n en = L10n(AppLang.en);

  String pick(String korean, String english) => isEn ? english : korean;

  // ── Bottom navigation ────────────────────────────────────────────────
  String get bible      => pick('성경', 'Bible');
  String get hymns      => pick('찬송가', 'Hymns');
  String get commentary => pick('주석', 'Commentary');
  String get settings   => pick('설정', 'Settings');

  // ── Bible screen ─────────────────────────────────────────────────────
  String get prevChapter => pick('이전 장', 'Previous chapter');
  String get nextChapter => pick('다음 장', 'Next chapter');
  String get translationSettings => pick('역본 선택', 'Select translation');
  String get compareSettings     => pick('역본 대조', 'Compare translations');
  String get translationCompareSettings =>
      pick('번역/비교 설정', 'Translation / compare');
  String get searchBible => pick('성경 검색', 'Search Bible');
  String get noData      => pick('데이터가 없습니다', 'No data');
  String chapter(int n)  => pick('$n장', 'Ch. $n');
  String verse(int n)    => pick('$n절', 'v.$n');
  String error(String m) => pick('오류: $m', 'Error: $m');

  // ── Translation selector ─────────────────────────────────────────────
  String get selectTranslation => pick('역본 선택', 'Select translation');
  String get selectCompare     => pick('역본 대조 설정', 'Compare settings');
  String get compare           => pick('비교', 'Compare');
  String get layout            => pick('레이아웃', 'Layout');
  String get sideBySide        => pick('좌우', 'Side by side');
  String get topBottom         => pick('상하', 'Top / bottom');
  String get compareHint => pick(
        '비교할 역본을 선택하세요 (최대 4개).',
        'Select translations to compare (up to 4).',
      );
  String get singleSelectHint =>
      pick('읽을 역본 한 개를 선택하세요.',
          'Select one translation to read.');

  // ── Book selector ────────────────────────────────────────────────────
  String get oldTestament => pick('구약', 'Old Testament');
  String get newTestament => pick('신약', 'New Testament');
  String get selectVerse  => pick('절 선택', 'Select verse');
  String get goToChapter  => pick('장 처음으로', 'Go to chapter start');

  // ── Commentary screen ────────────────────────────────────────────────
  String commentaryTitle(String chapterLabel) =>
      pick('$chapterLabel 주석', '$chapterLabel Commentary');
  String get goToBibleLocation =>
      pick('현재 성경 위치로', 'Go to current Bible location');
  String get noCommentaryEnabled =>
      pick('활성화된 주석이 없습니다.\n설정에서 주석을 추가하세요.',
          'No commentary enabled.\nAdd one in Settings.');
  String get noCommentary => pick('주석 없음', 'No commentary');

  // ── Hymn ─────────────────────────────────────────────────────────────
  String get searchHymnHint =>
      pick('찬송가 번호 또는 제목 검색...', 'Search hymn number or title...');
  String get noEnabledHymn => pick('활성화된 찬송가 없음', 'No hymn enabled');
  String get noResult      => pick('결과 없음', 'No result');
  String get sheetMusic    => pick('악보', 'Sheet music');
  String get lyrics        => pick('가사', 'Lyrics');
  String get cannotLoadImage =>
      pick('악보 이미지를 불러올 수 없습니다', 'Cannot load sheet-music image');

  // ── Notes ────────────────────────────────────────────────────────────
  String get addNote      => pick('노트 추가', 'Add note');
  String get editNote     => pick('노트 편집', 'Edit note');
  String get deleteNote   => pick('노트 삭제', 'Delete note');
  String get noteHint     => pick('여기에 노트를 입력하세요...', 'Enter note here...');
  String get noteSaved    => pick('노트 저장됨', 'Note saved');
  String get noteDeleted  => pick('노트 삭제됨', 'Note deleted');
  String noteVerse(int from, int to) => from == to
      ? pick('$from절', 'v.$from')
      : pick('$from-$to절', 'v.$from-$to');
  String get cancelSelection => pick('선택 취소', 'Cancel selection');
  String get verseSelected   => pick('절 선택됨', 'verse(s) selected');
  String get exportNotes     => pick('노트 내보내기 (CSV)', 'Export notes (CSV)');
  String get importNotes     => pick('노트 가져오기 (CSV)', 'Import notes (CSV)');
  String get exportSuccess   => pick('내보내기 완료', 'Export complete');
  String importSuccess(int n) => pick('$n개 노트 가져옴', '$n notes imported');
  String get importFailed    => pick('가져오기 실패', 'Import failed');
  String get noteSection     => pick('노트', 'Notes');

  // ── Settings screen ──────────────────────────────────────────────────
  String get view           => pick('보기', 'View');
  String get fontSize        => pick('글자 크기', 'Font size');
  String get theme           => pick('테마', 'Theme');
  String get themeSystem     => pick('시스템 설정', 'System');
  String get themeLight      => pick('밝은 테마', 'Light');
  String get themeDark       => pick('어두운 테마', 'Dark');
  String get languageSection => pick('언어', 'Language');
  String get korean          => pick('한국어', 'Korean');
  String get english         => pick('영어', 'English');
  String get bibleTranslations => pick('성경 번역', 'Bible translations');
  String get addBibleFile    => pick('성경 파일 추가 (.bdb)', 'Add Bible file (.bdb)');
  String get commentarySection => pick('주석', 'Commentary');
  String get addCommentaryFile => pick('주석 파일 추가 (.cdb)', 'Add commentary file (.cdb)');
  String get hymnSection     => pick('찬송가', 'Hymns');
  String get addHymnFile     => pick('찬송가 파일 추가 (.hdb)', 'Add hymn file (.hdb)');
  String get builtIn         => pick('기본 제공', 'Built-in');
  String get delete          => pick('삭제', 'Delete');
  String get cancel          => pick('취소', 'Cancel');
  String removeConfirm(String name) =>
      pick('$name을(를) 삭제하시겠습니까?', 'Remove $name?');
  String addedMsg(String name) => pick('$name 추가됨', '$name added');
  String onlySupported(String exts) =>
      pick('$exts 파일만 지원됩니다', 'Only $exts files are supported');
  String get cmpAlsoAdded =>
      pick('악보(.cmp)도 함께 추가됨', 'Sheet music (.cmp) also added');

  // ── Search screen ────────────────────────────────────────────────────
  String get searchWordHint => pick('단어 또는 구절 검색...', 'Search word or phrase...');
  String get translationLabel => pick('번역', 'Translation');
  String resultsCount(int n) => pick('$n건 검색됨', '$n results');
  String get enterSearch => pick('검색어를 입력하세요', 'Enter a search term');
  String onlyBook(String book) => pick('$book만', '$book only');
}
