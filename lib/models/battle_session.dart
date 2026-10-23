import 'battle.dart';

/// One stage as it ran in a simulation: the round count is captured at the
/// time, so later edits to the plan do not rewrite history.
class SessionStage {
  const SessionStage({required this.stage, required this.rounds});

  final BattleStage stage;
  final int rounds;

  factory SessionStage.fromJson(Map<String, dynamic> json) => SessionStage(
        stage: battleStageFromName(json['stage'] as String?),
        rounds: ((json['rounds'] as num?)?.toInt() ?? 1)
            .clamp(1, maxBattleRounds)
            .toInt(),
      );

  Map<String, dynamic> toJson() => {
        'stage': stage.name,
        'rounds': rounds,
      };
}

/// One finished simulation attached to a plan: the stages it ran in order, the
/// timings it used, and the video file written by the in-app recorder.
class BattleSession {
  const BattleSession({
    required this.id,
    required this.planId,
    required this.stages,
    required this.turnSeconds,
    required this.restSeconds,
    required this.elapsedSeconds,
    required this.recordedAt,
    required this.videoPath,
  });

  final String id;

  /// The plan this session belongs to. Sessions outlive plan edits but not a
  /// deleted plan.
  final String planId;
  final List<SessionStage> stages;
  final int turnSeconds;
  final int restSeconds;

  /// Seconds the session actually ran, which can stop short of the plan.
  final int elapsedSeconds;
  final DateTime recordedAt;

  /// Absolute path under the app's media folder.
  final String videoPath;

  int get totalRounds =>
      stages.fold(0, (sum, stage) => sum + stage.rounds);

  factory BattleSession.fromJson(Map<String, dynamic> json) => BattleSession(
        id: json['id'] as String? ?? '',
        planId: json['planId'] as String? ?? '',
        stages: (json['stages'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(SessionStage.fromJson)
            .toList(),
        turnSeconds: (json['turnSeconds'] as num?)?.toInt() ?? 0,
        restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 0,
        elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
        recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
            DateTime.now(),
        videoPath: json['videoPath'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'planId': planId,
        'stages': stages.map((stage) => stage.toJson()).toList(),
        'turnSeconds': turnSeconds,
        'restSeconds': restSeconds,
        'elapsedSeconds': elapsedSeconds,
        'recordedAt': recordedAt.toIso8601String(),
        'videoPath': videoPath,
      };
}
