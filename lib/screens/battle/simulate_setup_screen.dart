import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/battle.dart';
import '../../models/battle_session.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/duration_label.dart';
import 'plan_widgets.dart';
import 'simulation_setup_widgets.dart';
import 'simulation_screen.dart';

/// Settings before a run: which stages to simulate, how long a turn and a rest
/// last, and whether the camera records the run.
class SimulateSetupScreen extends StatefulWidget {
  const SimulateSetupScreen({super.key, required this.planId});

  final String planId;

  @override
  State<SimulateSetupScreen> createState() => _SimulateSetupScreenState();
}

class _SimulateSetupScreenState extends State<SimulateSetupScreen> {
  static const _minSeconds = 5;
  static const _maxSeconds = 300;

  late final Set<BattleStage> _selected = {
    for (final stage
        in context.read<AppState>().battle.byId(widget.planId)?.stages ??
            const <PlannedStage>[])
      stage.stage,
  };
  int _turnSeconds = 30;
  int _restSeconds = 15;
  bool _record = false;

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<AppState>().battle.byId(widget.planId);
    if (plan == null) {
      return const Scaffold(backgroundColor: AppColors.background);
    }

    final theme = context.appTextTheme;
    final chosen =
        plan.stages.where((s) => _selected.contains(s.stage)).toList();
    final totalSeconds = chosen.fold<int>(
      0,
      (sum, stage) => sum + stage.rounds * (_turnSeconds + _restSeconds),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrkHeader(
              eyebrow: plan.name,
              title: 'Simulate battle',
              leading: Icons.arrow_back,
              onLeading: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 6, bottom: 28),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: Text(
                      'Pick the stages to run. Each round is a turn, then a rest.',
                      style: theme.bodyMedium,
                    ),
                  ),
                  const PlanSectionLabel('Stages'),
                  if (plan.stages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Add a stage to the plan first.',
                          style: theme.bodySmall),
                    ),
                  for (final stage in plan.stages) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SimulationStageChoice(
                        planned: stage,
                        selected: _selected.contains(stage.stage),
                        onTap: () => _toggle(stage.stage),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 14),
                  const PlanSectionLabel('Timing'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BrkCard(
                      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                      child: Column(
                        children: [
                          SecondsStepper(
                            label: 'Turn',
                            seconds: _turnSeconds,
                            onMinus: _turnSeconds > _minSeconds
                                ? () => setState(() => _turnSeconds -= 5)
                                : null,
                            onPlus: _turnSeconds < _maxSeconds
                                ? () => setState(() => _turnSeconds += 5)
                                : null,
                          ),
                          const Divider(color: AppColors.outline, height: 1),
                          SecondsStepper(
                            label: 'Rest',
                            seconds: _restSeconds,
                            onMinus: _restSeconds > _minSeconds
                                ? () => setState(() => _restSeconds -= 5)
                                : null,
                            onPlus: _restSeconds < _maxSeconds
                                ? () => setState(() => _restSeconds += 5)
                                : null,
                          ),
                          const Divider(color: AppColors.outline, height: 1),
                          BrkRow(
                            label: 'Total',
                            value: sessionLengthLabel(totalSeconds),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BrkCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record the session',
                                  style: theme.titleSmall
                                      ?.copyWith(color: AppColors.onSurface),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Saves a video of the run to this plan.',
                                  style: theme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          BrkSwitch(
                            value: _record,
                            onChanged: (value) =>
                                setState(() => _record = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BrkButton(
                      label: 'Start simulation',
                      icon: Icons.play_arrow,
                      onPressed: chosen.isEmpty
                          ? null
                          : () => _start(context, plan, chosen),
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

  void _toggle(BattleStage stage) => setState(() {
        if (!_selected.remove(stage)) _selected.add(stage);
      });

  Future<void> _start(
    BuildContext context,
    BattlePlan plan,
    List<PlannedStage> chosen,
  ) {
    return Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (_) => SimulationScreen(
          planId: plan.id,
          stages: [
            for (final stage in chosen)
              SessionStage(stage: stage.stage, rounds: stage.rounds),
          ],
          turnSeconds: _turnSeconds,
          restSeconds: _restSeconds,
          record: _record,
        ),
      ),
    );
  }
}
