import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/move.dart';
import '../screens/detail/move_detail_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class MoveCard extends StatelessWidget {
  const MoveCard({super.key, required this.move});

  final BboyMove move;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => MoveDetailScreen(moveId: move.id)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(move.category.icon,
                    size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      move.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextTheme.titleMedium
                          ?.copyWith(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${move.category.label} · ${move.difficultyLabel}',
                      style: context.appTextTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _DifficultyDots(difficulty: move.difficulty),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => state.moves.toggleFavorite(move.id),
                icon: Icon(
                  move.favorite ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: move.favorite
                      ? AppColors.accent
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({required this.difficulty});

  final int difficulty;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= difficulty
                  ? AppColors.accent
                  : AppColors.surfaceVariant,
            ),
          ),
      ],
    );
  }
}
