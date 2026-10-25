import 'package:flutter/material.dart';

import '../components/index.dart';
import '../components/brk_tab_bar.dart';
import '../theme/app_theme.dart';
import 'battle/battle_screen.dart';
import 'battle/plan_sheet.dart';
import 'battle/prep_tab.dart';
import 'book/book_screen.dart';
import 'edit/add_edit_move_screen.dart';
import 'home/add_note_sheet.dart';
import 'home/home_screen.dart';
import 'library/library_screen.dart';
import 'sets/set_builder_screen.dart';

/// Root shell with a hamburger and drawer navigation. The floating add
/// button sits in the bottom right of the screen.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int _index = 1;

  static const List<NavItem> _items = [
    NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    NavItem(
      icon: Icons.style_outlined,
      selectedIcon: Icons.style,
      label: 'Library',
    ),
    NavItem(
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events,
      label: 'Battle',
    ),
    NavItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      label: 'Book',
    ),
  ];

  Future<void> _openAddSheet() async {
    // Index 0 is Home, whose only add is a note; the library keeps moves and sets.
    if (_index == 0) {
      await _openNoteAdd();
      return;
    }
    if (_index == 2) {
      await _openBattleAdd();
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

  Future<void> _openBattleAdd() async {
    final choice = await showBrkSheet<String>(
      context: context,
      builder: (ctx) => BrkSheet(
        title: 'Add',
        child: BrkSheetOptions(
          children: [
            BrkOptionTile(
              title: 'Battle plan',
              subtitle: 'Set rounds for each stage',
              icon: Icons.emoji_events_outlined,
              onTap: () => Navigator.of(ctx).pop('plan'),
            ),
            BrkOptionTile(
              title: 'Prep item',
              subtitle: 'Something to get ready',
              icon: Icons.checklist_outlined,
              onTap: () => Navigator.of(ctx).pop('prep'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    switch (choice) {
      case 'plan':
        await showPlanSheet(context);
      case 'prep':
        await showAddPrepItem(context);
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
            children: const [
              HomeScreen(),
              LibraryScreen(),
              BattleScreen(),
              BookScreen(),
            ],
          ),

          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: BrkFab(
              icon: Icons.add,
              onTap: _openAddSheet,
              size: 60,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openDrawer(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, _, __) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.transparent),
              ),
            ),
            AnimatedMenuDrawer(
              selectedIndex: _index,
              items: _items,
              onSelect: (i) {
                Navigator.of(context).pop();
                setState(() => _index = i);
              },
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
    );
  }
}

class NavItem {
  const NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AnimatedMenuDrawer extends StatelessWidget {
  const AnimatedMenuDrawer({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelect,
  });

  final int selectedIndex;
  final List<NavItem> items;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 10;
    final left = 16.0;
    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 240,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.menu, size: 18, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(
                        'BreakLog',
                        style: context.appTextTheme.titleSmall
                            ?.copyWith(color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.outline, height: 1),
                for (var i = 0; i < items.length; i++) ...[
                  _DrawerItem(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
                ],
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 20,
              color: selected ? AppColors.accent : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: context.appTextTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.accent : AppColors.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

