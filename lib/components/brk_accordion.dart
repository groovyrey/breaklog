import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Collapsible section: a labelled header that shows the current value and
/// opens to reveal its choices.
class BrkAccordion extends StatefulWidget {
  const BrkAccordion({
    super.key,
    required this.title,
    required this.summary,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final String summary;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<BrkAccordion> createState() => _BrkAccordionState();
}

class _BrkAccordionState extends State<BrkAccordion> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: _open ? AppColors.accent : AppColors.outline,
              ),
            ),
            child: Row(
              children: [
                Text(
                  widget.title.toUpperCase(),
                  style: context.appTextTheme.labelSmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  widget.summary,
                  style: context.appTextTheme.titleSmall?.copyWith(
                    color: _open ? AppColors.accent : AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: const Icon(Icons.keyboard_arrow_down,
                      size: 20, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 160),
          crossFadeState:
              _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
