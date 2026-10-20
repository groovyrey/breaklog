import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/media.dart';
import '../../models/note.dart';
import '../../services/media_store.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/media_actions.dart';
import '../edit/media_picker.dart';

/// Opens the composer for [note], or a fresh one when null, and toasts what
/// happened once the sheet closes.
Future<void> showNoteSheet(BuildContext context, {LogNote? note}) async {
  final outcome = await showBrkSheet<String>(
    context: context,
    builder: (_) => NoteSheet(note: note),
  );
  if (outcome == null || !context.mounted) return;
  showBrkToast(
    context,
    outcome,
    icon: outcome == 'Note deleted'
        ? Icons.delete_outline
        : Icons.check_circle_outline,
  );
}

/// Writes or edits one note: the body, its attachments, and delete when the
/// note already exists.
class NoteSheet extends StatefulWidget {
  const NoteSheet({super.key, this.note});

  final LogNote? note;

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  late final TextEditingController _body;
  late final List<MoveMedia> _media;

  bool get _editing => widget.note != null;

  bool get _canSave => _body.text.trim().isNotEmpty || _media.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _body = TextEditingController(text: widget.note?.body);
    _media = [...?widget.note?.media];
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BrkSheet(
      title: _editing ? 'Edit note' : 'Add note',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          BrkField(
            controller: _body,
            label: 'Note',
            hint: 'What happened at practice?',
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          _label('Media'),
          const SizedBox(height: 10),
          if (_media.isNotEmpty) ...[
            for (var i = 0; i < _media.length; i++) ...[
              BrkMediaTile(
                media: _media[i],
                onOpen: () => openMedia(context, _media[i]),
                onRemove: () => setState(() => _media.removeAt(i)),
              ),
              const SizedBox(height: 8),
            ],
          ],
          BrkButton(
            label: 'Attach media',
            variant: BrkButtonVariant.secondary,
            icon: Icons.attach_file,
            onPressed: _addMedia,
          ),
          const SizedBox(height: 24),
          BrkButton(
            label: _editing ? 'Save changes' : 'Save note',
            onPressed: _canSave ? _save : null,
          ),
          if (_editing) ...[
            const SizedBox(height: 10),
            BrkButton(
              label: 'Delete note',
              variant: BrkButtonVariant.danger,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: context.appTextTheme.labelSmall
            ?.copyWith(color: AppColors.onSurfaceVariant),
      );

  Future<void> _addMedia() async {
    final media = await pickBrkMedia(context);
    if (media == null || !mounted) return;
    setState(() => _media.add(media));
  }

  Future<void> _save() async {
    final notes = context.read<AppState>().notes;
    final text = _body.text.trim();
    final existing = widget.note;
    if (existing != null) {
      await notes.update(existing.copyWith(body: text, media: _media));
    } else {
      await notes.add(LogNote(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        body: text,
        createdAt: DateTime.now(),
        media: _media,
      ));
    }
    if (!mounted) return;
    Navigator.of(context)
        .pop(existing == null ? 'Note saved' : 'Note updated');
  }

  Future<void> _delete() async {
    final existing = widget.note;
    if (existing == null) return;
    final notes = context.read<AppState>().notes;
    for (final media in existing.media) {
      if (!media.isRemote) await MediaStore.remove(media.value);
    }
    await notes.remove(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop('Note deleted');
  }
}
