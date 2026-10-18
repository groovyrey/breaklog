import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../models/move.dart';
import '../../theme/app_theme.dart';
import '../detail/move_detail_screen.dart';

/// One vocabulary row: name, its category and depth, and the difficulty meter
/// in the level's own color.
class MoveCard extends StatelessWidget {
  const MoveCard({super.key, required this.move});

  final BboyMove move;

  @override
  Widget build(BuildContext context) {
    return BrkCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MoveDetailScreen(moveId: move.id)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        move.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.appTextTheme.titleLarge?.copyWith(
                          color: AppColors.onSurface,
                          fontSize: 19,
                        ),
                      ),
                    ),
                    if (move.favorite)
                      const Icon(Icons.favorite,
                          size: 15, color: AppColors.accent),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  [
                    if (move.category.isNotEmpty) move.category,
                    move.depth.label,
                  ].join('   '),
                  style: context.appTextTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    BrkDifficultyDots(level: move.difficulty),
                    const SizedBox(width: 8),
                    Text(
                      move.difficultyLabel,
                      style: context.appTextTheme.labelMedium?.copyWith(
                        color: AppColors.difficulty(move.difficulty),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right,
              size: 20, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
