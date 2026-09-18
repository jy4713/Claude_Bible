import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hymn_entry.dart';
import '../../models/source_info.dart';
import '../../providers/settings_provider.dart';
import '../../repositories/hymn_repository.dart';
import 'hymn_detail_screen.dart';

class HymnListScreen extends StatefulWidget {
  const HymnListScreen({super.key});

  @override
  State<HymnListScreen> createState() => _HymnListScreenState();
}

class _HymnListScreenState extends State<HymnListScreen> {
  List<HymnEntry> _allHymns  = [];
  List<HymnEntry> _filtered  = [];
  SourceInfo? _source;
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = context.read<SettingsProvider>();
    final hymns    = settings.enabledHymns;
    if (hymns.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    _source = hymns.first;
    try {
      final list = await HymnRepository.instance.getAllHymns(_source!);
      if (mounted) {
        setState(() {
          _allHymns = list;
          _filtered = list;
          _loading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter(String q) {
    final lq = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allHymns
          : _allHymns
              .where((h) =>
                  h.title.toLowerCase().contains(lq) ||
                  h.chapter.toString().contains(lq))
              .toList();
    });
  }

  void _openHymn(int chapter) {
    if (_source == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HymnDetailScreen(
          source: _source!,
          initialChapter: chapter,
          allHymns: _allHymns,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final t = settings.t;
    if (settings.enabledHymns.isEmpty) {
      return Center(child: Text(t.noEnabledHymn));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t.hymns),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: t.searchHymnHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _filter('');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24)),
                filled: true,
              ),
              onChanged: _filter,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? Center(child: Text(t.noResult))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _HymnCard(
                    hymn: _filtered[i],
                    onTap: () => _openHymn(_filtered[i].chapter),
                  ),
                ),
    );
  }
}

class _HymnCard extends StatelessWidget {
  final HymnEntry hymn;
  final VoidCallback onTap;

  const _HymnCard({required this.hymn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${hymn.chapter}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              hymn.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
