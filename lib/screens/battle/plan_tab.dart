import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/battle.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/battle_countdown.dart';
import 'plan_info_screen.dart';
import 'plan_sheet.dart';
import 'plan_widgets.dart';

/// Plan tab: the battles being worked on. A plan opens as its own page; this
/// tab only lists them and starts a new one.
class PlanTab extends StatelessWidget {
  const PlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<AppState>().battle.plans;

    if (plans.isEmpty) {
      return ListView(
        padding: EdgeInsets.only(
          top: 30,
          bottom: MediaQuery.of(context).padding.bottom + 90,
        ),
        children: [
          const BrkEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No battles planned',
            message: 'Start a plan to set rounds for each stage.',
          ),
          const SizedBox(height: 8),
          const _NewBattleCard(),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.only(
        top: 18,
        bottom: MediaQuery.of(context).padding.bottom + 90,
      ),
      children: [
        const PlanSectionLabel('Battles'),
        for (final plan in plans) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PlanRow(plan: plan),
          ),
          const SizedBox(height: 10),
        ],
        const _NewBattleCard(),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan});

  final BattlePlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTextTheme;
    final stages = plan.stages.length;

    return BrkCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlanInfoScreen(planId: plan.id),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: theme.titleLarge?.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  battleCountdown(plan.eventAt),
                  style: theme.bodyMedium?.copyWith(color: AppColors.accent),
                ),
                const SizedBox(height: 4),
                Text(
                  '$stages ${stages == 1 ? 'stage' : 'stages'}',
                  style: theme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              size: 20, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _NewBattleCard extends StatelessWidget {
  const _NewBattleCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: BrkCard(
        onTap: () => showPlanSheet(context),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            const Icon(Icons.add, size: 19, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'New battle',
                style: context.appTextTheme.titleSmall
                    ?.copyWith(color: AppColors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
