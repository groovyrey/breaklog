import 'dart:io';

import '../models/media.dart';
import '../models/move.dart';
import 'drive_backup.dart';
import 'move_repository.dart';

/// A backup run that could not start.
class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What one run did.
class BackupReport {
  const BackupReport({
    required this.uploaded,
    required this.skipped,
    required this.failed,
    this.firstError,
  });

  final int uploaded;
  final int skipped;
  final int failed;
  final String? firstError;
}

/// Copies local attachment files into the user's Drive folder and records the
/// resulting ids on the moves, so a later run skips what is already there.
class MediaBackup {
  MediaBackup({
    required MoveRepository moves,
    required Future<String?> Function() accessToken,
    DriveBackup? drive,
  })  : _moves = moves,
        _accessToken = accessToken,
        _drive = drive ?? DriveBackup();

  final MoveRepository _moves;
  final Future<String?> Function() _accessToken;
  final DriveBackup _drive;

  /// [onProgress] reports how many queued files are done and which one is in
  /// flight.
  Future<BackupReport> run({
    void Function(int done, int total, String name)? onProgress,
  }) async {
    final token = await _accessToken();
    if (token == null || token.isEmpty) {
      throw BackupException('Sign in again to back up media');
    }

    final queue = <_QueuedUpload>[];
    var skipped = 0;
    for (final move in _moves.moves) {
      for (final media in move.media) {
        if (media.isRemote || media.backedUp) {
          skipped++;
          continue;
        }
        final file = File(media.value);
        if (!await file.exists()) {
          skipped++;
          continue;
        }
        queue.add(_QueuedUpload(move: move, media: media, file: file));
      }
    }

    final folderId = await _drive.ensureFolder(token);
    var uploaded = 0;
    var failed = 0;
    String? firstError;
    for (final item in queue) {
      onProgress?.call(uploaded + failed, queue.length, _fileName(item));
      try {
        final fileId = await _drive.upload(
          accessToken: token,
          parentId: folderId,
          file: item.file,
          name: _fileName(item),
          mimeType: _mimeType(item.file.path),
        );
        await _attachDriveId(item, fileId);
        uploaded++;
      } on Exception catch (error) {
        failed++;
        firstError ??= error.toString();
      }
    }

    return BackupReport(
      uploaded: uploaded,
      skipped: skipped,
      failed: failed,
      firstError: firstError,
    );
  }

  Future<void> _attachDriveId(_QueuedUpload item, String driveFileId) async {
    final current = _moves.byId(item.move.id);
    if (current == null) return;
    final media = current.media
        .map((m) =>
            m.id == item.media.id ? m.copyWith(driveFileId: driveFileId) : m)
        .toList();
    await _moves.update(current.copyWith(media: media));
  }

  static String _fileName(_QueuedUpload item) {
    final cleaned = item.move.name
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    final base = cleaned.isEmpty ? 'breaklog' : cleaned;
    return '$base ${item.media.kind.label}${_extension(item.file.path)}';
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    final suffix = path.substring(dot).toLowerCase();
    return suffix.length <= 5 ? suffix : '';
  }

  static String _mimeType(String path) {
    return switch (_extension(path).replaceFirst('.', '')) {
      'mp4' || 'm4v' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      'mkv' => 'video/x-matroska',
      '3gp' => 'video/3gpp',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'heic' || 'heif' => 'image/heic',
      'webp' => 'image/webp',
      'm4a' => 'audio/mp4',
      'mp3' => 'audio/mpeg',
      'aac' => 'audio/aac',
      'wav' => 'audio/wav',
      'ogg' => 'audio/ogg',
      'opus' => 'audio/opus',
      _ => 'application/octet-stream',
    };
  }
}

class _QueuedUpload {
  _QueuedUpload({required this.move, required this.media, required this.file});

  final BboyMove move;
  final MoveMedia media;
  final File file;
}
