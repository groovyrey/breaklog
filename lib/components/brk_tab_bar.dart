import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One destination in the floating bar. [supportsAdd] decides whether the
/// centre action shows while the tab is active, so a screen with no add flow
/// (Stats) renders the bar without one.
typedef BrkTab = ({
  IconData icon,
  IconData selectedIcon,
  String label,
  bool supportsAdd,
});

const double _barHeight = 62;
const double _addLift = 14;
const double _addSize = 64;
const double _bottomMargin = 12;

/// Tail room a scroll view must leave so the floating bar never covers its last
/// item: the bar, the raised add button, the margin, and the system inset.
double brkFloatingBarInset(BuildContext context) =>
    _barHeight +
    _addLift +
    _bottomMargin +
    MediaQuery.of(context).padding.bottom +
    12;

/// Floating, blurred bottom bar. It sits over the content so items scroll under
/// it, which is why lists reserve [brkFloatingBarInset] at their tail.
class BrkTabBar extends StatelessWidget {
  const BrkTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onChanged,
    this.onAdd,
  });

  final List<BrkTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  /// When null the centre action is hidden.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final showAdd = onAdd != null;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: _barHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++) ...[
                    if (i > 0)
                      SizedBox(width: showAdd && i == 1 ? _addSize + 14 : 4),
                    Expanded(
                      child: _TabItem(
                        tab: tabs[i],
                        selected: i == currentIndex,
                        onTap: () => onChanged(i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showAdd)
          Positioned(
            top: -_addLift,
            child: BrkFab(icon: Icons.add, size: _addSize, onTap: onAdd!),
          ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final BrkTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 46,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? tab.selectedIcon : tab.icon,
              size: 20,
              color: selected ? AppColors.accent : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: context.appTextTheme.bodySmall?.copyWith(
                color: selected ? AppColors.accent : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular action for the floating bar. [size] lets the centre action sit
/// larger than the bar so it reads as a raised, primary control, with a
/// background-coloured ring so it looks docked rather than pasted on.
class BrkFab extends StatelessWidget {
  const BrkFab({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 60,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent,
          border: Border.all(color: AppColors.background, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: size * 0.42, color: AppColors.onAccent),
      ),
    );
    return tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);
  }
}
