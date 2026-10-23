import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/battle_session.dart';

enum SimulationPhase { turn, rest, done }

/// Drives one simulation: selected stages in order, each round alternating a
/// turn and a rest. Time is advanced one second at a time, so the widget layer
/// only has to render state and the tests can step it without waiting.
class SimulationEngine extends ChangeNotifier {
  SimulationEngine({
    required this.stages,
    required this.turnSeconds,
    required this.restSeconds,
  })  : assert(stages.length > 0),
        assert(turnSeconds > 0),
        assert(restSeconds > 0),
        _remaining = turnSeconds;

  final List<SessionStage> stages;
  final int turnSeconds;
  final int restSeconds;

  Timer? _ticker;
  int _stageIndex = 0;
  int _round = 1;
  SimulationPhase _phase = SimulationPhase.turn;
  int _remaining;
  int _elapsedSeconds = 0;
  bool _running = false;

  int get stageIndex => _stageIndex;
  SessionStage get currentStage => stages[_stageIndex];
  int get round => _round;
  SimulationPhase get phase => _phase;
  int get remainingSeconds => _remaining;
  int get elapsedSeconds => _elapsedSeconds;
  bool get running => _running;
  bool get finished => _phase == SimulationPhase.done;

  int get totalRounds =>
      stages.fold(0, (sum, stage) => sum + stage.rounds);

  /// Rounds already behind the current one, for a whole-session label.
  int get completedRounds =>
      stages.take(_stageIndex).fold(0, (sum, s) => sum + s.rounds) +
      (_round - 1);

  int get totalSeconds =>
      totalRounds * (turnSeconds + restSeconds);

  double get progress => totalSeconds == 0
      ? 0
      : (_elapsedSeconds / totalSeconds).clamp(0, 1).toDouble();

  void play() {
    if (_running || finished) return;
    _running = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => advanceSecond());
    notifyListeners();
  }

  void pause() {
    if (!_running) return;
    _running = false;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  /// Advances the clock by one second. Play calls this from a timer; tests call
  /// it directly after play to walk a whole session without waiting.
  void advanceSecond() {
    if (!_running || finished) return;
    _elapsedSeconds++;
    _remaining--;

    if (_remaining > 0) {
      notifyListeners();
      return;
    }

    if (_phase == SimulationPhase.turn) {
      _phase = SimulationPhase.rest;
      _remaining = restSeconds;
    } else if (_round < currentStage.rounds) {
      _round++;
      _phase = SimulationPhase.turn;
      _remaining = turnSeconds;
    } else if (_stageIndex < stages.length - 1) {
      _stageIndex++;
      _round = 1;
      _phase = SimulationPhase.turn;
      _remaining = turnSeconds;
    } else {
      _phase = SimulationPhase.done;
      _remaining = 0;
      _running = false;
      _ticker?.cancel();
      _ticker = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
