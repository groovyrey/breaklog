import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Round Google account photo, with a neutral person glyph when there is none.
class BrkAvatar extends StatelessWidget {
  const BrkAvatar({super.key, required this.photoUrl, this.size = 34});

  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.person_outline,
      size: size * 0.5,
      color: AppColors.onSurfaceVariant,
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline),
      ),
      child: photoUrl.isEmpty
          ? fallback
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}
