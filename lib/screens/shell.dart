import 'package:flutter/material.dart';

import '../components/brk_tab_bar.dart';
import '../components/index.dart';
import '../theme/app_theme.dart';
import 'battle/battle_screen.dart';
import 'battle/plan_sheet.dart';
import 'battle/prep_tab.dart';
import 'book/book_screen.dart';
import 'crew/crew_screen.dart';
import 'edit/add_edit_move_screen.dart';
import 'home/add_note_sheet.dart';
import 'home/home_screen.dart';
import 'library/library_screen.dart';
import 'sets/set_builder_screen.dart';

/// Root shell with a slide-out navigation drawer. The add button stays
/// at the bottom right.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _index = 1;
  bool _drawerOpen = false;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _animation =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  static const double _drawerWidth = 280;
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
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: 'Crew',
    ),
    NavItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      label: 'Book',
    ),
  ];

  void toggleDrawer() {
    setState(() {
      _drawerOpen = !_drawerOpen;
      if (_drawerOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void openDrawer() {
    if (_drawerOpen) return;
    setState(() {
      _drawerOpen = true;
      _controller.forward();
    });
  }

  void closeDrawer() {
    if (!_drawerOpen) return;
    setState(() {
      _drawerOpen = false;
      _controller.reverse();
    });
  }

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final offset = _drawerWidth * _animation.value;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: Stack(
                  children: [
                    IndexedStack(
                      index: _index,
                      children: const [
                        HomeScreen(),
                        LibraryScreen(),
                        BattleScreen(),
                        CrewScreen(),
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
                    if (_drawerOpen)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: closeDrawer,
                          child: Container(
                            color: Colors.black
                                .withValues(alpha: 0.4 * _animation.value),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final translateX = -_drawerWidth + (_drawerWidth * _animation.value);
              return Transform.translate(
                offset: Offset(translateX, 0),
                child: SafeArea(
                  child: Container(
                    width: _drawerWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: const Border(
                        right: BorderSide(color: AppColors.outline),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                          child: Row(
                            children: [
                              const Icon(Icons.menu,
                                  size: 18, color: AppColors.onSurfaceVariant),
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
                        const SizedBox(height: 6),
                        for (var i = 0; i < _items.length; i++) ...[
                          _DrawerItem(
                            item: _items[i],
                            selected: i == _index,
                            onTap: () {
                              setState(() => _index = i);
                              closeDrawer();
                            },
                          ),
                        ],
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
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

