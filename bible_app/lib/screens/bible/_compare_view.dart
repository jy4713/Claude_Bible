import 'package:flutter/material.dart';

import '../../models/source_info.dart';
import '../../models/verse.dart';
import '../../providers/bible_provider.dart';

/// Stateful compare view — renders all selectedIds side-by-side or top-bottom.
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
      if (i < ids.length - 1) panels.add(const VerticalDivider(width: 1));
    }
    return Row(children: panels);
  }
}

// ── Horizontal aligned table ─────────────────────────────────────────────────

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
                          style: TextStyle(fontSize: fontSize, height: 1.5),
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

// ── Vertical panel column ────────────────────────────────────────────────────

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
                _PanelVerseItem(verse: verses[i], fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}

class _PanelVerseItem extends StatelessWidget {
  final Verse verse;
  final double fontSize;

  const _PanelVerseItem({required this.verse, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                color: scheme.primary,
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

// ── Order badge ──────────────────────────────────────────────────────────────

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

// ── Linked scroll group ──────────────────────────────────────────────────────

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
