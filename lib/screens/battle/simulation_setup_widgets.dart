import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../constants/battle_stages.dart';
import '../../models/battle.dart';
import '../../theme/app_theme.dart';
import '../../utils/duration_label.dart';

/// One selectable stage on the simulation setup page.
class SimulationStageChoice extends StatelessWidget {
  const SimulationStageChoice({
    super.key,
    required this.planned,
    required this.selected,
    required this.onTap,
  });

  final PlannedStage planned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rounds = planned.rounds;
    return BrkCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  battleStageLabel(planned.stage),
                  style: context.appTextTheme.titleSmall
                      ?.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  '$rounds ${rounds == 1 ? 'round' : 'rounds'}',
                  style: context.appTextTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            size: 22,
            color: selected ? AppColors.accent : AppColors.outline,
          ),
        ],
      ),
    );
  }
}

/// Turn or rest duration in five second steps.
class SecondsStepper extends StatelessWidget {
  const SecondsStepper({
    super.key,
    required this.label,
    required this.seconds,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int seconds;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.appTextTheme.titleSmall
                  ?.copyWith(color: AppColors.onSurface),
            ),
          ),
          Text(
            clockLabel(seconds),
            style: context.appTextTheme.titleMedium
                ?.copyWith(color: AppColors.accent),
          ),
          const SizedBox(width: 8),
          BrkIconButton(
            icon: Icons.remove,
            size: 36,
            tooltip: 'Less $label time',
            onTap: onMinus,
          ),
          BrkIconButton(
            icon: Icons.add,
            size: 36,
            tooltip: 'More $label time',
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}
