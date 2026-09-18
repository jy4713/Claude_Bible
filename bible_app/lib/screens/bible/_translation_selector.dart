import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/source_info.dart';
import '../../providers/bible_provider.dart';
import '../../providers/settings_provider.dart';

/// Bottom-sheet for choosing translations and compare settings.
/// Uses [StatefulWidget] + explicit [Consumer] so state updates are always
/// reflected even inside an overlay route.
class TranslationSelector extends StatefulWidget {
  final List<SourceInfo> allSources;

  const TranslationSelector({super.key, required this.allSources});

  @override
  State<TranslationSelector> createState() => _TranslationSelectorState();
}

class _TranslationSelectorState extends State<TranslationSelector> {
  void _onTap(BibleProvider bible, List<String> selected, bool compare, String id) {
    final current = List<String>.from(selected);
    if (compare) {
      if (current.contains(id)) {
        if (current.length > 1) current.remove(id);
      } else {
        if (current.length >= BibleProvider.maxCompare) return;
        current.add(id);
      }
    } else {
      current
        ..clear()
        ..add(id);
    }
    bible.setSelectedIds(current, widget.allSources);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BibleProvider, SettingsProvider>(
      builder: (ctx, bible, settings, _) {
        final t        = settings.t;
        final selected = bible.selectedIds;
        final compare  = bible.compareMode;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) => Column(
            children: [
              const _Handle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Text(t.selectTranslation,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const Spacer(),
                    Text(t.compare),
                    Switch(
                      value: compare,
                      onChanged: (_) => bible.toggleCompare(widget.allSources),
                    ),
                  ],
                ),
              ),
              // Mode hint + colour indicator
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: compare
                      ? Theme.of(ctx).colorScheme.primaryContainer
                      : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  compare ? t.compareHint : t.singleSelectHint,
                  style: TextStyle(
                      fontSize: 12,
                      color: compare
                          ? Theme.of(ctx).colorScheme.onPrimaryContainer
                          : Theme.of(ctx).colorScheme.outline),
                ),
              ),
              if (compare) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('${t.layout}: '),
                      ChoiceChip(
                        label: Text(t.sideBySide),
                        selected: bible.compareAxis == Axis.horizontal,
                        onSelected: (_) => bible.setCompareAxis(Axis.horizontal),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(t.topBottom),
                        selected: bible.compareAxis == Axis.vertical,
                        onSelected: (_) => bible.setCompareAxis(Axis.vertical),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: widget.allSources.length,
                  itemBuilder: (_, i) {
                    final src = widget.allSources[i];
                    final order = selected.indexOf(src.id);
                    final isSelected = order >= 0;
                    return ListTile(
                      onTap: () => _onTap(bible, selected, compare, src.id),
                      leading: _SelectionMark(
                        compare: compare,
                        selected: isSelected,
                        order: order,
                      ),
                      title: Text(src.name),
                      subtitle: isSelected && compare
                          ? Text(
                              '${order + 1}번째 선택',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(ctx).colorScheme.primary),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shows a numbered priority badge (compare mode) or a radio/check mark.
class _SelectionMark extends StatelessWidget {
  final bool compare;
  final bool selected;
  final int order; // 0-based priority

  const _SelectionMark({
    required this.compare,
    required this.selected,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (compare) {
      if (!selected) {
        return Icon(Icons.circle_outlined, color: scheme.outline);
      }
      return CircleAvatar(
        radius: 13,
        backgroundColor: scheme.primary,
        child: Text(
          '${order + 1}',
          style: TextStyle(
            color: scheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }
    // single-select → radio style
    return Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      color: selected ? scheme.primary : scheme.outline,
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}
