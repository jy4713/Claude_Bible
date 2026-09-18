import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/book_names.dart';
import '../../models/source_info.dart';
import '../../providers/bible_provider.dart';
import '../../providers/settings_provider.dart';
import '_book_selector_dialog.dart';
import '_compare_view.dart';
import '_translation_selector.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCompareMode());
  }

  void _ensureCompareMode() {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    final bible = context.read<BibleProvider>();
    if (!bible.compareMode) {
      bible.toggleCompare(settings.enabledBibles);
    }
  }

  void _prevChapter(BibleProvider bible, List<SourceInfo> sources) {
    int book = bible.book, chapter = bible.chapter;
    if (chapter > 1) {
      chapter--;
    } else if (book > 1) {
      book--;
      chapter = bookInfoOf(book).chapters;
    }
    bible.navigate(sources, book, chapter);
  }

  void _nextChapter(BibleProvider bible, List<SourceInfo> sources) {
    final info = bookInfoOf(bible.book);
    int book = bible.book, chapter = bible.chapter;
    if (chapter < info.chapters) {
      chapter++;
    } else if (book < 66) {
      book++;
      chapter = 1;
    }
    bible.navigate(sources, book, chapter);
  }

  Future<void> _selectBook(
      BibleProvider bible, List<SourceInfo> sources) async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => BookSelectorDialog(
        currentBook: bible.book,
        currentChapter: bible.chapter,
        currentVerse: bible.verse,
      ),
    );
    if (result != null && mounted) {
      await bible.navigate(
        sources,
        result['book']!,
        result['chapter']!,
        verseIndex: (result['verse'] ?? 1) - 1,
      );
    }
  }

  Future<void> _selectTranslations(List<SourceInfo> sources) async {
    final bible = context.read<BibleProvider>();
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final bible = context.watch<BibleProvider>();
    final sources = settings.enabledBibles;
    final t = settings.t;

    final bookInfo = bookInfoOf(bible.book);
    final titleText = '${bookInfo.korean} ${t.chapter(bible.chapter)}';
    final isHorizontal = bible.compareAxis == Axis.horizontal;

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
          // 역본 선택
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: '역본 선택',
            onPressed: () => _selectTranslations(sources),
          ),
          // 세로(stacked) ↔ 나란히(side-by-side) 토글
          IconButton(
            icon: Icon(isHorizontal ? Icons.view_agenda : Icons.view_column),
            tooltip: isHorizontal ? '세로 보기' : '나란히 보기',
            onPressed: () => bible.setCompareAxis(
                isHorizontal ? Axis.vertical : Axis.horizontal),
          ),
        ],
      ),
      body: bible.loading
          ? const Center(child: CircularProgressIndicator())
          : bible.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('오류: ${bible.error}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                )
              : !bible.compareMode || bible.selectedIds.length < 2
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.compare_arrows,
                              size: 56,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline),
                          const SizedBox(height: 16),
                          const Text('역본을 2개 이상 선택하세요',
                              style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.menu_book),
                            label: const Text('역본 선택'),
                            onPressed: () => _selectTranslations(sources),
                          ),
                        ],
                      ),
                    )
                  : CompareView(
                      bible: bible,
                      sources: sources,
                      fontSize: settings.fontSize,
                    ),
    );
  }
}
