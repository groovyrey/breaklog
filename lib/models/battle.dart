/// The most rounds a stage can run in a plan. Simulation follows the same cap.
const int maxBattleRounds = 5;

/// A stage of an event, in bracket order. Only the stages a user adds to their
/// plan matter, so this is deliberately not the full event vocabulary. The
/// closing stage is [grandFinal]; `final` is a reserved word and cannot name it.
enum BattleStage {
  prelims,
  top32,
  top16,
  quarterfinal,
  semifinal,
  grandFinal,
  extra,
}

/// What the user plans to bring to one stage: how many rounds it runs and which
/// library moves or sets to lead with there.
class PlannedStage {
  const PlannedStage({
    required this.stage,
    required this.rounds,
    this.planIds = const [],
  });

  final BattleStage stage;

  /// How many rounds this stage runs. Each side takes one turn per round.
  final int rounds;

  /// Ids of the moves and sets chosen for this stage.
  final List<String> planIds;

  factory PlannedStage.fromJson(Map<String, dynamic> json) => PlannedStage(
        stage: battleStageFromName(json['stage'] as String?),
        rounds: ((json['rounds'] as num?)?.toInt() ?? 1)
            .clamp(1, maxBattleRounds)
            .toInt(),
        planIds: (json['planIds'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'stage': stage.name,
        'rounds': rounds,
        'planIds': planIds,
      };

  PlannedStage copyWith({int? rounds, List<String>? planIds}) => PlannedStage(
        stage: stage,
        rounds: rounds ?? this.rounds,
        planIds: planIds ?? this.planIds,
      );
}

/// Resolves a stored stage name, falling back to prelims so an unknown name
/// never drops the row that carried it.
BattleStage battleStageFromName(String? name) => BattleStage.values.firstWhere(
      (value) => value.name == name,
      orElse: () => BattleStage.prelims,
    );

/// One battle plan: the event, and what to do at each stage of it.
class BattlePlan {
  const BattlePlan({
    required this.id,
    required this.name,
    required this.eventAt,
    required this.stages,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime eventAt;
  final List<PlannedStage> stages;
  final DateTime updatedAt;

  factory BattlePlan.fromJson(Map<String, dynamic> json) => BattlePlan(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        eventAt: DateTime.tryParse(json['eventAt'] as String? ?? '') ??
            DateTime.now(),
        stages: (json['stages'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PlannedStage.fromJson)
            .toList(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'eventAt': eventAt.toIso8601String(),
        'stages': stages.map((s) => s.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  BattlePlan copyWith({
    String? id,
    String? name,
    DateTime? eventAt,
    List<PlannedStage>? stages,
    DateTime? updatedAt,
  }) =>
      BattlePlan(
        id: id ?? this.id,
        name: name ?? this.name,
        eventAt: eventAt ?? this.eventAt,
        stages: stages ?? this.stages,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Replaces the stage at [index], or appends it when [index] is out of range.
  BattlePlan withStage(int index, PlannedStage stage) {
    final next = [...stages];
    if (index >= 0 && index < next.length) {
      next[index] = stage;
    } else {
      next.add(stage);
    }
    return copyWith(stages: next);
  }

  BattlePlan withoutStage(BattleStage stage) =>
      copyWith(stages: stages.where((s) => s.stage != stage).toList());
}
