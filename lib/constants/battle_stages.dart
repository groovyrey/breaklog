import '../models/battle.dart';

/// The stages an event runs through, in bracket order. Every event opens with
/// these five; the user edits rounds, removes stages they will not reach, and
/// adds others like Top 32 as their event needs.
const List<BattleStage> defaultBattleStages = [
  BattleStage.prelims,
  BattleStage.top16,
  BattleStage.quarterfinal,
  BattleStage.semifinal,
  BattleStage.grandFinal,
];

/// Everything a user can put on a plan, so adding a stage offers each once.
/// [BattleStage.extra] is not in the opening plan; it is there for anything an
/// event adds outside the usual bracket.
const List<BattleStage> allBattleStages = [
  BattleStage.prelims,
  BattleStage.top32,
  BattleStage.top16,
  BattleStage.quarterfinal,
  BattleStage.semifinal,
  BattleStage.grandFinal,
  BattleStage.extra,
];

const Map<BattleStage, String> battleStageLabels = {
  BattleStage.prelims: 'Prelims',
  BattleStage.top32: 'Top 32',
  BattleStage.top16: 'Top 16',
  BattleStage.quarterfinal: 'Quarterfinal',
  BattleStage.semifinal: 'Semifinal',
  BattleStage.grandFinal: 'Final',
  BattleStage.extra: 'Extra',
};

/// Rounds an event usually runs at each stage, used as the starting point the
/// user is free to change.
const Map<BattleStage, int> defaultBattleRounds = {
  BattleStage.prelims: 1,
  BattleStage.top32: 1,
  BattleStage.top16: 1,
  BattleStage.quarterfinal: 2,
  BattleStage.semifinal: 2,
  BattleStage.grandFinal: 3,
  BattleStage.extra: 1,
};

String battleStageLabel(BattleStage stage) => battleStageLabels[stage]!;

int defaultRoundsFor(BattleStage stage) => defaultBattleRounds[stage]!;
