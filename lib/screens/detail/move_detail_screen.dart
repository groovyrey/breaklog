import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/media.dart';
import '../../models/move.dart';
import '../../state/app_state.dart';
import '../../services/media_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/media_actions.dart';
import '../edit/add_edit_move_screen.dart';

class MoveDetailScreen extends StatelessWidget {
  const MoveDetailScreen({super.key, required this.moveId});

  final String moveId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final move = state.moves.byId(moveId);

    if (move == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              BrkHeader(
                title: 'Move',
                leading: Icons.arrow_back,
                onLeading: () => Navigator.of(context).maybePop(),
              ),
              const Expanded(
                child: BrkEmptyState(
                  icon: Icons.block,
                  title: 'Move no longer exists',
                  message: 'It was removed from your vocabulary.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BrkHeader(
              eyebrow: move.category.isEmpty ? null : move.category,
              title: move.name,
              leading: Icons.arrow_back,
              onLeading: () => Navigator.of(context).maybePop(),
              actions: [
                BrkIconButton(
                  icon: move.favorite ? Icons.favorite : Icons.favorite_border,
                  tooltip: move.favorite ? 'Unfavorite' : 'Favorite',
                  accent: move.favorite,
                  onTap: () => state.moves.toggleFavorite(move.id),
                ),
                BrkIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => AddEditMoveScreen(existing: move)),
                  ),
                ),
                BrkIconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete',
                  danger: true,
                  onTap: () => _confirmDelete(context, state, move),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  BrkCard(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                    child: Column(
                      children: [
                        BrkRow(
                          label: 'Category',
                          value: move.category.isEmpty
                              ? 'Uncategorized'
                              : move.category,
                        ),
                        const Divider(height: 1),
                        BrkRow(
                          label: 'Difficulty',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BrkDifficultyDots(level: move.difficulty),
                              const SizedBox(width: 10),
                              Text(
                                '${move.difficulty} / 5 · ${move.difficultyLabel}',
                                style: context.appTextTheme.titleSmall
                                    ?.copyWith(
                                        color:
                                            AppColors.difficulty(move.difficulty)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        BrkRow(label: 'Depth', value: move.depth.label),
                        const Divider(height: 1),
                        BrkRow(
                          label: 'Logged on',
                          value: DateFormat.yMMMd()
                              .add_jm()
                              .format(move.learnedAt.toLocal()),
                        ),
                        const Divider(height: 1),
                        BrkRow(
                          label: 'Attachments',
                          value: move.media.isEmpty
                              ? 'None'
                              : '${move.media.length} '
                                  '${move.media.length == 1 ? 'file' : 'files'}',
                        ),
                      ],
                    ),
                  ),
                  if (move.notes.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    Text('Notes',
                        style: context.appTextTheme.titleMedium?.copyWith(
                            color: AppColors.onSurface, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(move.notes, style: context.appTextTheme.bodyLarge),
                  ],
                  if (move.media.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    Text('Media',
                        style: context.appTextTheme.titleMedium?.copyWith(
                            color: AppColors.onSurface, fontSize: 16)),
                    const SizedBox(height: 10),
                    for (var i = 0; i < move.media.length; i++) ...[
                      BrkMediaTile(
                        media: move.media[i],
                        onOpen: () => _openMedia(context, move.media[i]),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                  if (move.notes.isEmpty && move.media.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: Text(
                        'No notes or media on this move yet.',
                        style: context.appTextTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMedia(BuildContext context, MoveMedia media) =>
      openMedia(context, media);

  Future<void> _confirmDelete(
      BuildContext context, AppState state, BboyMove move) async {
    final confirmed = await showBrkDialog<bool>(
      context: context,
      builder: (ctx) => BrkDialog(
        title: 'Delete move?',
        actions: [
          BrkButton(
            label: 'Cancel',
            variant: BrkButtonVariant.secondary,
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          BrkButton(
            label: 'Delete',
            variant: BrkButtonVariant.danger,
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
        child: Text(
          '"${move.name}" will be removed from your vocabulary.',
          style: context.appTextTheme.bodyMedium
              ?.copyWith(color: AppColors.onSurface),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    for (final media in move.media) {
      if (!media.isRemote) await MediaStore.remove(media.value);
    }
    await state.moves.remove(move.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}
