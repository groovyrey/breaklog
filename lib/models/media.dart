/// Attachment kinds a move can carry.
enum MediaKind {
  link('Link'),
  video('Video'),
  record('Record'),
  photo('Photo');

  const MediaKind(this.label);

  final String label;

  static MediaKind fromName(String? name) =>
      MediaKind.values.firstWhere((k) => k.name == name,
          orElse: () => MediaKind.link);
}

class MoveMedia {
  const MoveMedia({
    required this.id,
    required this.kind,
    required this.value,
  });

  final String id;
  final MediaKind kind;

  /// Link holds a URL; the other kinds hold a local file path or a URL.
  final String value;

  bool get isRemote => value.startsWith('http://') || value.startsWith('https://');

  factory MoveMedia.fromJson(Map<String, dynamic> json) => MoveMedia(
        id: json['id'] as String,
        kind: MediaKind.fromName(json['kind'] as String?),
        value: json['value'] as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'kind': kind.name, 'value': value};
}
