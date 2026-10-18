import 'dart:io';

import 'package:flutter/material.dart';

import '../models/media.dart';
import '../theme/app_theme.dart';

/// One attachment row, shared by the editor and the move detail screen.
///
/// Remote values open in the browser, local photos open in the in-app viewer,
/// and other local files are listed as stored on the device.
class BrkMediaTile extends StatelessWidget {
  const BrkMediaTile({
    super.key,
    required this.media,
    this.onRemove,
    required this.onOpen,
  });

  final MoveMedia media;
  final VoidCallback? onRemove;
  final VoidCallback onOpen;

  static IconData iconFor(MediaKind kind) => switch (kind) {
        MediaKind.link => Icons.link,
        MediaKind.video => Icons.movie_outlined,
        MediaKind.record => Icons.videocam_outlined,
        MediaKind.photo => Icons.photo_outlined,
      };

  String get _title {
    if (media.isRemote) return media.value;
    final parts = media.value.split('/');
    return parts.isEmpty ? media.value : parts.last;
  }

  String get _subtitle => media.isRemote
      ? '${media.kind.label} · opens in browser'
      : '${media.kind.label} · saved on this device';

  @override
  Widget build(BuildContext context) {
    final isPhoto = media.kind == MediaKind.photo && !media.isRemote;

    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isPhoto
                  ? Image.file(
                      File(media.value),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      cacheWidth: 160,
                      errorBuilder: (_, __, ___) =>
                          const _Glyph(icon: Icons.broken_image_outlined),
                    )
                  : const SizedBox(
                      width: 44,
                      height: 44,
                      child: _Glyph(icon: Icons.play_circle_outline),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextTheme.titleSmall
                        ?.copyWith(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 3),
                  Text(_subtitle, style: context.appTextTheme.bodySmall),
                ],
              ),
            ),
            if (onRemove != null)
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, right: 2),
                  child:
                      Icon(Icons.close, size: 18, color: AppColors.onSurfaceVariant),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.chevron_right,
                    size: 18, color: AppColors.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
    );
  }
}
