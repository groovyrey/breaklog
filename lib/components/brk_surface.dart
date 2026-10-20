import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brk_button.dart';

/// Page title bar replacement; no AppBar, no platform back button styling.
class BrkHeader extends StatelessWidget {
  const BrkHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actions = const [],
    this.leading,
    this.onLeading,
    this.mark,
  });

  final String title;
  final String? eyebrow;
  final List<Widget> actions;
  final IconData? leading;
  final VoidCallback? onLeading;

  /// Brand mark set to the left of the title.
  final Widget? mark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
      child: Row(
        children: [
          if (leading != null) ...[
            BrkIconButton(icon: leading!, onTap: onLeading, size: 40),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!.toUpperCase(),
                    style: context.appTextTheme.labelSmall
                        ?.copyWith(color: AppColors.accent),
                  ),
                if (eyebrow != null) const SizedBox(height: 4),
                Row(
                  children: [
                    if (mark != null) ...[
                      mark!,
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: context.appTextTheme.headlineSmall
                            ?.copyWith(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Flat panel used everywhere a container is needed.
class BrkCard extends StatelessWidget {
  const BrkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.accented = false,
    this.decoration,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool accented;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final box = decoration ??
        BoxDecoration(
          color: accented ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: accented ? AppColors.accent : AppColors.outline,
          ),
        );

    return GestureDetector(
      onTap: onTap,
      behavior: onTap == null ? HitTestBehavior.deferToChild : HitTestBehavior.opaque,
      child: Container(width: double.infinity, padding: padding, decoration: box, child: child),
    );
  }
}

/// Two-line label/value row used on detail and settings screens. Pass either
/// [value] or a [trailing] widget when the value needs custom color or marks.
class BrkRow extends StatelessWidget {
  const BrkRow({
    super.key,
    required this.label,
    this.value = '',
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: context.appTextTheme.bodyMedium),
          const Spacer(),
          if (trailing != null)
            trailing!
          else
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: context.appTextTheme.titleSmall
                    ?.copyWith(color: AppColors.onSurface),
              ),
            ),
        ],
      ),
    );
  }
}

class BrkEmptyState extends StatelessWidget {
  const BrkEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline),
              ),
              child: Icon(icon, size: 30, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.appTextTheme.titleLarge
                  ?.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: context.appTextTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
