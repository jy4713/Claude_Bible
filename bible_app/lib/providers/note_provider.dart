import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/note.dart';
import '../repositories/note_repository.dart';

class NoteProvider with ChangeNotifier {
  // verse_from → Note for the currently displayed chapter
  final Map<int, Note> _chapterNotes = {};
  int _loadedBook = -1;
  int _loadedChapter = -1;

  bool hasNote(int verse) {
    for (final n in _chapterNotes.values) {
      if (n.verseFrom <= verse && verse <= n.verseTo) return true;
    }
    return false;
  }

  Note? getNote(int verse) {
    for (final n in _chapterNotes.values) {
      if (n.verseFrom <= verse && verse <= n.verseTo) return n;
    }
    return null;
  }

  Future<void> loadForChapter(int book, int chapter) async {
    if (_loadedBook == book && _loadedChapter == chapter) return;
    _loadedBook = book;
    _loadedChapter = chapter;
    _chapterNotes.clear();
    final notes =
        await NoteRepository.instance.getNotesForChapter(book, chapter);
    for (final n in notes) {
      _chapterNotes[n.verseFrom] = n;
    }
    notifyListeners();
  }

  Future<void> _reloadCurrent() async {
    final b = _loadedBook;
    final c = _loadedChapter;
    _loadedBook = -1;
    _loadedChapter = -1;
    await loadForChapter(b, c);
  }

  Future<void> saveNote(Note note) async {
    await NoteRepository.instance.saveNote(note);
    await _reloadCurrent();
  }

  Future<void> deleteNote(int id) async {
    await NoteRepository.instance.deleteNote(id);
    await _reloadCurrent();
  }

  Future<String> exportCsv() async {
    final notes = await NoteRepository.instance.getAllNotes();
    final buf = StringBuffer();
    buf.writeln('book,chapter,verse_from,verse_to,note,created_at');
    for (final n in notes) {
      final escaped = n.text.replaceAll('"', '""');
      buf.writeln(
          '${n.book},${n.chapter},${n.verseFrom},${n.verseTo},"$escaped",${n.createdAt}');
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'bible_notes_export.csv');
    await File(path).writeAsString(buf.toString(), flush: true);
    return path;
  }

  Future<int> importCsv(String filePath) async {
    final lines = await File(filePath).readAsLines();
    if (lines.isEmpty) return 0;
    int count = 0;
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      try {
        final parts = _parseCsvLine(line);
        if (parts.length < 5) continue;
        final note = Note(
          book: int.parse(parts[0]),
          chapter: int.parse(parts[1]),
          verseFrom: int.parse(parts[2]),
          verseTo: int.parse(parts[3]),
          text: parts[4],
          createdAt: parts.length > 5 && parts[5].isNotEmpty ? parts[5] : null,
        );
        await NoteRepository.instance.saveNote(note);
        count++;
      } catch (_) {}
    }
    await _reloadCurrent();
    return count;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (c == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString());
    return result;
  }
}
