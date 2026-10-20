import 'package:flutter/material.dart';

import '../components/index.dart';
import '../theme/app_theme.dart';
import 'battle/battle_screen.dart';
import 'book/book_screen.dart';
import 'edit/add_edit_move_screen.dart';
import 'home/add_note_sheet.dart';
import 'home/home_screen.dart';
import 'library/library_screen.dart';
import 'sets/set_builder_screen.dart';

/// Root shell: the four tabs, with the floating bar drawn over them so content
/// scrolls underneath it. Stats is reached from the top bar instead.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Opens on the Library, not the first tab, so the app never lands on a
  // coming soon page.
  int _index = 1;

  static const List<BrkTab> _tabs = [
    (
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
      supportsAdd: true,
    ),
    (
      icon: Icons.style_outlined,
      selectedIcon: Icons.style,
      label: 'Library',
      supportsAdd: true,
    ),
    (
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events,
      label: 'Battle',
      supportsAdd: false,
    ),
    (
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      label: 'Book',
      supportsAdd: false,
    ),
  ];

  Future<void> _openAddSheet() async {
    // Index 0 is Home, whose only add is a note; the library keeps moves and sets.
    if (_index == 0) {
      await _openNoteAdd();
      return;
    }
    final choice = await showBrkSheet<String>(
      context: context,
      builder: (ctx) => BrkSheet(
        title: 'Add',
        child: BrkSheetOptions(
          children: [
            BrkOptionTile(
              title: 'Add move',
              subtitle: 'Log a move into your vocabulary',
              icon: Icons.add_circle_outline,
              onTap: () => Navigator.of(ctx).pop('move'),
            ),
            BrkOptionTile(
              title: 'New set',
              subtitle: 'Group moves into a routine',
              icon: Icons.queue_music_outlined,
              onTap: () => Navigator.of(ctx).pop('set'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    switch (choice) {
      case 'move':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditMoveScreen()),
        );
      case 'set':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SetBuilderScreen()),
        );
      case null:
        break;
    }
  }

  Future<void> _openNoteAdd() async {
    final choice = await showBrkSheet<String>(
      context: context,
      builder: (ctx) => BrkSheet(
        title: 'Add',
        child: BrkSheetOptions(
          children: [
            BrkOptionTile(
              title: 'Add note',
              subtitle: "Write today's journal entry",
              icon: Icons.edit_note,
              onTap: () => Navigator.of(ctx).pop('note'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || choice != 'note') return;
    await showNoteSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              LibraryScreen(),
              BattleScreen(),
              BookScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: BrkTabBar(
                  tabs: _tabs,
                  currentIndex: _index,
                  onChanged: (i) => setState(() => _index = i),
                  onAdd: _tabs[_index].supportsAdd ? _openAddSheet : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
