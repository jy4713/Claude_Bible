import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/source_info.dart';
import '../models/verse.dart';
import '../repositories/bible_repository.dart';

class BibleProvider with ChangeNotifier {
  static const _kBook        = 'currentBook';
  static const _kChapter     = 'currentChapter';
  static const _kVerse       = 'currentVerse';
  static const _kSingleId    = 'singleId';
  static const _kCompareIds  = 'compareIds';
  static const _kCompareMode = 'compareMode';

  /// Maximum number of translations that can be compared at once.
  static const int maxCompare = 4;

  int _book          = 1;
  int _chapter       = 1;
  int _verse         = 1;
  int _verseIndex    = 0;
  // Separate navigation target (Kimi: scrollIndex) — only set by navigate().
  // setScrollPosition() updates _verse/_verseIndex but NOT _navVerseIndex,
  // so scroll-tracking never accidentally triggers a re-scroll.
  int _navVerseIndex = 0;

  // Single-view translation (Bible tab)
  String _singleId = '개역개정';

  // Compare-view translations (역본대조 tab) — persisted separately
  List<String> _compareIds = ['개역개정'];

  bool _compareMode = false;
  Axis _compareAxis = Axis.vertical;

  final Map<String, List<Verse>> _verses = {};
  bool _loading = false;
  String? _error;

  int get book           => _book;
  int get chapter        => _chapter;
  int get verse          => _verse;
  int get verseIndex     => _verseIndex;
  /// Navigation target verse index — only updated by navigate(), not by scroll tracking.
  int get navVerseIndex  => _navVerseIndex;

  /// The primary (single-view) translation ID.
  String get primaryId => _singleId;

  /// The compare-mode translation IDs (used by TranslationSelector in compare mode).
  List<String> get selectedIds => _compareIds;

  bool get compareMode => _compareMode;
  Axis get compareAxis => _compareAxis;
  bool get loading => _loading;
  String? get error => _error;

  List<Verse> versesFor(String id) => _verses[id] ?? [];

  /// In compare mode, always include singleId so Bible tab always has data.
  List<String> get visibleIds {
    if (_compareMode) {
      return {..._compareIds, _singleId}.toList();
    }
    return [_singleId];
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _book       = prefs.getInt(_kBook)    ?? 1;
    _chapter    = prefs.getInt(_kChapter) ?? 1;
    _verse         = prefs.getInt(_kVerse)   ?? 1;
    _verseIndex    = _verse - 1;
    _navVerseIndex = _verseIndex;
    _compareMode = prefs.getBool(_kCompareMode) ?? false;
    _singleId    = prefs.getString(_kSingleId) ?? '개역개정';
    final saved  = prefs.getStringList(_kCompareIds);
    if (saved != null && saved.isNotEmpty) _compareIds = saved;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSingleId, _singleId);
    await prefs.setStringList(_kCompareIds, _compareIds);
    await prefs.setBool(_kCompareMode, _compareMode);
  }

  Future<void> navigate(
    List<SourceInfo> sources,
    int book,
    int chapter, {
    int verseIndex = 0,
  }) async {
    _book          = book;
    _chapter       = chapter;
    _verseIndex    = verseIndex;
    _verse         = verseIndex + 1;
    _navVerseIndex = verseIndex;   // mark explicit navigation target
    await _loadVerses(sources);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBook,    book);
    await prefs.setInt(_kChapter, chapter);
    await prefs.setInt(_kVerse,   _verse);
  }

  Future<void> reload(List<SourceInfo> sources) => _loadVerses(sources);

  Future<void> _loadVerses(List<SourceInfo> sources) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _verses.clear();
      for (final id in visibleIds) {
        SourceInfo? src;
        for (final s in sources) {
          if (s.id == id) { src = s; break; }
        }
        if (src == null) continue;
        final list =
            await BibleRepository.instance.getChapter(src, _book, _chapter);
        _verses[id] = list;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Updates verse display from scroll position — no data reload, no scroll-back.
  void setScrollPosition(int verseNumber) {
    if (_verse == verseNumber) return;
    _verse = verseNumber;
    _verseIndex = verseNumber - 1;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_kVerse, _verse);
    });
    notifyListeners();
  }

  /// Changes the single-view translation (Bible tab).
  /// Does NOT affect compareIds.
  void setSingleId(String id, List<SourceInfo> sources) {
    _singleId = id;
    _persist();
    _loadVerses(sources); // Always load — visibleIds now includes singleId
  }

  /// Changes the compare-view translations (역본대조 tab).
  /// Does NOT affect singleId.
  void setSelectedIds(List<String> ids, List<SourceInfo> sources) {
    var next = ids.where((id) => id.isNotEmpty).toList();
    if (next.isEmpty) {
      next = [sources.isNotEmpty ? sources.first.id : '개역개정'];
    }
    if (next.length > maxCompare) next = next.sublist(0, maxCompare);
    _compareIds = next;
    _persist();
    if (_compareMode) {
      _loadVerses(sources);
    } else {
      notifyListeners();
    }
  }

  /// Toggles compare mode. Does NOT clear compareIds.
  void toggleCompare(List<SourceInfo> sources) {
    _compareMode = !_compareMode;
    _persist();
    _loadVerses(sources);
  }

  void setCompareAxis(Axis axis) {
    _compareAxis = axis;
    notifyListeners();
  }

  Future<int> chapterCount(SourceInfo source) async => 0;
}
