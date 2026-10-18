import 'package:flutter/material.dart';

import '../components/index.dart';
import '../theme/app_theme.dart';
import 'edit/add_edit_move_screen.dart';
import 'sets/sets_screen.dart';
import 'vocabulary/vocabulary_screen.dart';

/// Two-tab home. The floating control is a bare icon that only opens the add
/// action sheet, so the sheet decides what "add" means.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    VocabularyScreen(),
    SetsScreen(),
  ];

  Future<void> _openAddSheet() async {
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
          ],
        ),
      ),
    );

    if (choice == 'move' && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddEditMoveScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: _index == 0
          ? BrkFab(
              icon: Icons.add,
              tooltip: 'Add',
              onTap: _openAddSheet,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BrkTabBar(
        currentIndex: _index,
        onChanged: (i) => setState(() => _index = i),
        tabs: const [
          (
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book,
            label: 'Vocabulary',
          ),
          (
            icon: Icons.queue_music_outlined,
            selectedIcon: Icons.queue_music,
            label: 'Sets',
          ),
        ],
      ),
    );
  }
}
