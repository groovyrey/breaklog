import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../constants/battle_stages.dart';
import '../../models/battle_session.dart';
import '../../services/media_store.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/duration_label.dart';
import 'plan_widgets.dart';

/// Videos recorded while simulating this plan, newest first.
class RecordedSessionsSection extends StatelessWidget {
  const RecordedSessionsSection({
    super.key,
    required this.sessions,
  });

  final List<BattleSession> sessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PlanSectionLabel('Recorded sessions'),
        if (sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: BrkCard(
              child: Text(
                'No recorded sessions yet.',
                style: context.appTextTheme.bodySmall,
              ),
            ),
          )
        else
          for (var i = 0; i < sessions.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SessionRow(session: sessions[i]),
            ),
          ],
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final BattleSession session;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTextTheme;
    final labels = session.stages
        .map((stage) => battleStageLabel(stage.stage))
        .join(', ');

    return BrkCard(
      onTap: () => showBrkVideoViewer(context, session.videoPath, cover: true),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline,
              size: 22, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labels.isEmpty ? 'Session' : labels,
                  style: theme.titleSmall?.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat.yMMMd().format(session.recordedAt)}, '
                  '${sessionLengthLabel(session.elapsedSeconds)}',
                  style: theme.bodySmall,
                ),
              ],
            ),
          ),
          BrkIconButton(
            icon: Icons.delete_outline,
            size: 36,
            danger: true,
            tooltip: 'Delete session',
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final accepted = await showBrkDialog<bool>(
      context: context,
      builder: (ctx) => BrkDialog(
        title: 'Delete session',
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
          'This removes the video from the plan and this device.',
          style: ctx.appTextTheme.bodyMedium,
        ),
      ),
    );
    if (accepted != true || !context.mounted) return;

    final state = context.read<AppState>();
    await state.sessions.remove(session.id);
    await MediaStore.remove(session.videoPath);
    if (context.mounted) {
      showBrkToast(context, 'Session deleted', icon: Icons.delete_outline);
    }
  }
}
