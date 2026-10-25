import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../theme/app_theme.dart';
import '../top_actions.dart';

class CrewScreen extends StatelessWidget {
  const CrewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Builder(
                builder: (ctx) => BrkHeader(
                  title: 'Crew',
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
                    Tab(text: 'My Crew'),
                    Tab(text: 'Find Crews'),
                    Tab(text: 'Social'),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _MyCrewTab(),
                    _FindCrewsTab(),
                    _SocialTab(),
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

class _MyCrewTab extends StatelessWidget {
  const _MyCrewTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        BrkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No crew yet',
                style: context.appTextTheme.titleMedium
                    ?.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your own crew or find one to join.',
                style: context.appTextTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BrkButton(
                      label: 'Create crew',
                      icon: Icons.add,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BrkButton(
                      label: 'Find crews',
                      variant: BrkButtonVariant.secondary,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FindCrewsTab extends StatelessWidget {
  const _FindCrewsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: BrkEmptyState(
        icon: Icons.search,
        title: 'Find Crews',
        message: 'Browse and discover crews to join.',
      ),
    );
  }
}

class _SocialTab extends StatelessWidget {
  const _SocialTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: BrkEmptyState(
        icon: Icons.diversity_3,
        title: 'Social Space',
        message: 'View other crews and connect with the community.',
      ),
    );
  }
}
