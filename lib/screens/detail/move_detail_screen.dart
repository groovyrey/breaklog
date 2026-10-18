import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/move.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
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
        appBar: AppBar(),
        body: const Center(child: Text('Move no longer exists')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: move.favorite ? 'Unfavorite' : 'Favorite',
            onPressed: () => state.moves.toggleFavorite(move.id),
            icon: Icon(
              move.favorite ? Icons.favorite : Icons.favorite_border,
              color: move.favorite ? AppColors.accent : null,
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => AddEditMoveScreen(existing: move)),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, state, move),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Text(move.category.label.toUpperCase(),
              style: context.appTextTheme.labelSmall
                  ?.copyWith(color: AppColors.accent)),
          const SizedBox(height: 6),
          Text(move.name, style: context.appTextTheme.headlineMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              _Pill(label: move.difficultyLabel),
              const SizedBox(width: 8),
              _Pill(
                label:
                    'Logged ${move.learnedAt.toLocal().toString().split(' ').first}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (move.notes.isNotEmpty) ...[
            Text('Notes', style: context.appTextTheme.titleMedium),
            const SizedBox(height: 6),
            Text(move.notes, style: context.appTextTheme.bodyLarge),
            const SizedBox(height: 20),
          ],
          if (move.videoUrl.isNotEmpty) ...[
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(move.videoUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Watch reference'),
            ),
            const SizedBox(height: 8),
            Text(move.videoUrl, style: context.appTextTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state, BboyMove move) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('Delete move?'),
        content: Text('"${move.name}" will be removed permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await state.moves.remove(move.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.outline),
      ),
      child: Text(label, style: context.appTextTheme.labelMedium),
    );
  }
}
