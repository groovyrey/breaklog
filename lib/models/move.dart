import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum MoveCategory {
  toprock('Toprock'),
  footwork('Footwork'),
  power('Power'),
  freeze('Freeze'),
  combo('Combo');

  const MoveCategory(this.label);

  final String label;

  static MoveCategory fromName(String name) =>
      MoveCategory.values.firstWhere((c) => c.name == name,
          orElse: () => MoveCategory.footwork);

  IconData get icon => switch (this) {
        MoveCategory.toprock => PhosphorIconsRegular.shuffle,
        MoveCategory.footwork => PhosphorIconsRegular.steps,
        MoveCategory.power => PhosphorIconsRegular.hurricane,
        MoveCategory.freeze => PhosphorIconsRegular.snowflake,
        MoveCategory.combo => PhosphorIconsRegular.linkSimple,
      };
}

class BboyMove {
  const BboyMove({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.learnedAt,
    this.notes = '',
    this.videoUrl = '',
    this.favorite = false,
  });

  final String id;
  final String name;
  final MoveCategory category;

  /// 1 (beginner) to 5 (battle-ready).
  final int difficulty;
  final String notes;
  final String videoUrl;
  final DateTime learnedAt;
  final bool favorite;

  factory BboyMove.fromJson(Map<String, dynamic> json) => BboyMove(
        id: json['id'] as String,
        name: json['name'] as String,
        category: MoveCategory.fromName(json['category'] as String? ?? ''),
        difficulty: ((json['difficulty'] as num?)?.clamp(1, 5) ?? 1).toInt(),
        notes: json['notes'] as String? ?? '',
        videoUrl: json['videoUrl'] as String? ?? '',
        learnedAt: DateTime.tryParse(json['learnedAt'] as String? ?? '') ??
            DateTime.now(),
        favorite: json['favorite'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'difficulty': difficulty,
        'notes': notes,
        'videoUrl': videoUrl,
        'learnedAt': learnedAt.toIso8601String(),
        'favorite': favorite,
      };

  BboyMove copyWith({
    String? name,
    MoveCategory? category,
    int? difficulty,
    String? notes,
    String? videoUrl,
    DateTime? learnedAt,
    bool? favorite,
  }) =>
      BboyMove(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        difficulty: difficulty ?? this.difficulty,
        notes: notes ?? this.notes,
        videoUrl: videoUrl ?? this.videoUrl,
        learnedAt: learnedAt ?? this.learnedAt,
        favorite: favorite ?? this.favorite,
      );

  String get difficultyLabel => switch (difficulty) {
        1 => 'Beginner',
        2 => 'Getting it',
        3 => 'Clean',
        4 => 'Sharp',
        _ => 'Battle-ready',
      };
}
