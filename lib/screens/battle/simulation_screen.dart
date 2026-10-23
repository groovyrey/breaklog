import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/battle_session.dart';
import '../../services/session_recorder.dart';
import '../../services/simulation_engine.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'simulation_camera_view.dart';
import 'simulation_timer_view.dart';

/// Full-screen run: camera preview when recording, the turn/rest clock, and a
/// Done action that appears once the timer is paused or the run completes.
class SimulationScreen extends StatefulWidget {
  const SimulationScreen({
    super.key,
    required this.planId,
    required this.stages,
    required this.turnSeconds,
    required this.restSeconds,
    required this.record,
  });

  final String planId;
  final List<SessionStage> stages;
  final int turnSeconds;
  final int restSeconds;
  final bool record;

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  late final SimulationEngine _engine = SimulationEngine(
    stages: widget.stages,
    turnSeconds: widget.turnSeconds,
    restSeconds: widget.restSeconds,
  );
  final SessionRecorder _recorder = SessionRecorder();

  bool _cameraLoading = false;
  bool _cameraFailed = false;
  bool _closing = false;
  bool _saved = false;
  bool _saveFailed = false;
  Future<void>? _finishFuture;

  @override
  void initState() {
    super.initState();
    _engine.addListener(_onEngineChanged);
    if (widget.record) unawaited(_initCamera());
  }

  Future<void> _initCamera() async {
    _cameraLoading = true;
    try {
      await _recorder.initialize();
    } catch (error) {
      debugPrint('Camera init failed: $error');
      if (mounted) setState(() => _cameraFailed = true);
    } finally {
      if (mounted) setState(() => _cameraLoading = false);
    }
  }

  void _onEngineChanged() {
    if (_engine.finished) unawaited(_finish());
  }

  Future<void> _togglePlay() async {
    if (_engine.finished || _cameraLoading) return;

    if (_engine.running) {
      _engine.pause();
      if (_recorder.recording) {
        try {
          await _recorder.pause();
        } catch (error) {
          _recordingError(error);
        }
      }
      if (mounted) setState(() {});
      return;
    }

    if (widget.record && _recorder.ready && !_recorder.recording) {
      try {
        await _recorder.start();
      } catch (error) {
        _recordingError(error);
      }
    } else if (widget.record && _recorder.recording) {
      try {
        await _recorder.resume();
      } catch (error) {
        _recordingError(error);
      }
    }
    if (!mounted) return;
    _engine.play();
    setState(() {});
  }

  /// The clock still runs when the camera cannot, so one failed recording never
  /// blocks the practice itself.
  void _recordingError(Object error) {
    debugPrint('Recording control failed: $error');
    if (!mounted) return;
    showBrkToast(
      context,
      'Recording stopped, timer still running.',
      icon: Icons.videocam_off_outlined,
    );
  }

  Future<void> _finish() => _finishFuture ??= _runFinish();

  Future<void> _runFinish() async {
    _engine.pause();
    String? path;
    if (widget.record && _recorder.recording) {
      try {
        path = await _recorder.stop();
      } catch (error) {
        debugPrint('Stopping the recording failed: $error');
      }
    }
    if (path == null || !mounted) return;

    try {
      final state = context.read<AppState>();
      await state.sessions.save(BattleSession(
        id: '',
        planId: widget.planId,
        stages: widget.stages,
        turnSeconds: widget.turnSeconds,
        restSeconds: widget.restSeconds,
        elapsedSeconds: _engine.elapsedSeconds,
        recordedAt: DateTime.now(),
        videoPath: path,
      ));
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      debugPrint('Saving the simulation session failed: $error');
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  Future<void> _done() async {
    if (_closing) return;
    setState(() => _closing = true);
    await _finish();
    if (!mounted) return;
    if (_saved) {
      showBrkToast(context, 'Session saved to this plan',
          icon: Icons.videocam_outlined);
    } else if (_saveFailed) {
      showBrkToast(context, 'Could not save the session',
          icon: Icons.error_outline);
    }
    Navigator.of(context).pop();
  }

  void _requestClose() {
    if (_engine.running) {
      showBrkToast(context, 'Pause the session to finish',
          icon: Icons.pause_circle_outline);
      return;
    }
    unawaited(_done());
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_engine.running && !_recorder.recording,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              BrkHeader(
                title: 'Simulation',
                leading: Icons.close,
                onLeading: _requestClose,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    children: [
                      if (widget.record) ...[
                        Expanded(
                          flex: 5,
                          child: SimulationCameraView(
                            loading: _cameraLoading,
                            failed: _cameraFailed,
                            controller: _recorder.controller,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ] else
                        const Spacer(),
                      ListenableBuilder(
                        listenable: _engine,
                        builder: (context, _) =>
                            SimulationTimerView(engine: _engine),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: ListenableBuilder(
                  listenable: _engine,
                  builder: (context, _) => _controls(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    final running = _engine.running;
    final done = _engine.finished;

    return Column(
      children: [
        if (!done)
          BrkButton(
            label: running ? 'Pause' : 'Play',
            icon: running ? Icons.pause : Icons.play_arrow,
            onPressed: _cameraLoading ? null : _togglePlay,
          ),
        if (!running) ...[
          if (!done) const SizedBox(height: 10),
          BrkButton(
            label: 'Done',
            variant: done ? BrkButtonVariant.primary : BrkButtonVariant.secondary,
            onPressed: _closing ? null : _done,
            loading: _closing,
          ),
        ],
      ],
    );
  }
}
