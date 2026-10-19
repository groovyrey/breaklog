import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Round Google account photo, with a neutral person glyph when there is none.
class BrkAvatar extends StatelessWidget {
  const BrkAvatar({super.key, required this.photoUrl, this.size = 34});

  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: size * 0.55,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
    final content = photoUrl.isEmpty
        ? fallback
        : Image.network(
            photoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          );

    // ClipOval guarantees a true circle, and the ring is a foreground
    // decoration so it is painted whole on top instead of being half-cut by
    // the clip, which left the frame looking lopsided.
    return Container(
      width: size,
      height: size,
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline),
      ),
      child: ClipOval(child: content),
    );
  }
}
