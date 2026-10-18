import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/move.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Totals, a cold-to-hot difficulty spread, and counts per move type.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final moves = state.moves;
    final categoryCounts = moves.countsByCategory();
    final depthCounts = moves.countsByDepth();
    final total = moves.count;
    final maxCategory = categoryCounts.values
        .fold<int>(0, (a, b) => a > b ? a : b)
        .clamp(1, 999);
    final avg = total == 0
        ? 0
        : (moves.moves.fold<int>(0, (a, m) => a + m.difficulty) / total).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BrkHeader(
              title: 'Stats',
              eyebrow: total == 0 ? 'nothing logged yet' : '$total moves',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
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
                        value: total == 0 ? '—' : '$avg',
                        label: 'avg difficulty',
                        color: total == 0 ? null : AppColors.difficulty(avg),
                      ),
                    ],
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 26),
                    _SectionTitle('Difficulty spread'),
                    const SizedBox(height: 12),
                    for (var level = 1; level <= 5; level++)
                      _DifficultyRow(
                        level: level,
                        count: moves.moves.where((m) => m.difficulty == level).length,
                        total: total,
                      ),
                  ],
                  const SizedBox(height: 26),
                  _SectionTitle('Move types'),
                  const SizedBox(height: 12),
                  for (final entry in categoryCounts.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(entry.key,
                                  style: context.appTextTheme.titleSmall
                                      ?.copyWith(color: AppColors.onSurface)),
                              const Spacer(),
                              Text('${entry.value}',
                                  style: context.appTextTheme.titleSmall
                                      ?.copyWith(color: AppColors.accent)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _Bar(value: entry.value / maxCategory),
                        ],
                      ),
                    ),
                  ],
                  if (depthCounts.values.any((v) => v > 0)) ...[
                    const SizedBox(height: 8),
                    _SectionTitle('Depth'),
                    const SizedBox(height: 12),
                    for (final entry in depthCounts.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BrkRow(
                          label: entry.key.label,
                          value: '${entry.value}',
                        ),
                      ),
                  ],
                  if (total == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Stats fill in as you log moves.',
                        style: context.appTextTheme.bodyMedium,
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: context.appTextTheme.titleMedium);
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.level, required this.count, required this.total});

  final int level;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.difficulty(level);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              BboyMove.labelFor(level),
              style: context.appTextTheme.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: _Bar(value: total == 0 ? 0 : count / total, color: color),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 24,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: context.appTextTheme.titleSmall?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, this.color = AppColors.accent});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppColors.surfaceVariant),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

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
                    ?.copyWith(color: color ?? AppColors.accent)),
            const SizedBox(height: 4),
            Text(label, style: context.appTextTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
