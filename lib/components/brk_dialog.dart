import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Centered modal dialog built on our own route: no AlertDialog, no
/// platform-adaptive dialog chrome.
Future<T?> showBrkDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    BrkDialogRoute<T>(builder: builder, barrierDismissible: barrierDismissible),
  );
}

class BrkDialogRoute<T> extends RawDialogRoute<T> {
  BrkDialogRoute({
    required WidgetBuilder builder,
    super.barrierDismissible,
  }) : super(
        pageBuilder: (context, _, __) => Padding(
          // Keep the panel above the keyboard on its own: a dialog route is
          // not resized by a Scaffold the way a normal screen is.
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Align(
            alignment: Alignment.center,
            child: builder(context),
          ),
        ),
          barrierLabel: 'Dismiss',
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 180),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween(begin: 0.96, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Consistent panel every dialog uses.
class BrkDialog extends StatelessWidget {
  const BrkDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 28),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: context.appTextTheme.labelSmall
                ?.copyWith(color: AppColors.accent),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20),
              child: child,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Flexible(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
