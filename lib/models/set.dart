/// A saved group of vocabulary moves the user sequences into a routine.
class MoveSet {
  const MoveSet({
    required this.id,
    required this.name,
    required this.moveIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<String> moveIds;
  final DateTime createdAt;

  factory MoveSet.fromJson(Map<String, dynamic> json) => MoveSet(
        id: json['id'] as String,
        name: json['name'] as String,
        moveIds: (json['moveIds'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'moveIds': moveIds,
        'createdAt': createdAt.toIso8601String(),
      };

  MoveSet copyWith({String? name, List<String>? moveIds}) => MoveSet(
        id: id,
        name: name ?? this.name,
        moveIds: moveIds ?? this.moveIds,
        createdAt: createdAt,
      );
}
