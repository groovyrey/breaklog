import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen photo viewer on our own route: black field, close control,
/// no platform preview sheet.
Future<void> showBrkImageViewer(BuildContext context, String path) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    BrkImageViewerRoute(path: path),
  );
}

class BrkImageViewerRoute extends PageRoute<void> {
  BrkImageViewerRoute({required this.path});

  final String path;

  @override
  Color? get barrierColor => Colors.black;

  @override
  String? get barrierLabel => 'Close';

  @override
  bool get opaque => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image.file(
                  File(path),
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('This photo could not be opened.',
                        style: TextStyle(color: AppColors.onSurfaceVariant)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceVariant,
                  ),
                  child:
                      const Icon(Icons.close, size: 20, color: AppColors.onSurface),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
