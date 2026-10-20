/// A stage of an event, in bracket order. Only the stages a user adds to their
/// plan matter, so this is deliberately not the full event vocabulary.
enum BattleStage {
  prelims,
  top32,
  top16,
  quarterfinal,
  semifinal,
  final,
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
        stage: _stageFromName(json['stage'] as String?),
        rounds: (json['rounds'] as num?)?.toInt() ?? 1,
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

  /// Reads a stored stage name. Storage written by a newer build can name a
  /// stage this build does not know, which reads as prelims rather than
  /// dropping the whole row.
  static BattleStage _stageFromName(String? name) =>
      BattleStage.values.firstWhere(
        (value) => value.name == name,
        orElse: () => BattleStage.prelims,
      );
}

/// The one battle plan the user is working on: the event, and what to do at
/// each stage of it.
class BattlePlan {
  const BattlePlan({
    required this.name,
    required this.eventAt,
    required this.stages,
    required this.updatedAt,
  });

  final String name;
  final DateTime eventAt;
  final List<PlannedStage> stages;
  final DateTime updatedAt;

  factory BattlePlan.fromJson(Map<String, dynamic> json) => BattlePlan(
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
        'name': name,
        'eventAt': eventAt.toIso8601String(),
        'stages': stages.map((s) => s.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  BattlePlan copyWith({
    String? name,
    DateTime? eventAt,
    List<PlannedStage>? stages,
    DateTime? updatedAt,
  }) =>
      BattlePlan(
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
