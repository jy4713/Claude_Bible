import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/book_names.dart';
import '../../providers/settings_provider.dart';

/// Dialog that lets the user pick: OT/NT → Book → Chapter.
class BookSelectorDialog extends StatefulWidget {
  final int currentBook;
  final int currentChapter;

  const BookSelectorDialog({
    super.key,
    required this.currentBook,
    required this.currentChapter,
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
          trailing: Text(b.english, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          onTap: () => _showChapters(b),
        );
      },
    );
  }

  Future<void> _showChapters(BookInfo book) async {
    final chapter = await showDialog<int>(
      context: context,
      builder: (_) => _ChapterDialog(book: book, currentChapter: widget.currentChapter),
    );
    if (chapter != null && mounted) {
      Navigator.pop(context, {'book': book.number, 'chapter': chapter});
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

class _ChapterDialog extends StatelessWidget {
  final BookInfo book;
  final int currentChapter;

  const _ChapterDialog({required this.book, required this.currentChapter});

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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 0),
            Flexible(
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      onTap: () => Navigator.pop(context, ch),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$ch',
                          style: TextStyle(
                            color: selected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                            fontWeight: selected ? FontWeight.bold : null,
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
