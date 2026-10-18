import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/move.dart';
import '../../models/set.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'set_detail_screen.dart';

/// Creates or reorders a set: name it, then tick moves from the vocabulary.
class SetBuilderScreen extends StatefulWidget {
  const SetBuilderScreen({super.key, this.existing});

  final MoveSet? existing;

  @override
  State<SetBuilderScreen> createState() => _SetBuilderScreenState();
}

class _SetBuilderScreenState extends State<SetBuilderScreen> {
  late final TextEditingController _name;
  late List<String> _selected;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _selected = [...?widget.existing?.moveIds];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final moves = state.moves.query();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BrkHeader(
              title: _isEdit ? 'Edit set' : 'New set',
              leading: Icons.arrow_back,
              onLeading: () => Navigator.of(context).maybePop(),
              actions: [
                BrkIconButton(
                  icon: Icons.check,
                  accent: true,
                  tooltip: 'Save set',
                  onTap: _canSave ? _save : null,
                ),
                const SizedBox(width: 4),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  BrkField(
                    controller: _name,
                    label: 'Set name',
                    hint: 'e.g. Round one, Warmup rotation',
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Vocabulary',
                          style: context.appTextTheme.titleMedium),
                      const Spacer(),
                      Text('${_selected.length} picked',
                          style: context.appTextTheme.titleSmall
                              ?.copyWith(color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (moves.isEmpty)
                    Text('Log moves first, then build a set around them.',
                        style: context.appTextTheme.bodyMedium)
                  else
                    for (final move in moves) ...[
                      _PickRow(
                        move: move,
                        selected: _selected.contains(move.id),
                        onTap: () => setState(() => _selected.contains(move.id)
                            ? _selected.remove(move.id)
                            : _selected.add(move.id)),
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

  bool get _canSave => _name.text.trim().isNotEmpty && _selected.isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    final state = context.read<AppState>();
    final name = _name.text.trim();

    if (_isEdit) {
      await state.sets.update(
          widget.existing!.copyWith(name: name, moveIds: _selected));
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final navigator = Navigator.of(context);
    final id = '${DateTime.now().microsecondsSinceEpoch}';
    await state.sets.add(MoveSet(
      id: id,
      name: name,
      moveIds: _selected,
      createdAt: DateTime.now(),
    ));
    navigator.pop();
    navigator.push(
      MaterialPageRoute(builder: (_) => SetDetailScreen(setId: id)),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.move,
    required this.selected,
    required this.onTap,
  });

  final BboyMove move;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.outline,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    move.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextTheme.titleSmall
                        ?.copyWith(color: AppColors.onSurface, fontSize: 15),
                  ),
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
            const SizedBox(width: 10),
            BrkDifficultyDots(level: move.difficulty, size: 6),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.outline,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 15, color: AppColors.onAccent)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
