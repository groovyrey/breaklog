import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'media_store.dart';

/// Owns the in-app camera for one simulation: preview while it runs, one
/// continuous recording across every selected stage, and an app-private file
/// when the run ends.
class SessionRecorder {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _index = 0;
  bool _recording = false;

  CameraController? get controller => _controller;
  bool get ready => _controller?.value.isInitialized ?? false;
  bool get recording => _recording;
  bool get canFlip => _cameras.length > 1;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw const SessionRecorderException('No camera is available on this device');
    }
    final front =
        _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
    _index = front < 0 ? 0 : front;
    await _open();
  }

  Future<void> _open() async {
    final controller = CameraController(
      _cameras[_index],
      ResolutionPreset.high,
      enableAudio: true,
    );
    _controller = controller;
    await controller.initialize();
  }

  /// Swaps to the other lens. Only valid while no clip is being recorded.
  Future<void> flip() async {
    if (!canFlip || _recording) return;
    final current = _cameras[_index].lensDirection;
    var next = _cameras.indexWhere((c) => c.lensDirection != current);
    if (next < 0) next = (_index + 1) % _cameras.length;
    final previous = _controller;
    _controller = null;
    await previous?.dispose();
    _index = next;
    await _open();
  }

  Future<void> start() async {
    final controller = _controller;
    if (controller == null || !ready || _recording) return;
    await controller.startVideoRecording();
    _recording = true;
  }

  Future<void> pause() async {
    final controller = _controller;
    if (controller == null || !_recording) return;
    await controller.pauseVideoRecording();
  }

  Future<void> resume() async {
    final controller = _controller;
    if (controller == null || !_recording) return;
    await controller.resumeVideoRecording();
  }

  /// Stops the clip and copies it out of the camera cache. Returns null when no
  /// recording was running.
  Future<String?> stop() async {
    final controller = _controller;
    if (controller == null || !_recording) return null;
    _recording = false;
    final file = await controller.stopVideoRecording();
    return MediaStore.importXFile(file, fallbackExtension: 'mp4');
  }

  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    if (_recording) {
      _recording = false;
      try {
        await controller.stopVideoRecording();
      } catch (error) {
        debugPrint('Stopping camera on dispose failed: $error');
      }
    }
    await controller.dispose();
  }
}

class SessionRecorderException implements Exception {
  const SessionRecorderException(this.message);

  final String message;

  @override
  String toString() => message;
}
