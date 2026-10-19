import 'package:flutter/material.dart';

import '../components/index.dart';
import '../theme/app_theme.dart';
import 'edit/add_edit_move_screen.dart';
import 'library/library_screen.dart';
import 'sets/set_builder_screen.dart';
import 'stats/stats_screen.dart';

/// Root shell: the two tabs, with the floating bar drawn over them so content
/// scrolls underneath it.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const List<BrkTab> _tabs = [
    (
      icon: Icons.style_outlined,
      selectedIcon: Icons.style,
      label: 'Library',
      supportsAdd: true,
    ),
    (
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: 'Stats',
      supportsAdd: false,
    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [LibraryScreen(), StatsScreen()],
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
