import 'media.dart';

/// How a move relates to the standard.
enum MoveDepth {
  universal('Universal'),
  myVersion('My version'),
  myCreation('My creation');

  const MoveDepth(this.label);

  final String label;

  static MoveDepth fromName(String? name) => MoveDepth.values.firstWhere(
        (d) => d.name == name,
        orElse: () => MoveDepth.universal,
      );
}

class BboyMove {
  const BboyMove({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.learnedAt,
    this.depth = MoveDepth.universal,
    this.notes = '',
    this.media = const [],
    this.favorite = false,
  });

  final String id;
  final String name;

  /// Category name; resolved against the category store so user-created
  /// categories stay valid even after this model is serialized alone.
  final String category;

  /// 1 (beginner) to 5 (battle-ready).
  final int difficulty;

  final MoveDepth depth;
  final String notes;
  final List<MoveMedia> media;
  final DateTime learnedAt;
  final bool favorite;

  factory BboyMove.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    var media = <MoveMedia>[];
    if (rawMedia is List) {
      media = rawMedia
          .whereType<Map<String, dynamic>>()
          .map(MoveMedia.fromJson)
          .toList();
    } else if (json['videoUrl'] is String &&
        (json['videoUrl'] as String).isNotEmpty) {
      // Pre-media builds stored a single video URL.
      media = [
        MoveMedia(
          id: 'legacy',
          kind: MediaKind.video,
          value: json['videoUrl'] as String,
        ),
      ];
    }

    return BboyMove(
      id: json['id'] as String,
      name: json['name'] as String,
      category: (json['category'] as String?) ?? '',
      difficulty: ((json['difficulty'] as num?)?.clamp(1, 5) ?? 1).toInt(),
      depth: MoveDepth.fromName(json['depth'] as String?),
      notes: json['notes'] as String? ?? '',
      media: media,
      learnedAt: DateTime.tryParse(json['learnedAt'] as String? ?? '') ??
          DateTime.now(),
      favorite: json['favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'difficulty': difficulty,
        'depth': depth.name,
        'notes': notes,
        'media': media.map((m) => m.toJson()).toList(),
        'learnedAt': learnedAt.toIso8601String(),
        'favorite': favorite,
      };

  BboyMove copyWith({
    String? name,
    String? category,
    int? difficulty,
    MoveDepth? depth,
    String? notes,
    List<MoveMedia>? media,
    DateTime? learnedAt,
    bool? favorite,
  }) =>
      BboyMove(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        difficulty: difficulty ?? this.difficulty,
        depth: depth ?? this.depth,
        notes: notes ?? this.notes,
        media: media ?? this.media,
        learnedAt: learnedAt ?? this.learnedAt,
        favorite: favorite ?? this.favorite,
      );

  String get difficultyLabel => labelFor(difficulty);

  static String labelFor(int difficulty) => switch (difficulty) {
        1 => 'Beginner',
        2 => 'Getting it',
        3 => 'Clean',
        4 => 'Sharp',
        _ => 'Battle-ready',
      };
}
