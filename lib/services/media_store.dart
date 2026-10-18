import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Copies picked media out of the picker's temporary cache into app storage so
/// attachments survive restarts, and removes them when the user drops them.
class MediaStore {
  static const _folder = 'breaklog_media';

  /// [fallbackExtension] is used when neither the file name nor its MIME type
  /// carries one. Android pickers often hand back cache files whose name has no
  /// suffix, and a player that cannot see ".mp4" refuses to open the clip.
  static Future<String> importXFile(
    XFile file, {
    String fallbackExtension = 'bin',
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final extension = _extensionFor(file, fallbackExtension);
    final target = File(
        '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$extension');
    await file.saveTo(target.path);
    return target.path;
  }

  static String _extensionFor(XFile file, String fallback) {
    final name = file.name;
    final dot = name.lastIndexOf('.');
    if (dot >= 0 && dot < name.length - 1) {
      final fromName = name.substring(dot + 1).toLowerCase();
      if (_isPlainSuffix(fromName)) return fromName;
    }

    final mime = file.mimeType;
    final subtype = mime?.split('/').last.toLowerCase();
    if (subtype != null && _isPlainSuffix(subtype)) {
      return subtype == 'quicktime' ? 'mov' : subtype;
    }

    return fallback;
  }

  static bool _isPlainSuffix(String value) =>
      value.isNotEmpty &&
      value.length <= 5 &&
      RegExp(r'^[a-z0-9]+$').hasMatch(value);

  static Future<void> remove(String path) async {
    if (path.startsWith('http')) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A missing file is not worth surfacing to the user.
    }
  }
}
