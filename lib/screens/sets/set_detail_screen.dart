import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/move.dart';
import '../../services/media_store.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/media_actions.dart';
import '../detail/move_detail_screen.dart';
import 'set_builder_screen.dart';

/// One saved set in order. Tapping a row opens the move; the trailing control
/// drops it from the set without touching the vocabulary.
class SetDetailScreen extends StatelessWidget {
  const SetDetailScreen({super.key, required this.setId});

  final String setId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final set = state.sets.byId(setId);

    if (set == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              BrkHeader(
                title: 'Set',
                leading: Icons.arrow_back,
                onLeading: () => Navigator.of(context).maybePop(),
              ),
              const Expanded(
                child: BrkEmptyState(
                  icon: Icons.block,
                  title: 'Set no longer exists',
                  message: 'It was deleted from your saved sets.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final moves = [
      for (final id in set.moveIds)
        if (state.moves.byId(id) case final move?) move,
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BrkHeader(
              title: set.name,
              eyebrow: moves.isEmpty ? 'empty set' : '${moves.length} moves',
              leading: Icons.arrow_back,
              onLeading: () => Navigator.of(context).maybePop(),
              actions: [
                BrkIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit set',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => SetBuilderScreen(existing: set)),
                  ),
                ),
                BrkIconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete set',
                  danger: true,
                  onTap: () => _confirmDelete(context, state, set.id, set.name),
                ),
                const SizedBox(width: 4),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  if (set.media.isNotEmpty) ...[
                    Text('Media',
                        style: context.appTextTheme.titleMedium?.copyWith(
                            color: AppColors.onSurface, fontSize: 16)),
                    const SizedBox(height: 10),
                    for (final media in set.media) ...[
                      BrkMediaTile(
                        media: media,
                        onOpen: () => openMedia(context, media),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 18),
                  ],
                  if (moves.isEmpty)
                    const BrkEmptyState(
                      icon: Icons.queue_music_outlined,
                      title: 'This set is empty',
                      message:
                          'Edit the set to pick moves from your vocabulary.',
                    )
                  else
                    for (var i = 0; i < moves.length; i++) ...[
                      _MoveRow(
                        index: i,
                        move: moves[i],
                        onRemove: () => state.sets.update(
                          set.copyWith(
                            moveIds: [
                              for (final id in set.moveIds)
                                if (id != moves[i].id) id,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState state,
      String setId, String name) async {
    final confirmed = await showBrkDialog<bool>(
      context: context,
      builder: (ctx) => BrkDialog(
        title: 'Delete set?',
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
          '"$name" will be removed. Your vocabulary moves stay untouched.',
          style: context.appTextTheme.bodyMedium
              ?.copyWith(color: AppColors.onSurface),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final set = state.sets.byId(setId);
    for (final media in set?.media ?? const []) {
      if (!media.isRemote) await MediaStore.remove(media.value);
    }
    await state.sets.remove(setId);
    if (context.mounted) Navigator.of(context).pop();
  }
}

/// One numbered set member, with a control that drops it from this set only.
class _MoveRow extends StatelessWidget {
  const _MoveRow({
    required this.index,
    required this.move,
    required this.onRemove,
  });

  final int index;
  final BboyMove move;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14, top: 12, bottom: 12, right: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Text('${index + 1}'.padLeft(2, '0'),
              style: context.appTextTheme.titleSmall
                  ?.copyWith(color: AppColors.accent)),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MoveDetailScreen(moveId: move.id),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(move.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextTheme.titleLarge?.copyWith(
                          color: AppColors.onSurface, fontSize: 18)),
                  const SizedBox(height: 5),
                  Text(
                    [move.category, move.depth.label]
                        .where((s) => s.isNotEmpty)
                        .join('   '),
                    style: context.appTextTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          BrkDifficultyDots(level: move.difficulty, size: 6),
          const SizedBox(width: 4),
          BrkIconButton(
            icon: Icons.remove_circle_outline,
            size: 40,
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}
