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
    this.driveFileId,
  });

  final String id;
  final MediaKind kind;

  /// Link holds a URL; the other kinds hold a local file path or a URL.
  final String value;

  /// Id of the copy in the user's Drive, set once it has been backed up.
  final String? driveFileId;

  bool get isRemote => value.startsWith('http://') || value.startsWith('https://');

  bool get backedUp => driveFileId != null && driveFileId!.isNotEmpty;

  MoveMedia copyWith({String? driveFileId}) => MoveMedia(
        id: id,
        kind: kind,
        value: value,
        driveFileId: driveFileId ?? this.driveFileId,
      );

  factory MoveMedia.fromJson(Map<String, dynamic> json) => MoveMedia(
        id: json['id'] as String,
        kind: MediaKind.fromName(json['kind'] as String?),
        value: json['value'] as String? ?? '',
        driveFileId: json['driveFileId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'value': value,
        'driveFileId': driveFileId,
      };
}
