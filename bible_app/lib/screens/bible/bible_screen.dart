import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/book_names.dart';
import '../../models/source_info.dart';
import '../../models/verse.dart';
import '../../providers/bible_provider.dart';
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
    final sources = settings.enabledBibles;
    if (sources.isNotEmpty) {
      bible.reload(sources);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Navigation helpers ───────────────────────────────────────────────────

  void _prevChapter(BibleProvider bible, List<SourceInfo> sources) {
    if (bible.chapter > 1) {
      bible.navigate(sources, bible.book, bible.chapter - 1);
    } else if (bible.book > 1) {
      final info = bookInfoOf(bible.book - 1);
      bible.navigate(sources, info.number, info.chapters);
    }
  }

  void _nextChapter(BibleProvider bible, List<SourceInfo> sources) {
    final info = bookInfoOf(bible.book);
    if (bible.chapter < info.chapters) {
      bible.navigate(sources, bible.book, bible.chapter + 1);
    } else if (bible.book < 66) {
      bible.navigate(sources, bible.book + 1, 1);
    }
  }

  Future<void> _selectBook(BibleProvider bible, List<SourceInfo> sources) async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => BookSelectorDialog(
        currentBook: bible.book,
        currentChapter: bible.chapter,
      ),
    );
    if (result != null && mounted) {
      bible.navigate(sources, result['book']!, result['chapter']!);
    }
  }

  Future<void> _selectTranslations(List<SourceInfo> sources) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TranslationSelector(allSources: sources),
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
    final sources  = settings.enabledBibles;
    final t        = settings.t;

    final bookInfo = bookInfoOf(bible.book);
    final fontSize = settings.fontSize;

    // Auto-recover: if primary translation was deleted, switch to first available.
    if (sources.isNotEmpty &&
        !sources.any((s) => s.id == bible.primaryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bible.setSelectedIds([sources.first.id], sources);
      });
    }

    final showCompare = bible.compareMode && bible.selectedIds.length > 1;

    // Title text: in single mode show which translation is active.
    final primarySrc = _srcById(sources, bible.primaryId);
    final english = !showCompare && (primarySrc?.isEnglish ?? false);
    final bookLabel = english
        ? '${bookInfo.korean} / ${bookInfo.english}'
        : bookInfo.korean;
    final prefix = (!showCompare && primarySrc != null)
        ? '${primarySrc.name}  '
        : '';
    final titleText = '$prefix$bookLabel ${t.chapter(bible.chapter)}';

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
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: t.translationCompareSettings,
            onPressed: () => _selectTranslations(sources),
          ),
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
                    bible.navigate(sources, book, chapter,
                        verseIndex: verse - 1);
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
                      sourceId: bible.primaryId,
                      fontSize: fontSize,
                      scrollController: _scrollController,
                      emptyText: t.noData,
                    ),
    );
  }
}

// ── Single translation view ──────────────────────────────────────────────────

class _SingleView extends StatelessWidget {
  final BibleProvider bible;
  final String sourceId;
  final double fontSize;
  final ScrollController scrollController;
  final String emptyText;

  const _SingleView({
    required this.bible,
    required this.sourceId,
    required this.fontSize,
    required this.scrollController,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final verses = bible.versesFor(sourceId);
    if (verses.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: verses.length,
      itemBuilder: (_, i) => _VerseItem(verse: verses[i], fontSize: fontSize),
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
  // Stable set of linked controllers (one per possible compare slot),
  // created once so we never dispose a controller that is still attached.
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
      // Side-by-side: one shared vertical scroll, verses aligned by number.
      return _AlignedTable(
        ids: ids,
        nameFor: _nameFor,
        bible: widget.bible,
        fontSize: widget.fontSize,
      );
    }

    // Top/bottom: stacked full-width panels with linked scrolling.
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
      if (i < ids.length - 1) panels.add(const Divider(height: 1));
    }
    return Column(children: panels);
  }
}

/// Horizontal compare rendered as one scrollable table so every panel is
/// perfectly synchronized and each verse row lines up by verse number.
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
    // Union of verse numbers across all selected translations.
    final maps = <String, Map<int, String>>{};
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
        // Sticky header
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
                padding: const EdgeInsets.symmetric(vertical: 4),
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
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            maps[ids[i]]?[vn] ?? '',
                            style:
                                TextStyle(fontSize: fontSize, height: 1.5),
                          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

/// Keeps several [ScrollController]s in sync by offset.
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
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
  }
}

// ── Verse item ───────────────────────────────────────────────────────────────

class _VerseItem extends StatelessWidget {
  final Verse verse;
  final double fontSize;

  const _VerseItem({required this.verse, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${verse.verse}',
              style: TextStyle(
                fontSize: fontSize * 0.8,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              verse.text,
              style: TextStyle(fontSize: fontSize, height: 1.6),
            ),
          ),
        ],
      ),
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
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
}
