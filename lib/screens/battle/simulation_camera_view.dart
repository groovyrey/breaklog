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
  });

  final bool loading;
  final bool failed;
  final CameraController? controller;

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
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: CameraPreview(controller!),
      ),
    );
  }
}
