import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Switch built on a plain tap target; no Cupertino or platform switch.
class BrkSwitch extends StatelessWidget {
  const BrkSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 46,
        height: 27,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.accent : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? AppColors.accent : AppColors.outline,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.onAccent : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented single-choice control (used for move depth).

/// Segmented single-choice control (used for move depth).
class BrkSegmented<T> extends StatelessWidget {
  const BrkSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<({T value, String label})> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option.value),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option.value == value
                        ? AppColors.accentSoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.field - 2),
                    border: Border.all(
                      color: option.value == value
                          ? AppColors.accent
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    option.label,
                    style: context.appTextTheme.titleSmall?.copyWith(
                      color: option.value == value
                          ? AppColors.accent
                          : AppColors.onSurfaceVariant,
                      fontWeight: option.value == value
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Stepper used for difficulty (1-5). Drag or tap the marks.
