/// Lightweight in-app localization (Korean / English).
///
/// Only the app "chrome" (menus, buttons, section titles) is translated.
/// Source names (bibles / hymns / commentaries) keep their file names as-is.
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
  String get translationCompareSettings =>
      pick('번역/비교 설정', 'Translation / compare');
  String get searchBible => pick('성경 검색', 'Search Bible');
  String get noData      => pick('데이터가 없습니다', 'No data');
  String chapter(int n)  => pick('$n장', 'Ch. $n');
  String error(String m) => pick('오류: $m', 'Error: $m');

  // ── Translation selector ─────────────────────────────────────────────
  String get selectTranslation => pick('번역 선택', 'Select translation');
  String get compare           => pick('비교', 'Compare');
  String get layout            => pick('레이아웃', 'Layout');
  String get sideBySide        => pick('좌우', 'Side by side');
  String get topBottom         => pick('상하', 'Top / bottom');
  String get compareHint => pick(
        '비교는 최대 4개까지 선택할 수 있으며, 선택한 순서대로 표시됩니다.',
        'Up to 4 can be compared, shown in the order selected.',
      );
  String get singleSelectHint =>
      pick('비교가 꺼져 있어 한 개만 선택됩니다.',
          'Compare is off — only one can be selected.');

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

  // ── Book selector ────────────────────────────────────────────────────
  String get oldTestament => pick('구약', 'Old Testament');
  String get newTestament => pick('신약', 'New Testament');

  // ── Search screen ────────────────────────────────────────────────────
  String get searchWordHint => pick('단어 또는 구절 검색...', 'Search word or phrase...');
  String get translationLabel => pick('번역', 'Translation');
  String resultsCount(int n) => pick('$n건 검색됨', '$n results');
  String get enterSearch => pick('검색어를 입력하세요', 'Enter a search term');
  String onlyBook(String book) => pick('$book만', '$book only');
}
