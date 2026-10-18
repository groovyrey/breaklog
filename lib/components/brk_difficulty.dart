import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Five-step difficulty meter where every filled mark takes the color of its
/// own level, so the meter itself shows the cold-to-hot ramp.
class BrkDifficultyDots extends StatelessWidget {
  const BrkDifficultyDots({super.key, required this.level, this.size = 7});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= level ? AppColors.difficulty(i) : AppColors.outline,
              ),
            ),
          ),
      ],
    );
  }
}

/// Difficulty label rendered in its level color, with the ramp behind it.
class BrkDifficultyTag extends StatelessWidget {
  const BrkDifficultyTag({super.key, required this.level, required this.label});

  final int level;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.difficulty(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.difficultySoft(level),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: context.appTextTheme.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          BrkDifficultyDots(level: level, size: 5),
        ],
      ),
    );
  }
}
