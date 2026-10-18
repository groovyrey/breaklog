import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/move.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final moves = state.moves;
    final counts = moves.countsByCategory();
    final total = moves.count;
    final maxCount =
        counts.values.fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 999);
    final avgDifficulty = total == 0
        ? 0.0
        : moves.moves.fold<int>(0, (a, m) => a + m.difficulty) / total;

    return Scaffold(
      appBar: AppBar(
        title: Text('Stats', style: context.appTextTheme.headlineSmall),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              _MetricTile(
                value: '$total',
                label: total == 1 ? 'move logged' : 'moves logged',
              ),
              const SizedBox(width: 10),
              _MetricTile(
                value: '${moves.favoriteCount}',
                label: 'favorites',
              ),
              const SizedBox(width: 10),
              _MetricTile(
                value: total == 0 ? '—' : avgDifficulty.toStringAsFixed(1),
                label: 'avg difficulty',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('By category', style: context.appTextTheme.titleMedium),
          const SizedBox(height: 12),
          for (final c in MoveCategory.values) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(c.icon, size: 15, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(c.label,
                          style: context.appTextTheme.titleSmall?.copyWith(
                              color: AppColors.onSurface)),
                      const Spacer(),
                      Text('${counts[c] ?? 0}',
                          style: context.appTextTheme.titleSmall
                              ?.copyWith(color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (counts[c] ?? 0) / maxCount,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(
                        (counts[c] ?? 0) == 0
                            ? AppColors.surfaceVariant
                            : AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (total == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Stats fill in as you log moves.',
                style: context.appTextTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: context.appTextTheme.headlineMedium
                    ?.copyWith(color: AppColors.accent)),
            const SizedBox(height: 4),
            Text(label, style: context.appTextTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
