import 'dart:convert';

enum SourceType { bible, commentary, hymn, dictionary }

class SourceInfo {
  final String id;         // e.g. '개역개정'
  final String name;       // display name
  final SourceType type;
  final String assetPath;  // asset path if bundled, empty if user-imported
  String docPath;          // absolute path in documents directory after copy
  bool isEnabled;
  final bool isBuiltIn;    // bundled with app

  SourceInfo({
    required this.id,
    required this.name,
    required this.type,
    this.assetPath = '',
    this.docPath = '',
    this.isEnabled = true,
    this.isBuiltIn = false,
  });

  String get effectivePath => docPath.isNotEmpty ? docPath : assetPath;

  /// True for English-language bibles (affects how book names are shown).
  bool get isEnglish => kEnglishBibleIds.contains(id);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'assetPath': assetPath,
        'docPath': docPath,
        'isEnabled': isEnabled,
        'isBuiltIn': isBuiltIn,
      };

  factory SourceInfo.fromJson(Map<String, dynamic> j) => SourceInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        type: SourceType.values[j['type'] as int],
        assetPath: j['assetPath'] as String? ?? '',
        docPath: j['docPath'] as String? ?? '',
        isEnabled: j['isEnabled'] as bool? ?? true,
        isBuiltIn: j['isBuiltIn'] as bool? ?? false,
      );

  static String encodeList(List<SourceInfo> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<SourceInfo> decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => SourceInfo.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// IDs of English-language bibles. Used to decide whether to show the
/// English book name alongside the Korean one.
const Set<String> kEnglishBibleIds = {'KJV1769', 'NIV', 'NET', 'WEB'};

// ── Built-in sources that ship with the app ────────────────────────────────

final List<SourceInfo> kBuiltInBibles = [
  // Default enabled (4)
  SourceInfo(id: '개역개정',    name: '개역개정',    type: SourceType.bible, assetPath: 'assets/bible/개역개정.bdb',    isBuiltIn: true, isEnabled: true),
  SourceInfo(id: '개역한글',    name: '개역한글',    type: SourceType.bible, assetPath: 'assets/bible/개역한글.bdb',    isBuiltIn: true, isEnabled: true),
  SourceInfo(id: '새번역',      name: '새번역',      type: SourceType.bible, assetPath: 'assets/bible/새번역.bdb',      isBuiltIn: true, isEnabled: true),
  SourceInfo(id: 'NIV',        name: 'NIV',        type: SourceType.bible, assetPath: 'assets/bible/NIV.bdb',        isBuiltIn: true, isEnabled: true),
  // Additional (disabled by default)
  SourceInfo(id: '바른성경',    name: '바른성경',    type: SourceType.bible, assetPath: 'assets/bible/바른성경.bdb',    isBuiltIn: true, isEnabled: false),
  SourceInfo(id: '쉬운말성경',  name: '쉬운말성경',  type: SourceType.bible, assetPath: 'assets/bible/쉬운말성경.bdb',  isBuiltIn: true, isEnabled: false),
  SourceInfo(id: '쉬운성경',    name: '쉬운성경',    type: SourceType.bible, assetPath: 'assets/bible/쉬운성경.bdb',    isBuiltIn: true, isEnabled: false),
  SourceInfo(id: '우리말성경',  name: '우리말성경',  type: SourceType.bible, assetPath: 'assets/bible/우리말성경.bdb',  isBuiltIn: true, isEnabled: false),
  SourceInfo(id: '킹흠정역',    name: '킹흠정역',    type: SourceType.bible, assetPath: 'assets/bible/킹흠정역.bdb',    isBuiltIn: true, isEnabled: false),
  SourceInfo(id: '현대어성경',  name: '현대어성경',  type: SourceType.bible, assetPath: 'assets/bible/현대어성경.bdb',  isBuiltIn: true, isEnabled: false),
  SourceInfo(id: '현대인의성경',name: '현대인의성경', type: SourceType.bible, assetPath: 'assets/bible/현대인의성경.bdb',isBuiltIn: true, isEnabled: false),
  SourceInfo(id: 'KJV1769',    name: 'KJV1769',    type: SourceType.bible, assetPath: 'assets/bible/KJV1769.bdb',    isBuiltIn: true, isEnabled: false),
  SourceInfo(id: 'NET',        name: 'NET',        type: SourceType.bible, assetPath: 'assets/bible/NET.bdb',        isBuiltIn: true, isEnabled: false),
  SourceInfo(id: 'WEB',        name: 'WEB',        type: SourceType.bible, assetPath: 'assets/bible/WEB.bdb',        isBuiltIn: true, isEnabled: false),
];

final List<SourceInfo> kBuiltInCommentaries = [
  SourceInfo(id: '만나주석', name: '만나주석', type: SourceType.commentary, assetPath: 'assets/commentary/만나주석.cdb', isBuiltIn: true),
];

final List<SourceInfo> kBuiltInHymns = [
  SourceInfo(id: '새찬송가', name: '새찬송가', type: SourceType.hymn, assetPath: 'assets/hymn/새찬송가.hdb', isBuiltIn: true, docPath: ''),
];

/// Strong's-annotated bibles (SDB) — used for word-level original-language lookup.
final List<SourceInfo> kBuiltInSdbBibles = [
  SourceInfo(id: '개역한글S', name: '개역한글(원어)', type: SourceType.bible, assetPath: 'assets/bible/개역한글S.sdb', isBuiltIn: true, isEnabled: false),
  SourceInfo(id: 'KJV_S',    name: 'KJV(원어)',    type: SourceType.bible, assetPath: 'assets/bible/KJV_S.sdb',    isBuiltIn: true, isEnabled: false),
];

/// Original-language dictionaries (Lexicon databases).
final List<SourceInfo> kBuiltInDictionaries = [
  SourceInfo(id: 'HebGrkKo', name: '원어사전(한)', type: SourceType.dictionary, assetPath: 'assets/dic/HebGrkKo.dct', isBuiltIn: true),
  SourceInfo(id: 'HebGrkEn', name: '원어사전(영)', type: SourceType.dictionary, assetPath: 'assets/dic/HebGrkEn.dct', isBuiltIn: true),
];
