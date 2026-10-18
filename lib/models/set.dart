import 'media.dart';

/// A saved group of vocabulary moves the user sequences into a routine.
class MoveSet {
  const MoveSet({
    required this.id,
    required this.name,
    required this.moveIds,
    required this.createdAt,
    this.media = const [],
  });

  final String id;
  final String name;
  final List<String> moveIds;
  final DateTime createdAt;
  final List<MoveMedia> media;

  factory MoveSet.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    return MoveSet(
      id: json['id'] as String,
      name: json['name'] as String,
      moveIds: (json['moveIds'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      media: rawMedia is List
          ? rawMedia
              .whereType<Map<String, dynamic>>()
              .map(MoveMedia.fromJson)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'moveIds': moveIds,
        'createdAt': createdAt.toIso8601String(),
        'media': media.map((m) => m.toJson()).toList(),
      };

  MoveSet copyWith({
    String? name,
    List<String>? moveIds,
    List<MoveMedia>? media,
  }) =>
      MoveSet(
        id: id,
        name: name ?? this.name,
        moveIds: moveIds ?? this.moveIds,
        createdAt: createdAt,
        media: media ?? this.media,
      );
}
