import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../theme/app_theme.dart';
import '../edit/add_edit_move_screen.dart';
import '../sets/set_builder_screen.dart';
import '../top_actions.dart';
import 'sets_tab.dart';
import 'vocabulary_tab.dart';

/// Home. One header, then the Vocabulary and Sets tabs side by side (same
/// pattern as lcchub's home). The floating control only opens the add sheet.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const BrkHeader(title: 'BreakLog', actions: [TopBarActions()]),
              Container(
                color: AppColors.surface,
                child: const TabBar(
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  indicatorColor: AppColors.accent,
                  tabs: [
                    Tab(text: 'Vocabulary'),
                    Tab(text: 'Sets'),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [VocabularyTab(), SetsTab()],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: BrkFab(
          icon: Icons.add,
          tooltip: 'Add',
          onTap: _openAddSheet,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
