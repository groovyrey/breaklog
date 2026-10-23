import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../theme/app_theme.dart';

/// Live preview for a recorded run, with plain states for loading and for a
/// camera that could not start.
class SimulationCameraView extends StatelessWidget {
  const SimulationCameraView({
    super.key,
    required this.loading,
    required this.failed,
    required this.controller,
    required this.onFlip,
  });

  final bool loading;
  final bool failed;
  final CameraController? controller;
  final VoidCallback? onFlip;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: BrkSpinner());
    }
    if (failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined,
                size: 32, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Camera unavailable, so this run will not be recorded.',
              textAlign: TextAlign.center,
              style: context.appTextTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    if (controller == null) return const SizedBox.shrink();

    final ratio = controller!.value.aspectRatio;
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final displayRatio = ratio <= 0 ? 1.0 : (landscape ? ratio : 1 / ratio);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: 1000,
              height: 1000 / displayRatio,
              child: CameraPreview(controller!),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Tooltip(
              message: 'Flip camera',
              child: GestureDetector(
                onTap: onFlip,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: onFlip == null ? 0.42 : 1,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceVariant,
                    ),
                    child: const Icon(
                      Icons.flip_camera_ios_outlined,
                      size: 20,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
