import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../components/index.dart';
import '../../models/media.dart';
import '../../services/media_store.dart';
import 'voice_note_sheet.dart';

/// Runs the attachment flow and returns a ready-to-save [MoveMedia], or null
/// when the user backs out. Every kind is offered through our own sheet.
Future<MoveMedia?> pickBrkMedia(BuildContext context) async {
  final choice = await showBrkSheet<String>(
    context: context,
    builder: (ctx) => BrkSheet(
      title: 'Attach media',
      child: BrkSheetOptions(
        children: [
          BrkOptionTile(
            title: 'Link',
            subtitle: 'Paste a reference URL',
            icon: Icons.link,
            onTap: () => Navigator.of(ctx).pop('link'),
          ),
          BrkOptionTile(
            title: 'Video',
            subtitle: 'Pick a clip from this device',
            icon: Icons.video_library_outlined,
            onTap: () => Navigator.of(ctx).pop('video'),
          ),
          BrkOptionTile(
            title: 'Record',
            subtitle: 'Film a clip now',
            icon: Icons.videocam_outlined,
            onTap: () => Navigator.of(ctx).pop('record'),
          ),
          BrkOptionTile(
            title: 'Voice note',
            subtitle: 'Record audio on this device',
            icon: Icons.mic_none,
            onTap: () => Navigator.of(ctx).pop('voice'),
          ),
          BrkOptionTile(
            title: 'Photo',
            subtitle: 'Camera or gallery still',
            icon: Icons.photo_camera_outlined,
            onTap: () => Navigator.of(ctx).pop('photo'),
          ),
        ],
      ),
    ),
  );

  if (choice == null || !context.mounted) return null;

  switch (choice) {
    case 'link':
      return _askForLink(context);
    case 'video':
      return _capture(
        context,
        image: false,
        source: ImageSource.gallery,
        kind: MediaKind.video,
      );
    case 'record':
      return _capture(
        context,
        image: false,
        source: ImageSource.camera,
        kind: MediaKind.record,
      );
    case 'voice':
      return showVoiceNoteSheet(context);
    default:
      return _choosePhotoSource(context);
  }
}

Future<MoveMedia?> _choosePhotoSource(BuildContext context) async {
  final source = await showBrkSheet<String>(
    context: context,
    builder: (ctx) => BrkSheet(
      title: 'Photo',
      child: BrkSheetOptions(
        children: [
          BrkOptionTile(
            title: 'Take photo',
            icon: Icons.photo_camera_outlined,
            onTap: () => Navigator.of(ctx).pop('camera'),
          ),
          BrkOptionTile(
            title: 'From gallery',
            icon: Icons.photo_library_outlined,
            onTap: () => Navigator.of(ctx).pop('gallery'),
          ),
        ],
      ),
    ),
  );

  if (source == null || !context.mounted) return null;
  return _capture(
    context,
    image: true,
    source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
    kind: MediaKind.photo,
  );
}

Future<MoveMedia?> _askForLink(BuildContext context) async {
  final field = TextEditingController();
  final accepted = await showBrkDialog<bool>(
    context: context,
    builder: (ctx) => BrkDialog(
      title: 'Add link',
      actions: [
        BrkButton(
          label: 'Cancel',
          variant: BrkButtonVariant.secondary,
          expand: false,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        BrkButton(
          label: 'Attach',
          expand: false,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
      child: BrkField(
        controller: field,
        label: 'URL',
        hint: 'https://…',
        keyboardType: TextInputType.url,
      ),
    ),
  );

  final url = field.text.trim();
  field.dispose();
  if (accepted != true || url.isEmpty) return null;

  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return null;
  return MoveMedia(
    id: '${DateTime.now().microsecondsSinceEpoch}',
    kind: MediaKind.link,
    value: url,
  );
}

Future<MoveMedia?> _capture(
  BuildContext context, {
  required bool image,
  required ImageSource source,
  required MediaKind kind,
}) async {
  try {
    final picker = ImagePicker();
    final picked = image
        ? await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85)
        : await picker.pickVideo(source: source);
    if (picked == null || !context.mounted) return null;
    final path = await MediaStore.importXFile(
      picked,
      fallbackExtension: image ? 'jpg' : 'mp4',
    );
    return MoveMedia(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      value: path,
    );
  } catch (_) {
    // Permission denied or camera unavailable: treat as cancelled.
    return null;
  }
}
