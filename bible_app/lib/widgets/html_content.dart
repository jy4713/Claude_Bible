import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Renders a small subset of HTML used in commentary and hymn texts:
///   <b>, <strong>, <i>, <em>, <br>, <font color="...">, and plain text.
class HtmlContent extends StatelessWidget {
  final String html;
  final double fontSize;

  const HtmlContent({super.key, required this.html, this.fontSize = 14.0});

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      height: 1.6,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final doc = html_parser.parseFragment(html);
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: doc.nodes.map((n) => _node(n, baseStyle)).toList(),
      ),
    );
  }

  TextSpan _node(dom.Node node, TextStyle style) {
    if (node is dom.Text) {
      return TextSpan(text: node.text, style: style);
    }
    if (node is dom.Element) {
      TextStyle s = style;
      switch (node.localName) {
        case 'b':
        case 'strong':
          s = s.copyWith(fontWeight: FontWeight.bold);
          break;
        case 'i':
        case 'em':
          s = s.copyWith(fontStyle: FontStyle.italic);
          break;
        case 'font':
          final colorHex = node.attributes['color'];
          if (colorHex != null) {
            final c = _parseColor(colorHex);
            if (c != null) s = s.copyWith(color: c);
          }
          break;
        case 'br':
          return const TextSpan(text: '\n');
      }
      final children = node.nodes.map((n) => _node(n, s)).toList();
      return TextSpan(style: s, children: children);
    }
    return const TextSpan();
  }

  static Color? _parseColor(String hex) {
    try {
      var h = hex.trim().replaceFirst('#', '');
      if (h.length == 3) {
        h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
      }
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return null;
    }
  }
}
