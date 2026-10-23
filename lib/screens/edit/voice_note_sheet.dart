import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../components/index.dart';
import '../../models/media.dart';
import '../../services/media_store.dart';
import '../../services/voice_recorder.dart';
import '../../theme/app_theme.dart';

/// Records a voice note and returns it ready to attach, or null when the user
/// leaves without keeping one.
Future<MoveMedia?> showVoiceNoteSheet(BuildContext context) {
  return showBrkSheet<MoveMedia>(
    context: context,
    dismissible: false,
    builder: (_) => const VoiceNoteSheet(),
  );
}

class VoiceNoteSheet extends StatefulWidget {
  const VoiceNoteSheet({super.key});

  @override
  State<VoiceNoteSheet> createState() => _VoiceNoteSheetState();
}

class _VoiceNoteSheetState extends State<VoiceNoteSheet> {
  static const _max = Duration(minutes: 10);

  VoiceRecording? _recording;
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  String? _path;
  String? _error;
  bool _stopping = false;
  bool _kept = false;

  bool get _live => _recording != null && !_stopping;

  @override
  void dispose() {
    _ticker?.cancel();
    final recording = _recording;
    if (recording != null) unawaited(recording.discard());
    final path = _path;
    if (!_kept && path != null) unawaited(MediaStore.remove(path));
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final recording = await VoiceRecording.start();
      if (!mounted) {
        await recording.discard();
        return;
      }
      setState(() {
        _recording = recording;
        _startedAt = DateTime.now();
        _elapsed = Duration.zero;
        _path = null;
      });
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        final started = _startedAt;
        if (started == null || !mounted) return;
        setState(() => _elapsed = DateTime.now().difference(started));
        if (_elapsed >= _max) unawaited(_stop());
      });
    } on VoiceRecordingException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _stop() async {
    if (_stopping || _recording == null) return;
    _ticker?.cancel();
    _ticker = null;
    final recording = _recording!;
    setState(() => _stopping = true);
    try {
      final path = await recording.stop();
      _recording = null;
      if (!mounted) {
        await MediaStore.remove(path);
        return;
      }
      setState(() {
        _path = path;
        _stopping = false;
      });
    } on Object catch (error) {
      _recording = null;
      if (mounted) {
        setState(() {
          _stopping = false;
          _error = 'The recording could not be saved. $error';
        });
      }
    }
  }

  void _discard() {
    _ticker?.cancel();
    _ticker = null;
    final recording = _recording;
    final path = _path;
    _recording = null;
    _path = null;
    if (recording != null) {
      unawaited(recording.discard());
    } else if (path != null) {
      unawaited(MediaStore.remove(path));
    }
    Navigator.of(context).pop();
  }

  void _save() {
    final path = _path;
    if (path == null) return;
    _kept = true;
    Navigator.of(context).pop(MoveMedia(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      kind: MediaKind.voice,
      value: path,
    ));
  }

  String get _clock {
    final seconds = _elapsed.inSeconds;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    final live = _live;
    final saved = _path != null;

    return PopScope(
      canPop: !live && !_stopping,
      child: BrkSheet(
        title: 'Voice note',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: live ? AppColors.accentSoft : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: live ? AppColors.accent : AppColors.outline,
                  ),
                ),
                child: Icon(
                  live ? Icons.mic : Icons.mic_none,
                  size: 40,
                  color: live ? AppColors.accent : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                _clock,
                style: context.appTextTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _message(live: live, saved: saved),
              textAlign: TextAlign.center,
              style: context.appTextTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: context.appTextTheme.bodySmall
                    ?.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 26),
            if (live)
              BrkButton(
                label: 'Stop recording',
                icon: Icons.stop,
                onPressed: () => unawaited(_stop()),
              )
            else if (saved) ...[
              BrkButton(
                label: 'Save voice note',
                icon: Icons.check,
                onPressed: _save,
              ),
              const SizedBox(height: 10),
              BrkButton(
                label: 'Discard',
                variant: BrkButtonVariant.secondary,
                onPressed: _discard,
              ),
            ] else
              BrkButton(
                label: _error == null ? 'Start recording' : 'Try again',
                icon: Icons.mic_none,
                onPressed: () => unawaited(_start()),
              ),
          ],
        ),
      ),
    );
  }

  String _message({required bool live, required bool saved}) {
    if (live) return 'Recording. Tap stop to finish.';
    if (saved) return 'Ready to attach.';
    if (_stopping) return 'Finishing the recording.';
    return 'Tap start when you are ready.';
  }
}
