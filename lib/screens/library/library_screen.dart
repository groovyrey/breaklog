import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/move.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/move_card.dart';
import '../edit/add_edit_move_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _search = '';
  MoveCategory? _category;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final moves = state.moves.query(search: _search, category: _category);

    return Scaffold(
      appBar: AppBar(
        title: Text('BreakLog', style: context.appTextTheme.headlineSmall),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditMoveScreen()),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        icon: const Icon(Icons.add),
        label: const Text('Log move'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search moves or notes',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in MoveCategory.values)
                  _CategoryChip(
                    label: c.label,
                    icon: c.icon,
                    selected: _category == c,
                    onTap: () =>
                        setState(() => _category = _category == c ? null : c),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: moves.isEmpty
                ? EmptyState(
                    icon: Icons.style_outlined,
                    title: state.moves.count == 0
                        ? 'No moves logged'
                        : 'Nothing matches',
                    message: state.moves.count == 0
                        ? 'Log your first toprock, footwork, power, or freeze.'
                        : 'Try a different search or category.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: moves.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => MoveCard(move: moves[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 14,
                    color: selected
                        ? AppColors.accent
                        : AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: context.appTextTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.accent : AppColors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
