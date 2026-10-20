import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../theme/app_theme.dart';
import '../top_actions.dart';
import 'plan_tab.dart';
import 'prep_tab.dart';

/// Battle: what is being planned for the event and what to get ready for it.
/// Plan sets rounds per stage; Prep is the checklist of things to be ready.
class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

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
                    Tab(text: 'Prep'),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    PlanTab(),
                    PrepTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
