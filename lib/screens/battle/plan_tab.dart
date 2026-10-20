import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../constants/battle_stages.dart';
import '../../models/battle.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/battle_countdown.dart';
import 'plan_sheet.dart';
import 'stage_editor_sheet.dart';

/// Plan tab: the one battle being worked on, with a row per stage showing its
/// round count and what is planned there.
class PlanTab extends StatelessWidget {
  const PlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final plan = state.battle.plan;

    if (plan == null) {
      return BrkEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No battle planned',
        message: 'Start a plan to set rounds for each stage.',
      );
    }

    final theme = context.appTextTheme;

    return ListView(
      padding: EdgeInsets.only(
        top: 18,
        bottom: brkFloatingBarInset(context),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: BrkCard(
            onTap: () => showPlanSheet(context),
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
                  style: theme.bodyMedium
                      ?.copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Stages'),
        for (var i = 0; i < plan.stages.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _StageRow(
              planned: plan.stages[i],
              onEdit: () => _editStage(context, i, plan.stages[i]),
              onRemove: () => state.battle.save(
                plan.withoutStage(plan.stages[i].stage),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: BrkCard(
            onTap: () => _addStage(context, plan),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.add,
                    size: 19, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add a stage',
                    style: theme.titleSmall
                        ?.copyWith(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editStage(
    BuildContext context,
    int index,
    PlannedStage planned,
  ) async {
    final updated = await showStageEditor(context, stage: planned);
    if (updated == null || !context.mounted) return;
    final state = context.read<AppState>();
    final plan = state.battle.plan;
    if (plan == null) return;
    await state.battle.save(plan.withStage(index, updated));
  }

  /// Offers only the stages not already on the plan, so each appears once.
  Future<void> _addStage(BuildContext context, BattlePlan plan) async {
    final taken = plan.stages.map((s) => s.stage).toSet();
    final available = allBattleStages.where((s) => !taken.contains(s)).toList();

    if (available.isEmpty) {
      showBrkToast(context, 'Every stage is already on the plan',
          icon: Icons.info_outline);
      return;
    }

    final chosen = await showBrkSheet<BattleStage>(
      context: context,
      builder: (ctx) => BrkSheet(
        title: 'Add stage',
        child: BrkSheetOptions(
          children: [
            for (final stage in available)
              BrkOptionTile(
                title: battleStageLabel(stage),
                subtitle: '${defaultRoundsFor(stage)} rounds by default',
                icon: Icons.emoji_events_outlined,
                onTap: () => Navigator.of(ctx).pop(stage),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;

    final state = context.read<AppState>();
    final current = state.battle.plan;
    if (current == null) return;
    await state.battle.save(current.withStage(-1, PlannedStage(
      stage: chosen,
      rounds: defaultRoundsFor(chosen),
    )));
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.planned,
    required this.onEdit,
    required this.onRemove,
  });

  final PlannedStage planned;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTextTheme;
    final rounds = planned.rounds;

    return BrkCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  battleStageLabel(planned.stage),
                  style: theme.titleSmall?.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  '$rounds ${rounds == 1 ? 'round' : 'rounds'}',
                  style: theme.bodySmall,
                ),
              ],
            ),
          ),
          BrkIconButton(
            icon: Icons.close,
            size: 36,
            tooltip: 'Remove ${battleStageLabel(planned.stage)}',
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Text(text.toUpperCase(),
            style: context.appTextTheme.labelSmall
                ?.copyWith(color: AppColors.onSurfaceVariant)),
      );
}
