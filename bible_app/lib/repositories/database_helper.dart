import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'db_bytes_io.dart' if (dart.library.html) 'db_bytes_web.dart';

/// Manages all SQLite DB connections.
/// On first use, copies bundled assets to the app's documents directory
/// (sqflite needs a file path, not raw bytes on mobile/desktop).
/// On web, writes asset bytes to the virtual OPFS filesystem via sqflite_common_ffi_web.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  final Map<String, Database> _cache = {};

  Future<String> _dbDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'bible_db'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  /// Copies an asset to the documents directory if not already there (native only).
  /// Returns the absolute file path.
  Future<String> ensureAsset(String assetPath) async {
    final dir = await _dbDir();
    final fileName = p.basename(assetPath);
    final destPath = p.join(dir, fileName);

    if (!File(destPath).existsSync()) {
      final ByteData data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      await File(destPath).writeAsBytes(bytes, flush: true);
    }
    return destPath;
  }

  /// Opens (or returns cached) database at [filePath].
  Future<Database> open(String filePath) async {
    if (_cache.containsKey(filePath) && (_cache[filePath]?.isOpen ?? false)) {
      return _cache[filePath]!;
    }
    final db = await openDatabase(filePath, readOnly: true);
    _cache[filePath] = db;
    return db;
  }

  /// Opens a built-in asset DB.
  /// - Native: copies to docs dir, opens by file path.
  /// - Web: writes to OPFS virtual FS via sqflite_common_ffi_web, then opens.
  Future<Database> openAsset(String assetPath) async {
    if (kIsWeb) {
      return _openAssetWeb(assetPath);
    }
    final path = await ensureAsset(assetPath);
    return open(path);
  }

  Future<Database> _openAssetWeb(String assetPath) async {
    final fileName = p.basename(assetPath);
    final dbPath = await getDatabasesPath();
    final filePath = p.posix.join(dbPath, fileName);

    if (_cache.containsKey(filePath) && (_cache[filePath]?.isOpen ?? false)) {
      return _cache[filePath]!;
    }

    if (!await databaseExists(filePath)) {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      await writeDbBytes(filePath, bytes);
    }

    final db = await openDatabase(filePath, readOnly: true);
    _cache[filePath] = db;
    return db;
  }

  /// Opens a user-imported DB at [absolutePath].
  Future<Database> openExternal(String absolutePath) => open(absolutePath);

  Future<void> closeAll() async {
    for (final db in _cache.values) {
      if (db.isOpen) await db.close();
    }
    _cache.clear();
  }
}
