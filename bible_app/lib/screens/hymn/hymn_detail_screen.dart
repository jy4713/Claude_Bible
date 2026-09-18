import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hymn_entry.dart';
import '../../models/source_info.dart';
import '../../providers/settings_provider.dart';
import '../../repositories/hymn_repository.dart';
import '../../widgets/html_content.dart';

class HymnDetailScreen extends StatefulWidget {
  final SourceInfo source;
  final int initialChapter;
  final List<HymnEntry> allHymns;

  const HymnDetailScreen({
    super.key,
    required this.source,
    required this.initialChapter,
    required this.allHymns,
  });

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late TabController  _tabController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.allHymns
        .indexWhere((h) => h.chapter == widget.initialChapter)
        .clamp(0, widget.allHymns.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _tabController  = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  HymnEntry get current => widget.allHymns[_currentIndex];

  void _prev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _next() {
    if (_currentIndex < widget.allHymns.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<SettingsProvider>().t;
    return Scaffold(
      appBar: AppBar(
        title: Text('${current.chapter}${t.isEn ? '' : '장'}  ${current.title}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.image_outlined), text: t.sheetMusic),
            Tab(icon: const Icon(Icons.lyrics_outlined), text: t.lyrics),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Sheet music image ──
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.allHymns.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (_, i) => _SheetMusicPage(
                    source: widget.source,
                    chapter: widget.allHymns[i].chapter,
                  ),
                ),
                // ── Lyrics ──
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.allHymns.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (_, i) =>
                      _LyricsPage(hymn: widget.allHymns[i]),
                ),
              ],
            ),
          ),
          // Bottom nav bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton.outlined(
                    onPressed: _currentIndex > 0 ? _prev : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${current.chapter}장',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: _currentIndex < widget.allHymns.length - 1
                        ? _next
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetMusicPage extends StatefulWidget {
  final SourceInfo source;
  final int chapter;
  const _SheetMusicPage({required this.source, required this.chapter});

  @override
  State<_SheetMusicPage> createState() => _SheetMusicPageState();
}

class _SheetMusicPageState extends State<_SheetMusicPage> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_SheetMusicPage old) {
    super.didUpdateWidget(old);
    if (old.chapter != widget.chapter) _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _loading = true;
      _bytes   = null;
    });
    final bytes =
        await HymnRepository.instance.getHymnImage(widget.source, widget.chapter);
    if (mounted) {
      setState(() {
        _bytes   = bytes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_bytes == null) {
      return Center(
          child: Text(context.watch<SettingsProvider>().t.cannotLoadImage));
    }
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.memory(_bytes!, fit: BoxFit.contain),
      ),
    );
  }
}

class _LyricsPage extends StatelessWidget {
  final HymnEntry hymn;
  const _LyricsPage({required this.hymn});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${hymn.chapter}. ${hymn.title}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          HtmlContent(html: hymn.text, fontSize: 15),
        ],
      ),
    );
  }
}
