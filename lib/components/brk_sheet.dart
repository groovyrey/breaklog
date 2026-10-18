import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Presents [child] in the app's own bottom sheet.
///
/// Implemented as a bespoke route with our backdrop, grab handle and radius so
/// nothing falls back to the platform's sheet chrome.
Future<T?> showBrkSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    BrkSheetRoute<T>(builder: builder, dismissible: dismissible),
  );
}

class BrkSheetRoute<T> extends PageRoute<T> {
  BrkSheetRoute({required this.builder, this.dismissible = true});

  final WidgetBuilder builder;
  final bool dismissible;

  /// The dimming layer is painted by the route itself (see below) so a tap on
  /// it can be handled here instead of relying on the navigator's barrier.
  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Builder(builder: (ctx) => builder(ctx)),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: curved,
          child: GestureDetector(
            onTap: dismissible ? () => Navigator.of(context).maybePop() : null,
            child: const ColoredBox(color: Colors.black54),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position:
                Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Chrome wrapped around sheet content: handle, optional title, rounded top.
class BrkSheet extends StatelessWidget {
  const BrkSheet({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(
                title.toUpperCase(),
                style: context.appTextTheme.labelSmall
                    ?.copyWith(color: AppColors.accent),
              ),
            ),
            Flexible(
              // Loose flex: the viewport is bounded by the sheet's max height
              // but still sizes to its content, so short sheets stay short.
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrap a sheet's option list so rows read as a single grouped block.
class BrkSheetOptions extends StatelessWidget {
  const BrkSheetOptions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
