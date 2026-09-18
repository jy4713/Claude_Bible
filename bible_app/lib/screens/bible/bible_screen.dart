import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/book_names.dart';
import '../../models/note.dart';
import '../../models/source_info.dart';
import '../../models/verse.dart';
import '../../providers/bible_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/settings_provider.dart';
import '../../repositories/bible_repository.dart';
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

  Future<void> _selectChapter(BibleProvider bible, List<SourceInfo> sources) async {
    final notes = context.read<NoteProvider>();
    final book  = bookInfoOf(bible.book);
    final result = await showChapterSelector(
      context,
      book: book,
      currentChapter: bible.chapter,
      currentVerse: bible.verse,
    );
    if (result != null && mounted) {
      final chapter = result['chapter']!;
      final verse   = result['verse'] ?? 1;
      await bible.navigate(sources, bible.book, chapter, verseIndex: verse - 1);
      notes.loadForChapter(bible.book, chapter);
    }
  }

  Future<void> _selectVerse(BibleProvider bible, List<SourceInfo> sources) async {
    final notes    = context.read<NoteProvider>();
    final settings = context.read<SettingsProvider>();
    final book     = bookInfoOf(bible.book);
    int verseCount = 176;
    try {
      final srcs = settings.enabledBibles;
      if (srcs.isNotEmpty) {
        verseCount = await BibleRepository.instance
            .maxVerse(srcs.first, bible.book, bible.chapter);
      }
    } catch (_) {}
    if (!mounted) return;
    final result = await showVerseSelector(
      context,
      book: book,
      chapter: bible.chapter,
      currentVerse: bible.verse,
      verseCount: verseCount,
    );
    if (result != null && mounted) {
      final verse = result['verse'] ?? 1;
      await bible.navigate(sources, bible.book, bible.chapter,
          verseIndex: verse - 1);
      notes.loadForChapter(bible.book, bible.chapter);
    }
  }

  // Single translation selector — only changes primaryId, never affects compareIds
  Future<void> _selectTranslation(List<SourceInfo> sources) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TranslationSelector(
        allSources: sources,
        compareMode: false,
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
        bible.setSingleId(sources.first.id, sources);
      });
    }

    final primarySrc  = _srcById(sources, bible.primaryId);
    final translName  = primarySrc?.name ?? bible.primaryId;
    final bookLabel   = '${bookInfo.korean} / ${bookInfo.english}';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        titleSpacing: 4,
        title: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line 1: translation · book (Korean / English)
            Row(
              children: [
                _NavChip(
                  label: translName,
                  onTap: () => _selectTranslation(sources),
                ),
                const _NavSep(),
                Flexible(
                  child: _NavChip(
                    label: bookLabel,
                    onTap: () => _selectBook(bible, sources),
                  ),
                ),
              ],
            ),
            // Line 2: chapter · verse  ◀ ▶
            Row(
              children: [
                _NavChip(
                  label: t.chapter(bible.chapter),
                  onTap: () => _selectChapter(bible, sources),
                ),
                const _NavSep(),
                _NavChip(
                  label: t.verse(bible.verse),
                  onTap: () => _selectVerse(bible, sources),
                ),
                const SizedBox(width: 4),
                _SmallChevron(
                  icon: Icons.chevron_left,
                  tooltip: t.prevChapter,
                  onPressed: () => _prevChapter(bible, sources),
                ),
                _SmallChevron(
                  icon: Icons.chevron_right,
                  tooltip: t.nextChapter,
                  onPressed: () => _nextChapter(bible, sources),
                ),
              ],
            ),
          ],
        ),
        ),
        actions: [
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
      body: MediaQuery(
        // Bible content uses explicit fontSize from settings — don't double-scale.
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: bible.loading
          ? const Center(child: CircularProgressIndicator())
          : bible.error != null
              ? _Error(message: bible.error!)
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
  int  _lastVerseIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastBook        = widget.bible.book;
    _lastChapter     = widget.bible.chapter;
    _lastVerseIndex  = widget.bible.verseIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerse());
  }

  @override
  void didUpdateWidget(covariant _SingleView old) {
    super.didUpdateWidget(old);
    final bookOrChapterChanged =
        widget.bible.book != _lastBook || widget.bible.chapter != _lastChapter;

    if (bookOrChapterChanged) {
      _lastBook        = widget.bible.book;
      _lastChapter     = widget.bible.chapter;
      _lastVerseIndex  = widget.bible.verseIndex;
      _verseKeys.clear();
      setState(() {
        _selectedVerses = {};
        _selectionMode = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerse());
    } else if (widget.bible.verseIndex != _lastVerseIndex) {
      _lastVerseIndex = widget.bible.verseIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerse());
    }
  }

  void _scrollToVerse() {
    final idx = widget.bible.verseIndex;
    if (idx <= 0) {
      // Verse 1: scroll to top
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      return;
    }
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
        ListView(
          controller: widget.scrollController,
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, _selectionMode ? 72 : 8),
          children: [
            for (final v in verses)
              _VerseItem(
                key: _verseKeys.putIfAbsent(v.verse, () => GlobalKey()),
                verse: v,
                fontSize: widget.fontSize,
                hasNote: widget.notes.hasNote(v.verse),
                isSelected: _selectedVerses.contains(v.verse),
                selectionMode: _selectionMode,
                onTap: () => _onVerseTap(v),
                onLongPress: () => _onVerseLongPress(v),
              ),
          ],
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

// ── AppBar nav chip ──────────────────────────────────────────────────────────

class _NavChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

class _NavSep extends StatelessWidget {
  const _NavSep();
  @override
  Widget build(BuildContext context) => Text(
        ' / ',
        style: TextStyle(
          color: Theme.of(context).colorScheme.outline,
          fontSize: 12,
        ),
      );
}

class _SmallChevron extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _SmallChevron({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon),
        iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      );
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
