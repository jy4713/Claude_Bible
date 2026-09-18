import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/l10n.dart';
import '../models/source_info.dart';

class SettingsProvider with ChangeNotifier {
  static const _kFontSize    = 'fontSize';
  static const _kUiScale     = 'uiScale';
  static const _kThemeMode   = 'themeMode';
  static const _kLang        = 'appLang';
  static const _kBibles      = 'bibles';
  static const _kCommentaries = 'commentaries';
  static const _kHymns       = 'hymns';

  double _fontSize = 16.0;
  double _uiScale  = 1.0;
  ThemeMode _themeMode = ThemeMode.system;
  AppLang _lang = AppLang.ko;
  List<SourceInfo> _bibles = [];
  List<SourceInfo> _commentaries = [];
  List<SourceInfo> _hymns = [];

  double get fontSize => _fontSize;
  double get uiScale  => _uiScale;
  ThemeMode get themeMode => _themeMode;
  AppLang get lang => _lang;
  L10n get t => L10n(_lang);
  List<SourceInfo> get bibles => _bibles;
  List<SourceInfo> get commentaries => _commentaries;
  List<SourceInfo> get hymns => _hymns;

  List<SourceInfo> get enabledBibles =>
      _bibles.where((s) => s.isEnabled).toList();

  List<SourceInfo> get enabledCommentaries =>
      _commentaries.where((s) => s.isEnabled).toList();

  List<SourceInfo> get enabledHymns =>
      _hymns.where((s) => s.isEnabled).toList();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _fontSize = prefs.getDouble(_kFontSize) ?? 16.0;
    _uiScale  = (prefs.getDouble(_kUiScale) ?? 1.0).clamp(0.9, 1.1);
    _themeMode = ThemeMode.values[prefs.getInt(_kThemeMode) ?? 0];
    _lang = AppLang.values[prefs.getInt(_kLang) ?? 0];

    final biblesJson = prefs.getString(_kBibles);
    if (biblesJson != null && biblesJson.isNotEmpty) {
      final saved = SourceInfo.decodeList(biblesJson);
      final savedIds = {for (final s in saved) s.id};
      _bibles = [
        ...saved,
        for (final b in kBuiltInBibles) if (!savedIds.contains(b.id)) b,
      ];
    } else {
      _bibles = List<SourceInfo>.from(kBuiltInBibles);
    }

    final commJson = prefs.getString(_kCommentaries);
    if (commJson != null && commJson.isNotEmpty) {
      final saved = SourceInfo.decodeList(commJson);
      final savedIds = {for (final s in saved) s.id};
      _commentaries = [
        ...saved,
        for (final c in kBuiltInCommentaries) if (!savedIds.contains(c.id)) c,
      ];
    } else {
      _commentaries = List<SourceInfo>.from(kBuiltInCommentaries);
    }

    final hymnsJson = prefs.getString(_kHymns);
    if (hymnsJson != null && hymnsJson.isNotEmpty) {
      final saved = SourceInfo.decodeList(hymnsJson);
      final savedIds = {for (final s in saved) s.id};
      _hymns = [
        ...saved,
        for (final h in kBuiltInHymns) if (!savedIds.contains(h.id)) h,
      ];
    } else {
      _hymns = List<SourceInfo>.from(kBuiltInHymns);
    }

    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(10.0, 32.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontSize, _fontSize);
  }

  Future<void> setUiScale(double scale) async {
    _uiScale = scale.clamp(0.9, 1.1);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kUiScale, _uiScale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, mode.index);
  }

  Future<void> setLang(AppLang lang) async {
    _lang = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLang, lang.index);
  }

  Future<void> toggleSource(SourceInfo source, bool enabled) async {
    source.isEnabled = enabled;
    notifyListeners();
    await _persist();
  }

  Future<void> addSource(SourceInfo source) async {
    switch (source.type) {
      case SourceType.bible:
        if (!_bibles.any((s) => s.id == source.id)) _bibles.add(source);
        break;
      case SourceType.commentary:
        if (!_commentaries.any((s) => s.id == source.id)) _commentaries.add(source);
        break;
      case SourceType.hymn:
        if (!_hymns.any((s) => s.id == source.id)) _hymns.add(source);
        break;
      case SourceType.dictionary:
        break;
    }
    notifyListeners();
    await _persist();
  }

  /// Returns true if [source] can be deleted.
  bool canRemove(SourceInfo source) {
    switch (source.type) {
      case SourceType.bible:
        return _bibles.length > 1; // must keep at least 1
      case SourceType.commentary:
        return source.id != '만나주석'; // keep built-in commentary
      case SourceType.hymn:
        return source.id != '새찬송가'; // keep built-in hymnal
      case SourceType.dictionary:
        return true;
    }
  }

  Future<void> removeSource(SourceInfo source) async {
    if (!canRemove(source)) return;
    switch (source.type) {
      case SourceType.bible:
        _bibles.removeWhere((s) => s.id == source.id);
        break;
      case SourceType.commentary:
        _commentaries.removeWhere((s) => s.id == source.id);
        break;
      case SourceType.hymn:
        _hymns.removeWhere((s) => s.id == source.id);
        break;
      case SourceType.dictionary:
        break;
    }
    notifyListeners();
    await _persist();
    // Delete the copied file from documents/bible_db/ for user-imported sources.
    // Built-ins live in APK assets (no real file to delete). Original file untouched.
    if (!source.isBuiltIn && source.docPath.isNotEmpty) {
      try {
        final f = File(source.docPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBibles,       SourceInfo.encodeList(_bibles));
    await prefs.setString(_kCommentaries, SourceInfo.encodeList(_commentaries));
    await prefs.setString(_kHymns,        SourceInfo.encodeList(_hymns));
  }
}
