import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note.dart';

class NoteRepository {
  static final NoteRepository instance = NoteRepository._();
  NoteRepository._();

  Database? _db;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'bible_notes.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse_from INTEGER NOT NULL,
            verse_to INTEGER NOT NULL,
            text TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_notes_loc ON notes(book, chapter)');
      },
    );
    return _db!;
  }

  Future<List<Note>> getNotesForChapter(int book, int chapter) async {
    final db = await _getDb();
    final rows = await db.query(
      'notes',
      where: 'book = ? AND chapter = ?',
      whereArgs: [book, chapter],
      orderBy: 'verse_from',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<Note?> getNoteForVerse(int book, int chapter, int verse) async {
    final db = await _getDb();
    final rows = await db.query(
      'notes',
      where:
          'book = ? AND chapter = ? AND verse_from <= ? AND verse_to >= ?',
      whereArgs: [book, chapter, verse, verse],
      limit: 1,
    );
    return rows.isEmpty ? null : Note.fromMap(rows.first);
  }

  Future<int> saveNote(Note note) async {
    final db = await _getDb();
    final map = note.toMap();
    if (note.id != null) {
      map.remove('id');
      await db.update('notes', map, where: 'id = ?', whereArgs: [note.id]);
      return note.id!;
    }
    map.remove('id');
    return db.insert('notes', map);
  }

  Future<void> deleteNote(int id) async {
    final db = await _getDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> getAllNotes() async {
    final db = await _getDb();
    final rows = await db.query(
        'notes', orderBy: 'book, chapter, verse_from');
    return rows.map(Note.fromMap).toList();
  }
}
