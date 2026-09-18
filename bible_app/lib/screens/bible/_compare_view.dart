import 'package:flutter/material.dart';

import '../../models/source_info.dart';
import '../../providers/bible_provider.dart';

/// Translation label colors — one per translation slot.
const _kLabelColors = [
  Color(0xFFE53935), // red   – slot 1
  Color(0xFFF57C00), // amber – slot 2
  Color(0xFF1565C0), // blue  – slot 3
  Color(0xFF2E7D32), // green – slot 4
];

/// Stateful compare view — renders all selectedIds.
class CompareView extends StatefulWidget {
  final BibleProvider bible;
  final List<SourceInfo> sources;
  final double fontSize;

  const CompareView({
    super.key,
    required this.bible,
    required this.sources,
    required this.fontSize,
  });

  @override
  State<CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<CompareView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  // Track navVerseIndex (navigation target only) — not affected by scroll tracking.
  int _lastNavVerseIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastNavVerseIndex = widget.bible.navVerseIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerse());
  }

  @override
  void didUpdateWidget(covariant CompareView old) {
    super.didUpdateWidget(old);
    final bookOrChapterChanged =
        widget.bible.book != old.bible.book ||
        widget.bible.chapter != old.bible.chapter;
    if (bookOrChapterChanged) {
      _verseKeys.clear();
      _lastNavVerseIndex = widget.bible.navVerseIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerse());
    } else if (widget.bible.navVerseIndex != _lastNavVerseIndex) {
      _lastNavVerseIndex = widget.bible.navVerseIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerse());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToVerse() {
    if (!mounted) return;
    final idx = widget.bible.navVerseIndex;
    if (idx <= 0) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
      return;
    }
    final ids = widget.bible.selectedIds;
    if (ids.isEmpty) return;
    final verses = widget.bible.versesFor(ids.first);
    if (idx >= verses.length) return;
    final vNum = verses[idx].verse;
    final key = _verseKeys[vNum];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.0,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
        scrollController: _scrollController,
        verseKeys: _verseKeys,
      );
    }

    return _StackedView(
      ids: ids,
      nameFor: _nameFor,
      bible: widget.bible,
      fontSize: widget.fontSize,
      scrollController: _scrollController,
      verseKeys: _verseKeys,
    );
  }
}

// ── Stacked per-verse view (세로) ────────────────────────────────────────────

class _StackedView extends StatelessWidget {
  final List<String> ids;
  final String Function(String) nameFor;
  final BibleProvider bible;
  final double fontSize;
  final ScrollController scrollController;
  final Map<int, GlobalKey> verseKeys;

  const _StackedView({
    required this.ids,
    required this.nameFor,
    required this.bible,
    required this.fontSize,
    required this.scrollController,
    required this.verseKeys,
  });

  Widget _buildVerseRow(BuildContext context, int vn,
      Map<String, Map<int, String>> maps, ColorScheme scheme) {
    final key = verseKeys.putIfAbsent(vn, () => GlobalKey());
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$vn',
              style: TextStyle(
                fontSize: fontSize * 0.8,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < ids.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '[${nameFor(ids[i])}] ',
                          style: TextStyle(
                            color: _kLabelColors[i % _kLabelColors.length],
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize * 0.85,
                          ),
                        ),
                        TextSpan(
                          text: maps[ids[i]]?[vn] ?? '',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: fontSize,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final rows = <Widget>[];
    for (int r = 0; r < sortedNums.length; r++) {
      if (r > 0) rows.add(const Divider(height: 1, indent: 32));
      rows.add(_buildVerseRow(context, sortedNums[r], maps, scheme));
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(children: rows),
    );
  }
}

// ── Side-by-side aligned table (나란히) ──────────────────────────────────────

class _AlignedTable extends StatelessWidget {
  final List<String> ids;
  final String Function(String) nameFor;
  final BibleProvider bible;
  final double fontSize;
  final ScrollController scrollController;
  final Map<int, GlobalKey> verseKeys;

  const _AlignedTable({
    required this.ids,
    required this.nameFor,
    required this.bible,
    required this.fontSize,
    required this.scrollController,
    required this.verseKeys,
  });

  Widget _buildVerseRow(BuildContext context, int vn,
      Map<String, Map<int, String>> maps, ColorScheme scheme) {
    final key = verseKeys.putIfAbsent(vn, () => GlobalKey());
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
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
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '[${nameFor(ids[i])}] ',
                    style: TextStyle(
                      color: _kLabelColors[i % _kLabelColors.length],
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize * 0.8,
                    ),
                  ),
                  TextSpan(
                    text: maps[ids[i]]?[vn] ?? '',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: fontSize,
                      height: 1.5,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final rows = <Widget>[];
    for (int r = 0; r < sortedNums.length; r++) {
      if (r > 0) rows.add(const Divider(height: 1, indent: 32));
      rows.add(_buildVerseRow(context, sortedNums[r], maps, scheme));
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: rows),
    );
  }
}
