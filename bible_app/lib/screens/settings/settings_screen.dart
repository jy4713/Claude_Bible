import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../constants/l10n.dart';
import '../../models/source_info.dart';
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
        // Font preview
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '태초에 하나님이 천지를 창조하시니라. (창 1:1)',
              style: TextStyle(fontSize: settings.fontSize, height: 1.6),
            ),
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
                title: Text(t.korean),
                value: AppLang.ko,
              ),
              RadioListTile<AppLang>(
                title: Text(t.english),
                value: AppLang.en,
              ),
            ],
          ),
        ),
        // ── 테마 ─────────────────────────────────────────────────────────
        const Divider(),
        _SectionHeader(t.theme),
        RadioGroup<ThemeMode>(
          groupValue: settings.themeMode,
          onChanged: (v) { if (v != null) settings.setThemeMode(v); },
          child: Column(
            children: [
              RadioListTile<ThemeMode>(
                title: Text(t.themeSystem),
                value: ThemeMode.system,
              ),
              RadioListTile<ThemeMode>(
                title: Text(t.themeLight),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: Text(t.themeDark),
                value: ThemeMode.dark,
              ),
            ],
          ),
        ),
        // ── 성경 목록 ─────────────────────────────────────────────────────
        const Divider(),
        _SectionHeader(t.bibleTranslations),
        ..._buildSourceList(context, settings, settings.bibles, SourceType.bible),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(t.addBibleFile),
          onTap: () => _importFile(context, SourceType.bible),
        ),
        // ── 주석 목록 ─────────────────────────────────────────────────────
        const Divider(),
        _SectionHeader(t.commentarySection),
        ..._buildSourceList(context, settings, settings.commentaries, SourceType.commentary),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(t.addCommentaryFile),
          onTap: () => _importFile(context, SourceType.commentary),
        ),
        // ── 찬송가 목록 ───────────────────────────────────────────────────
        const Divider(),
        _SectionHeader(t.hymnSection),
        ..._buildSourceList(context, settings, settings.hymns, SourceType.hymn),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(t.addHymnFile),
          onTap: () => _importFile(context, SourceType.hymn),
        ),
        const SizedBox(height: 24),
      ],
    );
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
        leading: Icon(
          _iconFor(type),
          color: src.isEnabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        title: Text(src.name),
        subtitle: src.isBuiltIn ? Text(settings.t.builtIn) : Text(src.docPath),
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

    // Copy to documents directory
    final docs = await getApplicationDocumentsDirectory();
    final destDir  = Directory(p.join(docs.path, 'bible_db'));
    await destDir.create(recursive: true);
    final destPath = p.join(destDir.path, p.basename(srcPath));
    await File(srcPath).copy(destPath);

    // For hymns, also copy the sibling .cmp (sheet-music archive) if present,
    // so the same-named sheet music loads automatically.
    var copiedCmp = false;
    if (type == SourceType.hymn) {
      final base = p.basenameWithoutExtension(srcPath);
      final cmpSrc = p.join(p.dirname(srcPath), '$base.cmp');
      if (File(cmpSrc).existsSync()) {
        await File(cmpSrc).copy(p.join(destDir.path, '$base.cmp'));
        copiedCmp = true;
      }
    }

    final id   = p.basenameWithoutExtension(srcPath);
    final src  = SourceInfo(
      id:      id,
      name:    id,
      type:    type,
      docPath: destPath,
    );

    if (context.mounted) {
      context.read<SettingsProvider>().addSource(src);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copiedCmp ? '${t.addedMsg(id)} · ${t.cmpAlsoAdded}' : t.addedMsg(id),
          ),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: Text(t.delete)),
        ],
      ),
    );
    if (ok == true) settings.removeSource(src);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}
