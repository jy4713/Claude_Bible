import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/hymn_entry.dart';
import '../models/source_info.dart';
import 'database_helper.dart';

class HymnRepository {
  HymnRepository._();
  static final HymnRepository instance = HymnRepository._();

  // Cache of "sourceId:hymnNumber" → extracted image bytes
  final Map<String, Uint8List> _imageCache = {};
  // Cache of sourceId → decoded .cmp archive (null = tried, none found)
  final Map<String, Archive?> _archives = {};

  Future<List<HymnEntry>> getAllHymns(SourceInfo source) async {
    final db = source.isBuiltIn
        ? await DatabaseHelper.instance.openAsset(source.assetPath)
        : await DatabaseHelper.instance.openExternal(source.docPath);
    if (db == null) return [];

    final rows = await db.query('hymnal', orderBy: 'chapter');
    return rows.map((r) => HymnEntry.fromMap(r)).toList();
  }

  Future<HymnEntry?> getHymn(SourceInfo source, int chapter) async {
    final db = source.isBuiltIn
        ? await DatabaseHelper.instance.openAsset(source.assetPath)
        : await DatabaseHelper.instance.openExternal(source.docPath);
    if (db == null) return null;

    final rows = await db.query('hymnal', where: 'chapter = ?', whereArgs: [chapter]);
    if (rows.isEmpty) return null;
    return HymnEntry.fromMap(rows.first);
  }

  Future<List<HymnEntry>> searchHymns(SourceInfo source, String query) async {
    if (query.trim().isEmpty) return getAllHymns(source);
    final db = source.isBuiltIn
        ? await DatabaseHelper.instance.openAsset(source.assetPath)
        : await DatabaseHelper.instance.openExternal(source.docPath);
    if (db == null) return [];

    final rows = await db.query(
      'hymnal',
      where: 'title LIKE ? OR htext LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'chapter',
    );
    return rows.map((r) => HymnEntry.fromMap(r)).toList();
  }

  /// Returns sheet-music image bytes for a hymn chapter number.
  ///
  /// Each hymn source has a sibling `.cmp` (ZIP of `p{n}.png`) with the same
  /// base name as its `.hdb`. For a user-imported hymn `X.hdb`, `X.cmp` in the
  /// same folder is loaded automatically.
  Future<Uint8List?> getHymnImage(SourceInfo source, int chapter) async {
    final key = '${source.id}:$chapter';
    if (_imageCache.containsKey(key)) return _imageCache[key];

    final archive = await _archiveFor(source);
    if (archive == null) return null;

    final file = archive.findFile('p$chapter.png');
    if (file == null) return null;

    final bytes = Uint8List.fromList(file.content as List<int>);
    _imageCache[key] = bytes;
    return bytes;
  }

  String _swapToCmp(String path) {
    final dir = p.dirname(path);
    final base = p.basenameWithoutExtension(path);
    return p.join(dir, '$base.cmp');
  }

  Future<Archive?> _archiveFor(SourceInfo source) async {
    if (_archives.containsKey(source.id)) return _archives[source.id];

    Archive? archive;
    try {
      Uint8List? bytes;
      if (source.docPath.isNotEmpty) {
        // User-imported: sibling .cmp next to the .hdb.
        final cmpPath = _swapToCmp(source.docPath);
        if (File(cmpPath).existsSync()) {
          bytes = await File(cmpPath).readAsBytes();
        }
      } else if (source.assetPath.isNotEmpty) {
        // Built-in asset: prefer a cached copy, else load from bundle.
        final cmpAsset = _swapToCmp(source.assetPath).replaceAll('\\', '/');
        final docs = await getApplicationDocumentsDirectory();
        final cached =
            p.join(docs.path, 'bible_db', p.basename(cmpAsset));
        if (File(cached).existsSync()) {
          bytes = await File(cached).readAsBytes();
        } else {
          final data = await rootBundle.load(cmpAsset);
          bytes = data.buffer.asUint8List();
          await File(cached).writeAsBytes(bytes);
        }
      }
      if (bytes != null) archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      // Leave archive null on any failure.
    }
    _archives[source.id] = archive;
    return archive;
  }
}
