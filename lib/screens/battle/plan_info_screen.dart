import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../constants/battle_stages.dart';
import '../../models/battle.dart';
import '../../services/media_store.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/battle_countdown.dart';
import 'plan_sheet.dart';
import 'plan_widgets.dart';
import 'recorded_sessions_section.dart';
import 'simulate_setup_screen.dart';
import 'stage_editor_sheet.dart';

/// Everything about one plan: its date and the rounds planned at each stage.
/// Pushed from the Plan tab so a plan opens as its own page.
class PlanInfoScreen extends StatelessWidget {
  const PlanInfoScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final plan = state.battle.byId(planId);
    if (plan == null) {
      return const Scaffold(backgroundColor: AppColors.background);
    }

    final theme = context.appTextTheme;
    final sessions = state.sessions.forPlan(planId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrkHeader(
              title: plan.name,
              leading: Icons.arrow_back,
              onLeading: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 6, bottom: 28),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BrkCard(
                      onTap: () => showPlanSheet(context, plan: plan),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        children: [
                          const Icon(Icons.event_outlined,
                              size: 19, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  battleCountdown(plan.eventAt),
                                  style: theme.titleSmall
                                      ?.copyWith(color: AppColors.accent),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  DateFormat.yMMMd().format(plan.eventAt),
                                  style: theme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BrkButton(
                      label: 'Simulate battle',
                      icon: Icons.play_arrow,
                      onPressed: plan.stages.isEmpty
                          ? null
                          : () => Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SimulateSetupScreen(planId: plan.id),
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const PlanSectionLabel('Stages'),
                  for (var i = 0; i < plan.stages.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PlanStageRow(
                        planned: plan.stages[i],
                        onEdit: () => _editStage(context, plan, i),
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
                  const SizedBox(height: 28),
                  RecordedSessionsSection(sessions: sessions),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BrkButton(
                      label: 'Delete battle',
                      variant: BrkButtonVariant.danger,
                      onPressed: () => _delete(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editStage(
    BuildContext context,
    BattlePlan plan,
    int index,
  ) async {
    final updated = await showStageEditor(
      context,
      stage: plan.stages[index],
    );
    if (updated == null || !context.mounted) return;
    final state = context.read<AppState>();
    final current = state.battle.byId(plan.id);
    if (current == null) return;
    await state.battle.save(current.withStage(index, updated));
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
    final current = state.battle.byId(plan.id);
    if (current == null) return;
    await state.battle.save(current.withStage(-1, PlannedStage(
      stage: chosen,
      rounds: defaultRoundsFor(chosen),
    )));
  }

  Future<void> _delete(BuildContext context) async {
    final accepted = await showBrkDialog<bool>(
      context: context,
      builder: (ctx) => BrkDialog(
        title: 'Delete battle',
        actions: [
          BrkButton(
            label: 'Cancel',
            variant: BrkButtonVariant.secondary,
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          BrkButton(
            label: 'Delete',
            variant: BrkButtonVariant.danger,
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
        child: Text(
          'This removes the plan, every stage in it, and its recorded sessions.',
          style: ctx.appTextTheme.bodyMedium,
        ),
      ),
    );
    if (accepted != true || !context.mounted) return;

    final state = context.read<AppState>();
    final sessions = state.sessions.forPlan(planId);
    for (final session in sessions) {
      await MediaStore.remove(session.videoPath);
    }
    await state.sessions.removeForPlan(planId);
    await state.battle.remove(planId);
    if (!context.mounted) return;
    Navigator.of(context).maybePop();
  }
}
