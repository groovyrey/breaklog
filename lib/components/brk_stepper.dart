import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Stepper used for difficulty (1-5). Drag or tap the marks.
class BrkStepper extends StatelessWidget {
  const BrkStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 5,
    this.readOnlyLabels = const [],
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final List<String> readOnlyLabels;

  @override
  Widget build(BuildContext context) {
    final label = value >= 0 && value - min < readOnlyLabels.length
        ? readOnlyLabels[value - min]
        : '$value';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Difficulty',
              style: context.appTextTheme.titleSmall
                  ?.copyWith(color: AppColors.onSurface),
            ),
            const Spacer(),
            Text(
              label,
              style: context.appTextTheme.titleSmall
                  ?.copyWith(color: AppColors.difficulty(value)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = max - min + 1;
            final step = constraints.maxWidth / (count - 1);
            final fill = AppColors.difficulty(value);
            return SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    width: (value - min) * step,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  for (var i = 0; i < count; i++)
                    Positioned(
                      left: (i * step) - 13,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(min + i),
                        child: Container(
                          width: 26,
                          height: 44,
                          alignment: Alignment.center,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: min + i == value ? 20 : 13,
                            height: min + i == value ? 20 : 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: min + i <= value
                                  ? AppColors.difficulty(min + i)
                                  : AppColors.outline,
                              border: min + i == value
                                  ? Border.all(color: AppColors.onAccent, width: 2)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
