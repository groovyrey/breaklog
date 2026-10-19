import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The toast currently on screen, so a new one replaces it instead of stacking.
OverlayEntry? _active;

/// Shows a short confirmation at the top of the screen.
///
/// Lives in the root overlay, so it survives a route pop and can be shown right
/// before navigating away.
void showBrkToast(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_outline,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final previous = _active;
  if (previous != null && previous.mounted) previous.remove();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _BrkToast(
      message: message,
      icon: icon,
      onDismissed: () {
        if (entry.mounted) entry.remove();
        if (identical(_active, entry)) _active = null;
      },
    ),
  );
  _active = entry;
  overlay.insert(entry);
}

class _BrkToast extends StatefulWidget {
  const _BrkToast({
    required this.message,
    required this.icon,
    required this.onDismissed,
  });

  final String message;
  final IconData icon;
  final VoidCallback onDismissed;

  @override
  State<_BrkToast> createState() => _BrkToastState();
}

class _BrkToastState extends State<_BrkToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _hold = Timer(const Duration(milliseconds: 2600), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _hold?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      top: 0,
      child: IgnorePointer(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: FadeTransition(
                opacity: _curve,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, -0.3), end: Offset.zero)
                      .animate(_curve),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: context.appTextTheme.bodySmall?.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
