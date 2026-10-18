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
