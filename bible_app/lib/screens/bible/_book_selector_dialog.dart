import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/book_names.dart';
import '../../providers/settings_provider.dart';

/// Dialog that lets the user pick: OT/NT → Book → Chapter → Verse.
/// Returns {'book': int, 'chapter': int, 'verse': int}.
class BookSelectorDialog extends StatefulWidget {
  final int currentBook;
  final int currentChapter;
  final int currentVerse;

  const BookSelectorDialog({
    super.key,
    required this.currentBook,
    required this.currentChapter,
    this.currentVerse = 1,
  });

  @override
  State<BookSelectorDialog> createState() => _BookSelectorDialogState();
}

class _BookSelectorDialogState extends State<BookSelectorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int? _selectedBook;

  @override
  void initState() {
    super.initState();
    final isOT = widget.currentBook <= 39;
    _tab = TabController(length: 2, vsync: this, initialIndex: isOT ? 0 : 1);
    _selectedBook = widget.currentBook;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<BookInfo> get otBooks => bibleBooks.where((b) => b.isOT).toList();
  List<BookInfo> get ntBooks => bibleBooks.where((b) => !b.isOT).toList();

  Widget _bookList(List<BookInfo> books) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (_, i) {
        final b = books[i];
        final selected = b.number == _selectedBook;
        return ListTile(
          selected: selected,
          leading: Text('${b.number}'),
          title: Text(b.korean),
          trailing: Text(b.english,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          onTap: () => _showChapters(b),
        );
      },
    );
  }

  Future<void> _showChapters(BookInfo book) async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => _ChapterDialog(
        book: book,
        currentChapter: widget.currentChapter,
        currentVerse: widget.currentVerse,
      ),
    );
    if (result != null && mounted) {
      Navigator.pop(context, {
        'book': book.number,
        'chapter': result['chapter']!,
        'verse': result['verse'] ?? 1,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tab,
            tabs: [
              Tab(text: context.watch<SettingsProvider>().t.oldTestament),
              Tab(text: context.watch<SettingsProvider>().t.newTestament),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tab,
              children: [_bookList(otBooks), _bookList(ntBooks)],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chapter dialog ───────────────────────────────────────────────────────────

class _ChapterDialog extends StatelessWidget {
  final BookInfo book;
  final int currentChapter;
  final int currentVerse;

  const _ChapterDialog({
    required this.book,
    required this.currentChapter,
    required this.currentVerse,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.65;
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(book.korean,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 0),
            Flexible(
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: book.chapters,
                  itemBuilder: (_, i) {
                    final ch = i + 1;
                    final selected = ch == currentChapter;
                    return InkWell(
                      onTap: () async {
                        final result = await showDialog<Map<String, int>>(
                          context: context,
                          builder: (_) => _VerseDialog(
                            book: book,
                            chapter: ch,
                            currentVerse:
                                ch == currentChapter ? currentVerse : 1,
                          ),
                        );
                        if (result != null && context.mounted) {
                          Navigator.pop(context, result);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$ch',
                          style: TextStyle(
                            color: selected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                            fontWeight:
                                selected ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Verse dialog ─────────────────────────────────────────────────────────────

class _VerseDialog extends StatelessWidget {
  final BookInfo book;
  final int chapter;
  final int currentVerse;

  const _VerseDialog({
    required this.book,
    required this.chapter,
    required this.currentVerse,
  });

  static const int _maxVerses = 176; // Psalm 119 has most (176 verses)

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.65;
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${book.korean} $chapter장',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text('절을 선택하세요',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Divider(height: 0),
            // "처음 절로" quick button
            ListTile(
              leading: const Icon(Icons.first_page),
              title: const Text('장 처음으로 이동'),
              dense: true,
              onTap: () => Navigator.pop(context, {'chapter': chapter, 'verse': 1}),
            ),
            const Divider(height: 0),
            Flexible(
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _maxVerses,
                  itemBuilder: (_, i) {
                    final v = i + 1;
                    final selected = v == currentVerse;
                    return InkWell(
                      onTap: () => Navigator.pop(
                          context, {'chapter': chapter, 'verse': v}),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$v',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                            fontWeight:
                                selected ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
