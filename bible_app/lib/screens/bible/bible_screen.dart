import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/book_names.dart';
import '../../models/note.dart';
import '../../models/source_info.dart';
import '../../models/verse.dart';
import '../../providers/bible_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/settings_provider.dart';
import 'bible_search_screen.dart';
import '_book_selector_dialog.dart';
import '_translation_selector.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLoad());
  }

  void _initLoad() {
    final settings = context.read<SettingsProvider>();
    final bible   = context.read<BibleProvider>();
    final notes   = context.read<NoteProvider>();
    final sources = settings.enabledBibles;
    if (sources.isNotEmpty) {
      bible.reload(sources);
    }
    notes.loadForChapter(bible.book, bible.chapter);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Navigation helpers ───────────────────────────────────────────────────

  void _prevChapter(BibleProvider bible, List<SourceInfo> sources) {
    final notes = context.read<NoteProvider>();
    int book = bible.book, chapter = bible.chapter;
    if (chapter > 1) {
      chapter--;
    } else if (book > 1) {
      book--;
      chapter = bookInfoOf(book).chapters;
    }
    bible.navigate(sources, book, chapter);
    notes.loadForChapter(book, chapter);
  }

  void _nextChapter(BibleProvider bible, List<SourceInfo> sources) {
    final notes  = context.read<NoteProvider>();
    final info   = bookInfoOf(bible.book);
    int book = bible.book, chapter = bible.chapter;
    if (chapter < info.chapters) {
      chapter++;
    } else if (book < 66) {
      book++;
      chapter = 1;
    }
    bible.navigate(sources, book, chapter);
    notes.loadForChapter(book, chapter);
  }

  Future<void> _selectBook(
      BibleProvider bible, List<SourceInfo> sources) async {
    final notes = context.read<NoteProvider>();
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => BookSelectorDialog(
        currentBook: bible.book,
        currentChapter: bible.chapter,
        currentVerse: bible.verse,
      ),
    );
    if (result != null && mounted) {
      final v = result['verse'] ?? 1;
      await bible.navigate(sources, result['book']!, result['chapter']!,
          verseIndex: v - 1);
      notes.loadForChapter(result['book']!, result['chapter']!);
    }
  }

  // Single translation selector (no compare)
  Future<void> _selectTranslation(List<SourceInfo> sources) async {
    final bible = context.read<BibleProvider>();
    // Temporarily ensure compare mode is off
    if (bible.compareMode) {
      bible.toggleCompare(sources);
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TranslationSelector(
        allSources: sources,
        compareMode: false,
      ),
    );
  }

  // Compare translation selector
  Future<void> _openCompare(List<SourceInfo> sources) async {
    final bible = context.read<BibleProvider>();
    // Ensure compare mode is on
    if (!bible.compareMode) {
      bible.toggleCompare(sources);
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TranslationSelector(
        allSources: sources,
        compareMode: true,
      ),
    );
  }

  SourceInfo? _srcById(List<SourceInfo> sources, String id) {
    for (final s in sources) {
      if (s.id == id) return s;
    }
    return null;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final bible    = context.watch<BibleProvider>();
    final notes    = context.watch<NoteProvider>();
    final sources  = settings.enabledBibles;
    final t        = settings.t;

    final bookInfo = bookInfoOf(bible.book);
    final fontSize = settings.fontSize;

    if (sources.isNotEmpty &&
        !sources.any((s) => s.id == bible.primaryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bible.setSelectedIds([sources.first.id], sources);
      });
    }

    final showCompare = bible.compareMode && bible.selectedIds.length > 1;

    final primarySrc = _srcById(sources, bible.primaryId);
    final english = !showCompare && (primarySrc?.isEnglish ?? false);
    final bookLabel = english
        ? '${bookInfo.korean} / ${bookInfo.english}'
        : bookInfo.korean;
    final verseLabel = !showCompare && bible.verse > 1
        ? ':${bible.verse}'
        : '';
    final titleText =
        '$bookLabel ${t.chapter(bible.chapter)}$verseLabel';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TextButton(
                onPressed: () => _selectBook(bible, sources),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: Text(
                  titleText,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: t.prevChapter,
              onPressed: () => _prevChapter(bible, sources),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: t.nextChapter,
              onPressed: () => _nextChapter(bible, sources),
            ),
          ],
        ),
        actions: [
          // Single translation button
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: t.translationSettings,
            onPressed: () => _selectTranslation(sources),
          ),
          // Compare translations button
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: t.compareSettings,
            onPressed: () => _openCompare(sources),
          ),
          // Search
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: t.searchBible,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BibleSearchScreen(
                  sources: sources,
                  currentBook: bible.book,
                  fontSize: fontSize,
                  onNavigate: (book, chapter, verse) {
                    Navigator.pop(context);
                    final np = context.read<NoteProvider>();
                    bible.navigate(sources, book, chapter,
                        verseIndex: verse - 1);
                    np.loadForChapter(book, chapter);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: bible.loading
          ? const Center(child: CircularProgressIndicator())
          : bible.error != null
              ? _Error(message: bible.error!)
              : showCompare
                  ? _CompareView(
                      bible: bible,
                      sources: sources,
                      fontSize: fontSize,
                    )
                  : _SingleView(
                      bible: bible,
                      notes: notes,
                      sourceId: bible.primaryId,
                      fontSize: fontSize,
                      scrollController: _scrollController,
                      emptyText: t.noData,
                      onChapterChanged: (book, chapter) {
                        context
                            .read<NoteProvider>()
                            .loadForChapter(book, chapter);
                      },
                    ),
    );
  }
}

// ── Single translation view ──────────────────────────────────────────────────

class _SingleView extends StatefulWidget {
  final BibleProvider bible;
  final NoteProvider notes;
  final String sourceId;
  final double fontSize;
  final ScrollController scrollController;
  final String emptyText;
  final void Function(int book, int chapter) onChapterChanged;

  const _SingleView({
    required this.bible,
    required this.notes,
    required this.sourceId,
    required this.fontSize,
    required this.scrollController,
    required this.emptyText,
    required this.onChapterChanged,
  });

  @override
  State<_SingleView> createState() => _SingleViewState();
}

class _SingleViewState extends State<_SingleView> {
  final Map<int, GlobalKey> _verseKeys = {};
  Set<int> _selectedVerses = {};
  bool _selectionMode = false;
  int? _lastBook;
  int? _lastChapter;

  @override
  void initState() {
    super.initState();
    _lastBook    = widget.bible.book;
    _lastChapter = widget.bible.chapter;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerse());
  }

  @override
  void didUpdateWidget(covariant _SingleView old) {
    super.didUpdateWidget(old);
    if (widget.bible.book != _lastBook ||
        widget.bible.chapter != _lastChapter) {
      _lastBook    = widget.bible.book;
      _lastChapter = widget.bible.chapter;
      _verseKeys.clear();
      setState(() {
        _selectedVerses = {};
        _selectionMode = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerse());
    }
  }

  void _scrollToVerse() {
    final idx = widget.bible.verseIndex;
    if (idx <= 0) return;
    final verses = widget.bible.versesFor(widget.sourceId);
    if (idx >= verses.length) return;
    final vNum = verses[idx].verse;
    final key  = _verseKeys[vNum];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.0,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void _onVerseTap(Verse verse) {
    if (_selectionMode) {
      setState(() {
        if (_selectedVerses.contains(verse.verse)) {
          _selectedVerses.remove(verse.verse);
          if (_selectedVerses.isEmpty) _selectionMode = false;
        } else {
          _selectedVerses.add(verse.verse);
        }
      });
      return;
    }
    final note = widget.notes.getNote(verse.verse);
    if (note != null) {
      _showNoteViewDialog(note);
    }
  }

  void _onVerseLongPress(Verse verse) {
    setState(() {
      _selectionMode = true;
      _selectedVerses = {verse.verse};
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectionMode = false;
      _selectedVerses = {};
    });
  }

  Future<void> _showAddNoteDialog() async {
    if (_selectedVerses.isEmpty) return;
    final sorted = _selectedVerses.toList()..sort();
    final from = sorted.first;
    final to   = sorted.last;
    final bible = widget.bible;
    final existing = widget.notes.getNote(from);

    await _openNoteEditor(
      context: context,
      book: bible.book,
      chapter: bible.chapter,
      verseFrom: from,
      verseTo: to,
      existingNote: existing,
    );
    setState(() {
      _selectionMode = false;
      _selectedVerses = {};
    });
  }

  void _showNoteViewDialog(Note note) {
    showDialog(
      context: context,
      builder: (_) => _NoteViewDialog(
        note: note,
        onEdit: () {
          Navigator.pop(context);
          _openNoteEditor(
            context: context,
            book: note.book,
            chapter: note.chapter,
            verseFrom: note.verseFrom,
            verseTo: note.verseTo,
            existingNote: note,
          );
        },
        onDelete: () async {
          Navigator.pop(context);
          await widget.notes.deleteNote(note.id!);
        },
      ),
    );
  }

  Future<void> _openNoteEditor({
    required BuildContext context,
    required int book,
    required int chapter,
    required int verseFrom,
    required int verseTo,
    Note? existingNote,
  }) async {
    final controller =
        TextEditingController(text: existingNote?.text ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existingNote != null ? '노트 편집' : '노트 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$chapter장 $verseFrom${verseFrom != verseTo ? '-$verseTo' : ''}절',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '여기에 노트를 입력하세요...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      final note = Note(
        id: existingNote?.id,
        book: book,
        chapter: chapter,
        verseFrom: verseFrom,
        verseTo: verseTo,
        text: result.trim(),
      );
      await widget.notes.saveNote(note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verses = widget.bible.versesFor(widget.sourceId);
    if (verses.isEmpty) {
      return Center(child: Text(widget.emptyText));
    }

    return Stack(
      children: [
        ListView.builder(
          controller: widget.scrollController,
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, _selectionMode ? 72 : 8),
          itemCount: verses.length,
          itemBuilder: (_, i) {
            final v = verses[i];
            final key =
                _verseKeys.putIfAbsent(v.verse, () => GlobalKey());
            final hasNote = widget.notes.hasNote(v.verse);
            final isSelected = _selectedVerses.contains(v.verse);
            return _VerseItem(
              key: key,
              verse: v,
              fontSize: widget.fontSize,
              hasNote: hasNote,
              isSelected: isSelected,
              selectionMode: _selectionMode,
              onTap: () => _onVerseTap(v),
              onLongPress: () => _onVerseLongPress(v),
            );
          },
        ),
        // Selection mode action bar
        if (_selectionMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Text(
                      '${_selectedVerses.length}절 선택됨',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.note_add),
                      label: const Text('노트 추가'),
                      onPressed: _showAddNoteDialog,
                    ),
                    TextButton(
                      onPressed: _cancelSelection,
                      child: const Text('취소'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Compare view ─────────────────────────────────────────────────────────────

class _CompareView extends StatefulWidget {
  final BibleProvider bible;
  final List<SourceInfo> sources;
  final double fontSize;

  const _CompareView({
    required this.bible,
    required this.sources,
    required this.fontSize,
  });

  @override
  State<_CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<_CompareView> {
  late final _LinkedScrollGroup _linked;
  late final List<ScrollController> _controllers;

  @override
  void initState() {
    super.initState();
    _linked = _LinkedScrollGroup();
    _controllers = List.generate(
      BibleProvider.maxCompare,
      (_) => _linked.create(),
    );
  }

  @override
  void dispose() {
    _linked.dispose();
    super.dispose();
  }

  String _nameFor(String id) {
    for (final s in widget.sources) {
      if (s.id == id) return s.name;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.bible.selectedIds;
    if (widget.bible.compareAxis == Axis.horizontal) {
      return _AlignedTable(
        ids: ids,
        nameFor: _nameFor,
        bible: widget.bible,
        fontSize: widget.fontSize,
      );
    }

    final panels = <Widget>[];
    for (int i = 0; i < ids.length; i++) {
      final id = ids[i];
      panels.add(Expanded(
        child: _PanelColumn(
          order: i + 1,
          name: _nameFor(id),
          verses: widget.bible.versesFor(id),
          fontSize: widget.fontSize,
          controller: _controllers[i],
        ),
      ));
      if (i < ids.length - 1) {
        panels.add(const VerticalDivider(width: 1));
      }
    }
    return Row(children: panels);
  }
}

/// Horizontal compare: single scrollable table with verses aligned by number.
class _AlignedTable extends StatelessWidget {
  final List<String> ids;
  final String Function(String) nameFor;
  final BibleProvider bible;
  final double fontSize;

  const _AlignedTable({
    required this.ids,
    required this.nameFor,
    required this.bible,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final maps      = <String, Map<int, String>>{};
    final verseNums = <int>{};
    for (final id in ids) {
      final m = <int, String>{};
      for (final v in bible.versesFor(id)) {
        m[v.verse] = v.text;
        verseNums.add(v.verse);
      }
      maps[id] = m;
    }
    final sortedNums = verseNums.toList()..sort();
    final scheme = Theme.of(context).colorScheme;

    Widget headerCell(int i) => Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: scheme.surfaceContainerHighest,
            child: Row(
              children: [
                _OrderBadge(order: i + 1),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nameFor(ids[i]),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 32),
            for (int i = 0; i < ids.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              headerCell(i),
            ],
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: sortedNums.length,
            itemBuilder: (_, r) {
              final vn = sortedNums[r];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$vn',
                        style: TextStyle(
                          fontSize: fontSize * 0.8,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    for (int i = 0; i < ids.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          maps[ids[i]]?[vn] ?? '',
                          style:
                              TextStyle(fontSize: fontSize, height: 1.5),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PanelColumn extends StatelessWidget {
  final int order;
  final String name;
  final List<Verse> verses;
  final double fontSize;
  final ScrollController controller;

  const _PanelColumn({
    required this.order,
    required this.name,
    required this.verses,
    required this.fontSize,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              _OrderBadge(order: order),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            itemCount: verses.length,
            itemBuilder: (_, i) =>
                _VerseItem(verse: verses[i], fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}

class _OrderBadge extends StatelessWidget {
  final int order;
  const _OrderBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 9,
      backgroundColor: scheme.primary,
      child: Text(
        '$order',
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Keeps several [ScrollController]s in sync by fraction of maxScrollExtent.
class _LinkedScrollGroup {
  final List<ScrollController> _controllers = [];
  bool _syncing = false;

  ScrollController create() {
    final c = ScrollController();
    c.addListener(() => _onScroll(c));
    _controllers.add(c);
    return c;
  }

  void _onScroll(ScrollController source) {
    if (_syncing || !source.hasClients) return;
    final maxSrc = source.position.maxScrollExtent;
    if (maxSrc == 0) return;
    _syncing = true;
    final fraction = source.offset / maxSrc;
    for (final c in _controllers) {
      if (c != source && c.hasClients && c.position.maxScrollExtent > 0) {
        final target = (fraction * c.position.maxScrollExtent)
            .clamp(0.0, c.position.maxScrollExtent);
        if ((c.offset - target).abs() > 1.0) c.jumpTo(target);
      }
    }
    _syncing = false;
  }

  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    _controllers.clear();
  }
}

// ── Verse item ───────────────────────────────────────────────────────────────

class _VerseItem extends StatelessWidget {
  final Verse verse;
  final double fontSize;
  final bool hasNote;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _VerseItem({
    super.key,
    required this.verse,
    required this.fontSize,
    this.hasNote = false,
    this.isSelected = false,
    this.selectionMode = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = isSelected
        ? scheme.primaryContainer.withValues(alpha: 0.5)
        : Colors.transparent;

    Widget textContent = Text(
      verse.text,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.6,
        decoration: hasNote ? TextDecoration.underline : null,
        decorationStyle:
            hasNote ? TextDecorationStyle.dashed : null,
        decorationColor:
            hasNote ? scheme.tertiary : null,
        decorationThickness: hasNote ? 1.5 : null,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Row(
                children: [
                  if (selectionMode)
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 16,
                      color: isSelected
                          ? scheme.primary
                          : scheme.outline,
                    )
                  else
                    Text(
                      '${verse.verse}',
                      style: TextStyle(
                        fontSize: fontSize * 0.8,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: textContent),
          ],
        ),
      ),
    );
  }
}

// ── Note view dialog ─────────────────────────────────────────────────────────

class _NoteViewDialog extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteViewDialog({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final verseLabel = note.verseFrom == note.verseTo
        ? '${note.chapter}장 ${note.verseFrom}절'
        : '${note.chapter}장 ${note.verseFrom}-${note.verseTo}절';

    return AlertDialog(
      title: Text(verseLabel,
          style: TextStyle(color: scheme.primary, fontSize: 15)),
      content: SingleChildScrollView(
        child: Text(note.text, style: const TextStyle(fontSize: 15)),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('삭제'),
          style: TextButton.styleFrom(
              foregroundColor: scheme.error),
          onPressed: onDelete,
        ),
        TextButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('편집'),
          onPressed: onEdit,
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

// ── Error widget ─────────────────────────────────────────────────────────────

class _Error extends StatelessWidget {
  final String message;
  const _Error({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '오류: $message',
            style:
                TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
}
