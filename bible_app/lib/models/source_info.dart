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
  SourceInfo(id: '개역개정', name: '개역개정',  type: SourceType.bible, assetPath: 'assets/bible/개역개정.bdb', isBuiltIn: true),
  SourceInfo(id: '개역한글', name: '개역한글',  type: SourceType.bible, assetPath: 'assets/bible/개역한글.bdb', isBuiltIn: true),
  SourceInfo(id: '새번역',   name: '새번역',    type: SourceType.bible, assetPath: 'assets/bible/새번역.bdb',   isBuiltIn: true),
  SourceInfo(id: 'NIV',     name: 'NIV',      type: SourceType.bible, assetPath: 'assets/bible/NIV.bdb',     isBuiltIn: true),
];

final List<SourceInfo> kBuiltInCommentaries = [
  SourceInfo(id: '만나주석', name: '만나주석', type: SourceType.commentary, assetPath: 'assets/commentary/만나주석.cdb', isBuiltIn: true),
];

final List<SourceInfo> kBuiltInHymns = [
  SourceInfo(id: '새찬송가', name: '새찬송가', type: SourceType.hymn, assetPath: 'assets/hymn/새찬송가.hdb', isBuiltIn: true, docPath: ''),
];
