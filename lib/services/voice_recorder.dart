import 'package:record/record.dart';

import 'media_store.dart';

/// A recording that could not start, with a message fit for a toast.
class VoiceRecordingException implements Exception {
  VoiceRecordingException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One recording in progress. The audio is written straight into the media
/// folder, so saving the returned [path] is all a caller has to do.
class VoiceRecording {
  VoiceRecording._(this._recorder, this.path);

  final AudioRecorder _recorder;
  final String path;
  bool _closed = false;

  /// Requests the microphone when needed and starts writing to a new file.
  static Future<VoiceRecording> start() async {
    final recorder = AudioRecorder();
    try {
      if (!await recorder.hasPermission()) {
        throw VoiceRecordingException('Microphone access is needed to record.');
      }
      final path = await MediaStore.allocate('m4a');
      await recorder.start(const RecordConfig(), path: path);
      return VoiceRecording._(recorder, path);
    } on VoiceRecordingException {
      await recorder.dispose();
      rethrow;
    } on Object catch (error) {
      await recorder.dispose();
      throw VoiceRecordingException('Recording could not start. $error');
    }
  }

  /// Finishes the file and returns its path, which stays on disk.
  Future<String> stop() async {
    if (_closed) return path;
    _closed = true;
    try {
      return await _recorder.stop() ?? path;
    } finally {
      await _recorder.dispose();
    }
  }

  /// Stops without keeping anything, whether or not [stop] already ran.
  Future<void> discard() async {
    if (!_closed) {
      _closed = true;
      try {
        await _recorder.cancel();
      } on Object catch (_) {
        // A recorder already torn down has nothing left to cancel.
      }
      await _recorder.dispose();
    }
    await MediaStore.remove(path);
  }
}
