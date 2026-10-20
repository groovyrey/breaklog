import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/prep_item.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Asks for one prep item and adds it to the checklist.
Future<void> showAddPrepItem(BuildContext context) async {
  final text = await showBrkSheet<String>(
    context: context,
    builder: (_) => const _PrepItemSheet(),
  );
  if (text == null || !context.mounted) return;
  await context.read<AppState>().prep.add(
        PrepItem(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          text: text,
          done: false,
          createdAt: DateTime.now(),
        ),
      );
}

/// Prep tab: the checklist of things to get ready before the battle. Tapping a
/// row ticks it off; ticking sinks it below the open items.
class PrepTab extends StatelessWidget {
  const PrepTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.prep.items;

    if (items.isEmpty) {
      return BrkEmptyState(
        icon: Icons.checklist_outlined,
        title: 'Nothing to prepare yet',
        message: 'Add what you want ready for the battle.',
      );
    }

    final theme = context.appTextTheme;

    return ListView(
      padding: EdgeInsets.only(
        top: 18,
        bottom: brkFloatingBarInset(context),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            'To do: ${state.prep.openCount} of ${state.prep.count}'.toUpperCase(),
            style: theme.labelSmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PrepRow(item: items[i]),
          ),
        ],
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: BrkCard(
            onTap: () => showAddPrepItem(context),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.add,
                    size: 19, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add a prep item',
                    style: theme.titleSmall
                        ?.copyWith(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One prep row. Tapping toggles done; the trailing control removes it.
class _PrepRow extends StatelessWidget {
  const _PrepRow({required this.item});

  final PrepItem item;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTextTheme;
    final state = context.read<AppState>();

    return BrkCard(
      onTap: () => state.prep.update(item.copyWith(done: !item.done)),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          BrkIconButton(
            icon: item.done ? Icons.check_box : Icons.check_box_outline_blank,
            size: 36,
            accent: item.done,
            onTap: () => state.prep.update(item.copyWith(done: !item.done)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.text,
              style: theme.bodyMedium?.copyWith(
                color:
                    item.done ? AppColors.onSurfaceVariant : AppColors.onSurface,
                decoration: item.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          BrkIconButton(
            icon: Icons.close,
            size: 36,
            tooltip: 'Remove item',
            onTap: () => state.prep.remove(item.id),
          ),
        ],
      ),
    );
  }
}

/// Writes one prep item. Pops the trimmed text, or null when cancelled.
class _PrepItemSheet extends StatefulWidget {
  const _PrepItemSheet();

  @override
  State<_PrepItemSheet> createState() => _PrepItemSheetState();
}

class _PrepItemSheetState extends State<_PrepItemSheet> {
  final _text = TextEditingController();

  bool get _canSave => _text.text.trim().isNotEmpty;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BrkSheet(
      title: 'Add prep item',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          BrkField(
            controller: _text,
            label: 'Item',
            hint: 'What do you want ready?',
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          BrkButton(
            label: 'Add item',
            onPressed: _canSave
                ? () => Navigator.of(context).pop(_text.text.trim())
                : null,
          ),
        ],
      ),
    );
  }
}
