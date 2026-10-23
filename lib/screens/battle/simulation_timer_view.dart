import 'package:flutter/material.dart';

import '../../constants/battle_stages.dart';
import '../../services/simulation_engine.dart';
import '../../theme/app_theme.dart';
import '../../utils/duration_label.dart';

/// The stage, round and clock for the running simulation.
class SimulationTimerView extends StatelessWidget {
  const SimulationTimerView({super.key, required this.engine});

  final SimulationEngine engine;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTextTheme;
    final rest = engine.phase == SimulationPhase.rest;
    final done = engine.finished;

    return Column(
      children: [
        Text(
          'Stage ${engine.stageIndex + 1} of ${engine.stages.length}',
          style: theme.labelSmall?.copyWith(color: AppColors.accent),
        ),
        const SizedBox(height: 6),
        Text(
          battleStageLabel(engine.currentStage.stage),
          style: theme.titleLarge?.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          'Round ${engine.round} of ${engine.currentStage.rounds}',
          style: theme.bodySmall,
        ),
        const SizedBox(height: 18),
        Text(
          done
              ? 'Session complete'
              : rest
                  ? 'Rest'
                  : 'Your turn',
          style: theme.titleMedium?.copyWith(
            color: rest || done ? AppColors.accent : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          clockLabel(engine.remainingSeconds),
          style: theme.displayLarge?.copyWith(
            fontSize: 84,
            color: rest ? AppColors.onSurfaceVariant : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 18),
        _ProgressBar(value: engine.progress),
        const SizedBox(height: 8),
        Text(
          '${clockLabel(engine.elapsedSeconds)} elapsed',
          style: theme.bodySmall,
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.outline),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
