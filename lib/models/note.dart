import 'media.dart';

/// A dated journal entry written from Home. The day it belongs to comes from
/// [createdAt], so a note is never separated from the date it was written on.
class LogNote {
  const LogNote({
    required this.id,
    required this.body,
    required this.createdAt,
    this.media = const [],
  });

  final String id;
  final String body;
  final DateTime createdAt;

  /// Attachments carried the same way moves carry them.
  final List<MoveMedia> media;

  factory LogNote.fromJson(Map<String, dynamic> json) => LogNote(
        id: json['id'] as String,
        body: json['body'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        media: (json['media'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(MoveMedia.fromJson)
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'media': media.map((m) => m.toJson()).toList(),
      };

  LogNote copyWith({String? body, List<MoveMedia>? media}) => LogNote(
        id: id,
        body: body ?? this.body,
        createdAt: createdAt,
        media: media ?? this.media,
      );
}
