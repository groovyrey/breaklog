import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brk_progress.dart';

enum BrkButtonVariant { primary, secondary, ghost, danger, light }

/// The app's only button. Drawn from scratch so no Material button styling or
/// platform-adaptive widget leaks in.
class BrkButton extends StatelessWidget {
  const BrkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BrkButtonVariant.primary,
    this.icon,
    this.leading,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final BrkButtonVariant variant;
  final IconData? icon;

  /// Drawn before the label instead of [icon]; a provider mark like the Google
  /// G is an image rather than a font glyph.
  final Widget? leading;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final colors = _colorsFor(variant, enabled);

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          BrkSpinner(size: 14, stroke: 2, color: colors.foreground),
          const SizedBox(width: 10),
        ] else if (leading != null) ...[
          leading!,
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 17, color: colors.foreground),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: context.appTextTheme.titleSmall?.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: colors.border == null
                ? null
                : Border.all(color: colors.border!),
          ),
          child: expand
              ? SizedBox(width: double.infinity, child: child)
              : child,
        ),
      ),
    );
  }

  ({Color background, Color foreground, Color? border}) _colorsFor(
      BrkButtonVariant variant, bool enabled) {
    return switch (variant) {
      BrkButtonVariant.primary => (
          background: AppColors.accent,
          foreground: AppColors.onAccent,
          border: null,
        ),
      BrkButtonVariant.secondary => (
          background: AppColors.surfaceVariant,
          foreground: AppColors.onSurface,
          border: AppColors.outline,
        ),
      BrkButtonVariant.ghost => (
          background: Colors.transparent,
          foreground: AppColors.accent,
          border: null,
        ),
      BrkButtonVariant.danger => (
          background: Colors.transparent,
          foreground: AppColors.error,
          border: AppColors.error,
        ),
      BrkButtonVariant.light => (
          background: AppColors.lightSurface,
          foreground: AppColors.onLight,
          border: null,
        ),
    };
  }
}

/// Square icon-only control used for the add action and in-app toolbars.
class BrkIconButton extends StatelessWidget {
  const BrkIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 44,
    this.accent = false,
    this.danger = false,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final bool accent;
  final bool danger;

  /// Draws the accent dot used to flag a pending update.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final tint = danger
        ? AppColors.error
        : accent
            ? AppColors.accent
            : AppColors.onSurfaceVariant;

    final glyph = Icon(icon, size: size * 0.48, color: tint);

    return Opacity(
      opacity: onTap == null ? 0.42 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(
              color: accent ? AppColors.accent : Colors.transparent,
            ),
          ),
          child: badge
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _glyphWithTooltip(glyph),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                )
              : _glyphWithTooltip(glyph),
        ),
      ),
    );
  }

  Widget _glyphWithTooltip(Widget glyph) =>
      tooltip == null ? glyph : Tooltip(message: tooltip!, child: glyph);
}
