import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/index.dart';
import '../../models/note.dart';
import '../../theme/app_theme.dart';
import 'add_note_sheet.dart';

/// One note in a list: the body, when it was written, and a count of its
/// attachments. Tapping opens the composer to edit or open them.
class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note});

  final LogNote note;

  @override
  Widget build(BuildContext context) {
    final attachments = note.media.length;
    final theme = context.appTextTheme;

    return BrkCard(
      onTap: () => showNoteSheet(context, note: note),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.body.isNotEmpty) ...[
            Text(
              note.body,
              style: theme.bodyMedium?.copyWith(
                color: AppColors.onSurface,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Text(
                _timeLabel(note.createdAt),
                style: theme.bodySmall
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              if (attachments > 0) ...[
                const SizedBox(width: 14),
                Icon(
                  BrkMediaTile.iconFor(note.media.first.kind),
                  size: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  '$attachments ${attachments == 1 ? 'attachment' : 'attachments'}',
                  style: theme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Today shows the time only; older notes show date and time, joined with a
  /// comma so the line never reads as a dot-separated run.
  String _timeLabel(DateTime written) {
    final now = DateTime.now();
    final sameDay = written.year == now.year &&
        written.month == now.month &&
        written.day == now.day;
    final time = DateFormat.jm().format(written);
    return sameDay ? time : '${DateFormat.MMMd().format(written)}, $time';
  }
}
