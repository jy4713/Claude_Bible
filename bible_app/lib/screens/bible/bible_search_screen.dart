import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/book_names.dart';
import '../../models/source_info.dart';
import '../../models/verse.dart';
import '../../providers/settings_provider.dart';
import '../../repositories/bible_repository.dart';

class BibleSearchScreen extends StatefulWidget {
  final List<SourceInfo> sources;
  final int currentBook;
  final double fontSize;
  final void Function(int book, int chapter, int verse) onNavigate;

  const BibleSearchScreen({
    super.key,
    required this.sources,
    required this.currentBook,
    required this.fontSize,
    required this.onNavigate,
  });

  @override
  State<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();

  bool _searchCurrentBook = false;
  String _selectedSourceId = '';
  List<Verse> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sources.isNotEmpty) {
      _selectedSourceId = widget.sources.first.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final src = widget.sources.firstWhere((s) => s.id == _selectedSourceId,
          orElse: () => widget.sources.first);
      final results = await BibleRepository.instance.search(
        src,
        query,
        book: _searchCurrentBook ? widget.currentBook : null,
      );
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<SettingsProvider>().t;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: t.searchWordHint,
            border: InputBorder.none,
          ),
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_controller.text),
          ),
        ],
      ),
      body: Column(
        children: [
          // Options bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Translation picker
                DropdownButton<String>(
                  value: _selectedSourceId.isEmpty ? null : _selectedSourceId,
                  hint: Text(t.translationLabel),
                  items: widget.sources
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (id) {
                    if (id != null) {
                      setState(() => _selectedSourceId = id);
                      if (_controller.text.isNotEmpty) _search(_controller.text);
                    }
                  },
                ),
                const Spacer(),
                // Limit to current book
                Row(
                  children: [
                    Checkbox(
                      value: _searchCurrentBook,
                      onChanged: (v) {
                        setState(() => _searchCurrentBook = v!);
                        if (_controller.text.isNotEmpty) _search(_controller.text);
                      },
                    ),
                    Text(
                      t.onlyBook(bookInfoOf(widget.currentBook).korean),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Result count
          if (_results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.resultsCount(_results.length),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          const Divider(height: 0),
          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _controller.text.isEmpty ? t.enterSearch : t.noResult,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.outline),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (_, i) => _ResultTile(
                          verse: _results[i],
                          query: _controller.text,
                          fontSize: widget.fontSize,
                          onTap: () => widget.onNavigate(
                            _results[i].book,
                            _results[i].chapter,
                            _results[i].verse,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Verse verse;
  final String query;
  final double fontSize;
  final VoidCallback onTap;

  const _ResultTile({
    required this.verse,
    required this.query,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final book = bookInfoOf(verse.book);
    final ref  = '${book.korean} ${verse.chapter}:${verse.verse}';

    // Highlight the search term in the text
    final lc   = verse.text.toLowerCase();
    final lcq  = query.toLowerCase();
    final idx  = lc.indexOf(lcq);

    TextSpan body;
    if (idx >= 0 && query.isNotEmpty) {
      body = TextSpan(children: [
        TextSpan(text: verse.text.substring(0, idx)),
        TextSpan(
          text: verse.text.substring(idx, idx + query.length),
          style: TextStyle(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(text: verse.text.substring(idx + query.length)),
      ]);
    } else {
      body = TextSpan(text: verse.text);
    }

    return ListTile(
      onTap: onTap,
      title: Text.rich(
        body,
        style: TextStyle(fontSize: fontSize),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(ref,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          )),
    );
  }
}
