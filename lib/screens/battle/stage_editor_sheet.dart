import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../constants/battle_stages.dart';
import '../../models/battle.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Edits one stage of the plan: how many rounds it runs and which moves or sets
/// to bring there. Pops the updated [PlannedStage], or null when cancelled.
Future<PlannedStage?> showStageEditor(
  BuildContext context, {
  required PlannedStage stage,
}) {
  return showBrkSheet<PlannedStage>(
    context: context,
    builder: (_) => StageEditorSheet(stage: stage),
  );
}

class StageEditorSheet extends StatefulWidget {
  const StageEditorSheet({super.key, required this.stage});

  final PlannedStage stage;

  @override
  State<StageEditorSheet> createState() => _StageEditorSheetState();
}

class _StageEditorSheetState extends State<StageEditorSheet> {
  late int _rounds = widget.stage.rounds.clamp(1, maxBattleRounds).toInt();
  late final List<String> _planIds = [...widget.stage.planIds];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final moves = state.moves.moves;
    final sets = state.sets.sets;

    return BrkSheet(
      title: battleStageLabel(widget.stage.stage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('Rounds'),
          const SizedBox(height: 10),
          BrkCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$_rounds ${_rounds == 1 ? 'round' : 'rounds'}',
                    style: context.appTextTheme.titleSmall
                        ?.copyWith(color: AppColors.onSurface),
                  ),
                ),
                BrkIconButton(
                  icon: Icons.remove,
                  onTap: _rounds > 1 ? () => setState(() => _rounds--) : null,
                ),
                const SizedBox(width: 6),
                BrkIconButton(
                  icon: Icons.add,
                  onTap: _rounds < maxBattleRounds
                      ? () => setState(() => _rounds++)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _label('What to bring'),
          const SizedBox(height: 10),
          if (moves.isEmpty && sets.isEmpty)
            BrkCard(
              child: Text(
                'Nothing in your library yet. Add moves or sets first, then pick them here.',
                style: context.appTextTheme.bodySmall,
              ),
            )
          else
            BrkSheetOptions(
              children: [
                for (final move in moves)
                  BrkOptionTile(
                    title: move.name,
                    subtitle: move.category,
                    icon: Icons.sports_martial_arts,
                    trailing: _mark(_planIds.contains(move.id)),
                    onTap: () => _toggle(move.id),
                  ),
                for (final set in sets)
                  BrkOptionTile(
                    title: set.name,
                    subtitle: '${set.moveIds.length} moves',
                    icon: Icons.queue_music_outlined,
                    trailing: _mark(_planIds.contains(set.id)),
                    onTap: () => _toggle(set.id),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          BrkButton(
            label: 'Save stage',
            onPressed: () => Navigator.of(context).pop(
              widget.stage.copyWith(rounds: _rounds, planIds: _planIds),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: context.appTextTheme.labelSmall
            ?.copyWith(color: AppColors.onSurfaceVariant),
      );

  /// A tick mark rather than a chip, per the app's plain row style.
  Widget _mark(bool selected) => Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        size: 20,
        color: selected ? AppColors.accent : AppColors.outline,
      );

  void _toggle(String id) => setState(() {
        if (!_planIds.remove(id)) _planIds.add(id);
      });
}
