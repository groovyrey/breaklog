import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Copies picked media out of the picker's temporary cache into app storage so
/// attachments survive restarts, and removes them when the user drops them.
class MediaStore {
  static const _folder = 'breaklog_media';

  static Future<String> importXFile(XFile file) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'bin';
    final target = File(
        '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$extension');
    await File(file.path).copy(target.path);
    return target.path;
  }

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
