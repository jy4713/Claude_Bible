import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/book_names.dart';
import '../../models/source_info.dart';
import '../../providers/bible_provider.dart';
import '../../providers/settings_provider.dart';
import '../../repositories/commentary_repository.dart';
import '../../widgets/html_content.dart';
import '../bible/_book_selector_dialog.dart';

class CommentaryScreen extends StatefulWidget {
  const CommentaryScreen({super.key});

  @override
  State<CommentaryScreen> createState() => CommentaryScreenState();
}

class CommentaryScreenState extends State<CommentaryScreen> {
  List<CommentaryEntry> _entries = [];
  SourceInfo? _source;
  bool _loading = false;
  bool _initialized = false;

  int _book    = 1;
  int _chapter = 1;
  int _verse   = 1;

  // Keys per verse-entry for scrolling
  final Map<int, GlobalKey> _entryKeys = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final bible = Provider.of<BibleProvider>(context, listen: false);
      _book    = bible.book;
      _chapter = bible.chapter;
      _verse   = bible.verse;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    }
  }

  /// Called when the Commentary tab is (re)selected: jump to the Bible's
  /// current position including verse.
  void syncToBible() {
    final bible = Provider.of<BibleProvider>(context, listen: false);
    final sameLocation = _book == bible.book &&
        _chapter == bible.chapter &&
        _verse == bible.verse &&
        _entries.isNotEmpty;
    if (sameLocation) {
      _scrollToVerse(_verse);
      return;
    }
    setState(() {
      _book    = bible.book;
      _chapter = bible.chapter;
      _verse   = bible.verse;
    });
    _reload().then((_) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToVerse(_verse));
    });
  }

  void _scrollToVerse(int verse) {
    if (_entries.isEmpty) return;
    // Find the last entry whose verse number is <= target (entries are sorted asc).
    // This gives the commentary section that covers the target verse.
    CommentaryEntry? best;
    for (final e in _entries) {
      if (e.verse <= verse) {
        best = e;
      } else {
        break; // entries are ascending; first entry past target, stop
      }
    }
    best ??= _entries.first;

    final key = _entryKeys[best.verse];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.0,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void _navigate(int book, int chapter, {int verse = 1}) {
    setState(() {
      _book    = book;
      _chapter = chapter;
      _verse   = verse;
    });
    _reload().then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToVerse(_verse));
      }
    });
  }

  void _prev() {
    if (_chapter > 1) {
      _navigate(_book, _chapter - 1);
    } else if (_book > 1) {
      final info = bookInfoOf(_book - 1);
      _navigate(info.number, info.chapters);
    }
  }

  void _next() {
    final info = bookInfoOf(_book);
    if (_chapter < info.chapters) {
      _navigate(_book, _chapter + 1);
    } else if (_book < 66) {
      _navigate(_book + 1, 1);
    }
  }

  Future<void> _selectBook() async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => BookSelectorDialog(
        currentBook: _book,
        currentChapter: _chapter,
        currentVerse: _verse,
      ),
    );
    if (result != null && mounted) {
      _navigate(
        result['book']!,
        result['chapter']!,
        verse: result['verse'] ?? 1,
      );
    }
  }

  Future<void> _reload() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final sources = settings.enabledCommentaries;
    if (sources.isEmpty) {
      setState(() => _entries = []);
      return;
    }
    var src = _source;
    if (src == null || !sources.any((s) => s.id == src!.id)) {
      src = sources.first;
      _source = src;
    }
    _entryKeys.clear();
    setState(() => _loading = true);
    try {
      final entries = await CommentaryRepository.instance
          .getChapter(src, _book, _chapter);
      if (mounted) setState(() => _entries = entries);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchSource(SourceInfo src) {
    setState(() => _source = src);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final sources  = settings.enabledCommentaries;
    final fontSize = settings.fontSize;
    final t        = settings.t;

    final bookInfo     = bookInfoOf(_book);
    final chapterLabel = '${bookInfo.korean} ${t.chapter(_chapter)}';

    if (sources.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(t.noCommentaryEnabled, textAlign: TextAlign.center),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TextButton(
                onPressed: _selectBook,
                style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8)),
                child: Text(
                  t.commentaryTitle(chapterLabel),
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
              onPressed: _prev,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: t.nextChapter,
              onPressed: _next,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: t.goToBibleLocation,
            onPressed: syncToBible,
          ),
          if (sources.length > 1)
            PopupMenuButton<SourceInfo>(
              initialValue: _source,
              onSelected: _switchSource,
              itemBuilder: (_) => sources
                  .map((s) =>
                      PopupMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_source?.name ?? ''),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Text(
                    t.noCommentary,
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.outline),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < _entries.length; i++) ...[
                        Builder(builder: (ctx) {
                          final e = _entries[i];
                          final key = _entryKeys.putIfAbsent(
                              e.verse, () => GlobalKey());
                          return Column(
                            key: key,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.verse}${settings.t.isEn ? '' : '절'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  fontSize: fontSize * 0.9,
                                ),
                              ),
                              const SizedBox(height: 4),
                              HtmlContent(
                                  html: e.html, fontSize: fontSize * 0.9),
                            ],
                          );
                        }),
                        if (i < _entries.length - 1) const Divider(),
                      ],
                    ],
                  ),
                ),
    );
  }
}
