import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../constants/battle_stages.dart';
import '../../models/battle.dart';
import '../../theme/app_theme.dart';

/// One stage row in a plan: rounds, open to edit, and a remove control.
class PlanStageRow extends StatelessWidget {
  const PlanStageRow({
    super.key,
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

class PlanSectionLabel extends StatelessWidget {
  const PlanSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Text(text.toUpperCase(),
            style: context.appTextTheme.labelSmall
                ?.copyWith(color: AppColors.onSurfaceVariant)),
      );
}
