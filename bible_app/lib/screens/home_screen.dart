import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import 'bible/bible_screen.dart';
import 'commentary/commentary_screen.dart';
import 'hymn/hymn_list_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _icons  = [
    Icons.menu_book_outlined,
    Icons.music_note_outlined,
    Icons.comment_outlined,
    Icons.settings_outlined,
  ];
  static const _selectedIcons = [
    Icons.menu_book,
    Icons.music_note,
    Icons.comment,
    Icons.settings,
  ];

  final _commentaryKey = GlobalKey<CommentaryScreenState>();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const BibleScreen(),
      const HymnListScreen(),
      CommentaryScreen(key: _commentaryKey),
      const SettingsScreen(),
    ];
  }

  void _onSelect(int i) {
    setState(() => _index = i);
    // When entering the commentary tab, jump to the Bible's current location.
    if (i == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _commentaryKey.currentState?.syncToBible();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<SettingsProvider>().t;
    final labels = [t.bible, t.hymns, t.commentary, t.settings];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onSelect,
        destinations: [
          for (int i = 0; i < labels.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_selectedIcons[i]),
              label: labels[i],
            ),
        ],
      ),
    );
  }
}
