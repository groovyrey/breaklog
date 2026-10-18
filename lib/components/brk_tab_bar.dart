import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Two-item bottom tab strip drawn by the app. Replaces NavigationBar so the
/// indicator, labels and hit targets are ours rather than Material's.
class BrkTabBar extends StatelessWidget {
  const BrkTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<({IconData icon, IconData selectedIcon, String label})> tabs;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
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
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, IconData selectedIcon, String label}) tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
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
                  size: 21,
                  color:
                      selected ? AppColors.accent : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  tab.label,
                  style: context.appTextTheme.bodySmall?.copyWith(
                    color: selected
                        ? AppColors.accent
                        : AppColors.onSurfaceVariant,
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

/// Circular icon-only action. Deliberately holds a single glyph with no label,
/// so the option sheet decides what the add action actually does.
class BrkFab extends StatelessWidget {
  const BrkFab({super.key, required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: 26, color: AppColors.onAccent),
      ),
    );

    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}
