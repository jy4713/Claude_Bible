import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../constants/l10n.dart';
import '../../models/source_info.dart';
import '../../providers/bible_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final t = settings.t;

    return ListView(
      children: [
        // ── 글자 크기 ─────────────────────────────────────────────────────
        _SectionHeader(t.view),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(t.fontSize),
              Expanded(
                child: Slider(
                  value: settings.fontSize,
                  min: 10,
                  max: 32,
                  divisions: 22,
                  label: '${settings.fontSize.round()}',
                  onChanged: settings.setFontSize,
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${settings.fontSize.round()}',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
              child: Text(
                '태초에 하나님이 천지를 창조하시니라. (창 1:1)',
                style: TextStyle(fontSize: settings.fontSize, height: 1.6),
              ),
            ),
          ),
        ),
        // ── 메뉴 글자 크기 ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(t.uiFontSize),
              Expanded(
                child: Slider(
                  value: settings.uiScale,
                  min: 0.9,
                  max: 1.1,
                  divisions: 4,
                  label: '${(settings.uiScale * 100).round()}%',
                  onChanged: settings.setUiScale,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${(settings.uiScale * 100).round()}%',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        // ── 언어 ─────────────────────────────────────────────────────────
        const Divider(),
        _SectionHeader(t.languageSection),
        RadioGroup<AppLang>(
          groupValue: settings.lang,
          onChanged: (v) { if (v != null) settings.setLang(v); },
          child: Column(
            children: [
              RadioListTile<AppLang>(
                  title: Text(t.korean), value: AppLang.ko,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
              RadioListTile<AppLang>(
                  title: Text(t.english), value: AppLang.en,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
            ],
          ),
        ),
        // ── 테마 ─────────────────────────────────────────────────────────
        const Divider(height: 8),
        _SectionHeader(t.theme),
        RadioGroup<ThemeMode>(
          groupValue: settings.themeMode,
          onChanged: (v) { if (v != null) settings.setThemeMode(v); },
          child: Column(
            children: [
              RadioListTile<ThemeMode>(
                  title: Text(t.themeSystem), value: ThemeMode.system,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
              RadioListTile<ThemeMode>(
                  title: Text(t.themeLight), value: ThemeMode.light,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
              RadioListTile<ThemeMode>(
                  title: Text(t.themeDark), value: ThemeMode.dark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
            ],
          ),
        ),
        // ── 노트 ─────────────────────────────────────────────────────────
        const Divider(height: 8),
        _SectionHeader(t.noteSection),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.upload_file),
          title: Text(t.exportNotes),
          subtitle: const Text('CSV 파일로 저장'),
          onTap: () => _exportNotes(context),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.download),
          title: Text(t.importNotes),
          subtitle: const Text('CSV 파일에서 가져오기'),
          onTap: () => _importNotes(context),
        ),
        // ── 성경 목록 ─────────────────────────────────────────────────────
        const Divider(height: 8),
        _SectionHeader(t.bibleTranslations),
        ..._buildSourceList(context, settings, settings.bibles, SourceType.bible),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.add),
          title: Text(t.addBibleFile),
          onTap: () => _importFile(context, SourceType.bible),
        ),
        // ── 주석 목록 ─────────────────────────────────────────────────────
        const Divider(height: 8),
        _SectionHeader(t.commentarySection),
        ..._buildSourceList(context, settings, settings.commentaries, SourceType.commentary),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.add),
          title: Text(t.addCommentaryFile),
          onTap: () => _importFile(context, SourceType.commentary),
        ),
        // ── 찬송가 목록 ───────────────────────────────────────────────────
        const Divider(height: 8),
        _SectionHeader(t.hymnSection),
        ..._buildSourceList(context, settings, settings.hymns, SourceType.hymn),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.add),
          title: Text(t.addHymnFile),
          onTap: () => _importFile(context, SourceType.hymn),
        ),
        const Divider(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              '최준영 제작',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportNotes(BuildContext context) async {
    final notes = context.read<NoteProvider>();
    try {
      final bytes = await notes.buildCsvBytes();
      final path = await FilePicker.platform.saveFile(
        dialogTitle: '노트 내보내기',
        fileName: 'bible_notes_export.csv',
        bytes: bytes,
      );
      if (path == null) return;
      if (context.mounted) _showSnack(context, '저장됨: $path');
    } catch (e) {
      if (context.mounted) _showSnack(context, '오류: $e');
    }
  }

  Future<void> _importNotes(BuildContext context) async {
    final notes = context.read<NoteProvider>();
    final t = context.read<SettingsProvider>().t;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    if (!path.toLowerCase().endsWith('.csv')) {
      if (context.mounted) {
        _showSnack(context, t.onlySupported('.csv'));
      }
      return;
    }

    try {
      final count = await notes.importCsv(path);
      if (context.mounted) {
        _showSnack(context, t.importSuccess(count));
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, t.importFailed);
      }
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  List<Widget> _buildSourceList(
    BuildContext context,
    SettingsProvider settings,
    List<SourceInfo> sources,
    SourceType type,
  ) {
    return sources.map((src) {
      final canDel = settings.canRemove(src);
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(
          _iconFor(type),
          color: src.isEnabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        title: Text(src.name),
        subtitle: src.isBuiltIn
            ? Text(settings.t.builtIn)
            : Text(src.docPath),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: src.isEnabled,
              onChanged: (v) => settings.toggleSource(src, v),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: canDel
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
              tooltip: canDel ? settings.t.delete : null,
              onPressed: canDel
                  ? () => _confirmRemove(context, settings, src)
                  : null,
            ),
          ],
        ),
      );
    }).toList();
  }

  IconData _iconFor(SourceType type) {
    switch (type) {
      case SourceType.bible:       return Icons.menu_book;
      case SourceType.commentary:  return Icons.comment_outlined;
      case SourceType.hymn:        return Icons.music_note_outlined;
      case SourceType.dictionary:  return Icons.abc;
    }
  }

  Future<void> _importFile(BuildContext context, SourceType type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final srcPath = file.path;
    if (srcPath == null) return;

    final ext = p.extension(srcPath).toLowerCase();
    final allowed = {
      SourceType.bible:       ['.bdb'],
      SourceType.commentary:  ['.cdb'],
      SourceType.hymn:        ['.hdb'],
      SourceType.dictionary:  ['.dct'],
    }[type]!;

    final t = context.mounted
        ? context.read<SettingsProvider>().t
        : const L10n(AppLang.ko);

    if (!allowed.contains(ext)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.onlySupported(allowed.join(", ")))),
        );
      }
      return;
    }

    final docs    = await getApplicationDocumentsDirectory();
    final destDir = Directory(p.join(docs.path, 'bible_db'));
    await destDir.create(recursive: true);
    final destPath = p.join(destDir.path, p.basename(srcPath));
    await File(srcPath).copy(destPath);

    var copiedCmp = false;
    if (type == SourceType.hymn) {
      final base   = p.basenameWithoutExtension(srcPath);
      final cmpSrc = p.join(p.dirname(srcPath), '$base.cmp');
      if (File(cmpSrc).existsSync()) {
        await File(cmpSrc).copy(p.join(destDir.path, '$base.cmp'));
        copiedCmp = true;
      }
    }

    final id  = p.basenameWithoutExtension(srcPath);
    final src = SourceInfo(
      id:      id,
      name:    id,
      type:    type,
      docPath: destPath,
    );

    if (context.mounted) {
      context.read<SettingsProvider>().addSource(src);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(copiedCmp
              ? '${t.addedMsg(id)} · ${t.cmpAlsoAdded}'
              : t.addedMsg(id)),
        ),
      );
    }
  }

  Future<void> _confirmRemove(
      BuildContext context, SettingsProvider settings, SourceInfo src) async {
    final t = settings.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.removeConfirm(src.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t.delete)),
        ],
      ),
    );
    if (ok == true) {
      settings.removeSource(src);
      if (src.type == SourceType.bible && context.mounted) {
        final bible = context.read<BibleProvider>();
        final remaining = settings.enabledBibles;
        // Remove deleted source from compare IDs
        if (bible.selectedIds.contains(src.id)) {
          final newIds =
              bible.selectedIds.where((id) => id != src.id).toList();
          bible.setSelectedIds(
            newIds.isEmpty && remaining.isNotEmpty
                ? [remaining.first.id]
                : newIds,
            remaining,
          );
        }
        // Switch primary if the deleted source was active
        if (bible.primaryId == src.id && remaining.isNotEmpty) {
          bible.setSingleId(remaining.first.id, remaining);
        }
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}
