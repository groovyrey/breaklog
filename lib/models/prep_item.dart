/// One thing to prepare before a battle, ticked off as it is done. Prep is a
/// working list, so an item keeps whatever order the user added it in.
class PrepItem {
  const PrepItem({
    required this.id,
    required this.text,
    required this.done,
    required this.createdAt,
  });

  final String id;
  final String text;
  final bool done;
  final DateTime createdAt;

  factory PrepItem.fromJson(Map<String, dynamic> json) => PrepItem(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        done: json['done'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
      };

  PrepItem copyWith({String? text, bool? done}) => PrepItem(
        id: id,
        text: text ?? this.text,
        done: done ?? this.done,
        createdAt: createdAt,
      );
}
