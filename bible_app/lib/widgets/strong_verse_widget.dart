import 'package:flutter/material.dart';

import '../models/source_info.dart';
import '../models/verse.dart';
import '../repositories/dic_repository.dart';
import 'html_content.dart';

/// Renders bible verse text.
/// For SDB bibles (hasSdbAnnotations), annotated words are tappable and show
/// a Strong's dictionary popup.
class StrongVerseWidget extends StatelessWidget {
  final Verse verse;
  final double fontSize;
  final TextStyle? baseStyle;
  // Preferred DIC source for definition lookup (null = no lookup)
  final SourceInfo? dic;

  const StrongVerseWidget({
    super.key,
    required this.verse,
    required this.fontSize,
    this.baseStyle,
    this.dic,
  });

  @override
  Widget build(BuildContext context) {
    if (!verse.hasSdbAnnotations || dic == null) {
      return Text(
        verse.text,
        style: baseStyle ?? TextStyle(fontSize: fontSize, height: 1.6),
      );
    }
    final style = baseStyle ?? TextStyle(fontSize: fontSize, height: 1.6);
    final scheme = Theme.of(context).colorScheme;
    final taggedStyle = style.copyWith(
      color: scheme.primary,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: scheme.primary.withValues(alpha: 0.5),
    );

    // Build wrapped words
    return Wrap(
      children: verse.strongWords.map((sw) {
        final display = '${sw.word} ';
        if (!sw.hasCode) {
          return Text(display, style: style);
        }
        return GestureDetector(
          onTap: () => _showDefinition(context, sw.codes.first),
          child: Text(display, style: taggedStyle),
        );
      }).toList(),
    );
  }

  Future<void> _showDefinition(BuildContext context, String scode) async {
    if (dic == null) return;
    final entry = await DicRepository.instance.getDefinition(dic!, scode);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DicPopup(entry: entry, scode: scode),
    );
  }
}

class _DicPopup extends StatelessWidget {
  final DicEntry? entry;
  final String scode;

  const _DicPopup({required this.entry, required this.scode});

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final padding = MediaQuery.of(context).viewInsets.bottom + 16;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    scode,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (entry != null)
                  Expanded(
                    child: Text(
                      entry!.original,
                      style: TextStyle(
                        fontSize: 20,
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (entry == null)
                  Text('정의를 찾을 수 없습니다',
                      style: TextStyle(color: scheme.outline)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Definition body
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: EdgeInsets.fromLTRB(16, 12, 16, padding),
              children: [
                if (entry != null)
                  HtmlContent(html: entry!.definition, fontSize: 15)
                else
                  Text(
                    'Strong\'s $scode에 대한 정의를 찾을 수 없습니다.',
                    style: TextStyle(color: scheme.outline),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
