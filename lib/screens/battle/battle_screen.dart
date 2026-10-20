import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../theme/app_theme.dart';
import '../top_actions.dart';

/// Battle planning. The tab bar is scaffolded with Plan as the first tab; the
/// content is not built yet.
class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const BrkHeader(
                title: 'Battle',
                mark: BrkBrandMark(),
                actions: [TopBarActions()],
              ),
              Container(
                color: AppColors.surface,
                child: const TabBar(
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  indicatorColor: AppColors.accent,
                  tabs: [
                    Tab(text: 'Plan'),
                  ],
                ),
              ),
              const Expanded(
                child: BrkEmptyState(
                  icon: Icons.emoji_events_outlined,
                  title: 'Coming soon',
                  message: 'Battle is not built yet.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
