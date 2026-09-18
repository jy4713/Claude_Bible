import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/source_info.dart';
import '../models/verse.dart';
import '../repositories/bible_repository.dart';

class BibleProvider with ChangeNotifier {
  static const _kBook    = 'currentBook';
  static const _kChapter = 'currentChapter';
  static const _kSelected = 'selectedIds';
  static const _kCompare  = 'compareMode';

  /// Maximum number of translations that can be compared at once.
  static const int maxCompare = 4;

  int _book    = 1;
  int _chapter = 1;
  int _verseIndex = 0; // for scroll-to

  // Selected translation IDs for primary + compare (priority order 1..4)
  List<String> _selectedIds = ['개역개정'];

  bool _compareMode = false;
  Axis _compareAxis = Axis.horizontal; // horizontal = side-by-side

  // verses[translationId] = list of Verse
  final Map<String, List<Verse>> _verses = {};
  bool _loading = false;
  String? _error;

  int get book    => _book;
  int get chapter => _chapter;
  int get verseIndex => _verseIndex;

  List<String> get selectedIds => _selectedIds;
  bool get compareMode => _compareMode;
  Axis get compareAxis => _compareAxis;
  bool get loading => _loading;
  String? get error => _error;

  List<Verse> versesFor(String id) => _verses[id] ?? [];

  /// The single active translation id when compare is off (priority #1).
  String get primaryId => _selectedIds.isNotEmpty ? _selectedIds.first : '개역개정';

  /// Ids that are actually shown in the current view.
  List<String> get visibleIds =>
      _compareMode ? _selectedIds : [primaryId];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _book    = prefs.getInt(_kBook)    ?? 1;
    _chapter = prefs.getInt(_kChapter) ?? 1;
    _compareMode = prefs.getBool(_kCompare) ?? false;
    final saved = prefs.getStringList(_kSelected);
    if (saved != null && saved.isNotEmpty) _selectedIds = saved;
    if (!_compareMode && _selectedIds.length > 1) {
      _selectedIds = [_selectedIds.first];
    }
    notifyListeners();
  }

  Future<void> _persistSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kSelected, _selectedIds);
    await prefs.setBool(_kCompare, _compareMode);
  }

  Future<void> navigate(
    List<SourceInfo> sources,
    int book,
    int chapter, {
    int verseIndex = 0,
  }) async {
    _book    = book;
    _chapter = chapter;
    _verseIndex = verseIndex;
    await _loadVerses(sources);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBook, book);
    await prefs.setInt(_kChapter, chapter);
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

  void setSelectedIds(List<String> ids, List<SourceInfo> sources) {
    var next = ids.where((id) => id.isNotEmpty).toList();
    if (next.isEmpty) {
      next = [sources.isNotEmpty ? sources.first.id : '개역개정'];
    }
    if (_compareMode) {
      if (next.length > maxCompare) next = next.sublist(0, maxCompare);
    } else {
      next = [next.first];
    }
    _selectedIds = next;
    _persistSelection();
    _loadVerses(sources);
  }

  void toggleCompare(List<SourceInfo> sources) {
    _compareMode = !_compareMode;
    if (!_compareMode && _selectedIds.length > 1) {
      _selectedIds = [_selectedIds.first];
    }
    _persistSelection();
    _loadVerses(sources); // reloads + notifies for the new view
  }

  void setCompareAxis(Axis axis) {
    _compareAxis = axis;
    notifyListeners();
  }

  Future<int> chapterCount(SourceInfo source) async {
    // Use book info constants for speed (avoids DB query)
    return 0; // caller uses BookInfo.chapters instead
  }
}
