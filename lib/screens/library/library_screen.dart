import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../theme/app_theme.dart';
import '../top_actions.dart';
import 'sets_tab.dart';
import 'vocabulary_tab.dart';

/// Home. One header, then the Vocabulary and Sets tabs side by side. The add
/// action lives in the shell's floating bar, not here.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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
              Builder(
                builder: (ctx) => BrkHeader(
                  title: 'Library',
                  mark: const BrkBrandMark(),
                  onMenu: () {
                    final state = ctx.findAncestorStateOfType<AppShellState>();
                    state?.toggleDrawer();
                  },
                  actions: const [TopBarActions()],
                ),
              ),
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
      ),
    );
  }
}
