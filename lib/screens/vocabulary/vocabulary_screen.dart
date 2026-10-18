import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import 'move_card.dart';

/// The library half of home: search, a category filter built from the user's
/// own move types, and the move list.
class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final _search = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final categories = state.categories.categories;
    final results = state.moves.query(
      search: _search.text,
      category: _category ?? '',
    );

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrkHeader(
            title: 'Vocabulary',
            eyebrow: state.moves.count == 0
                ? 'nothing logged yet'
                : '${state.moves.count} moves',
            actions: [
              BrkIconButton(
                icon: Icons.bar_chart_outlined,
                tooltip: 'Stats',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                ),
              ),
              const SizedBox(width: 4),
              BrkIconButton(
                icon: Icons.tune,
                tooltip: 'Settings',
                badge: state.hasUpdate,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: BrkField(
              controller: _search,
              hint: 'Search moves or notes',
              suffix: _search.text.isEmpty
                  ? const Icon(Icons.search,
                      size: 18, color: AppColors.onSurfaceVariant)
                  : BrkIconButton(
                      icon: Icons.close,
                      size: 34,
                      onTap: () {
                        _search.clear();
                        setState(() {});
                      },
                    ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                BrkChip(
                  label: 'All',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                const SizedBox(width: 8),
                for (final c in categories) ...[
                  BrkChip(
                    label: c.name,
                    selected: _category == c.name,
                    onTap: () => setState(
                        () => _category = _category == c.name ? null : c.name),
                  ),
                  const SizedBox(width: 8),
                ],
                BrkChip(
                  label: 'New',
                  selected: false,
                  leading: const Icon(Icons.add, size: 15, color: AppColors.accent),
                  onTap: () => _addCategory(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: results.isEmpty
                ? _EmptyVocabulary(
                    searching: _search.text.trim().isNotEmpty || _category != null,
                    hasMoves: state.moves.count > 0,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => MoveCard(move: results[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory() async {
    final field = TextEditingController();
    final result = await showBrkDialog<bool>(
      context: context,
      builder: (ctx) => BrkDialog(
        title: 'New move type',
        actions: [
          BrkButton(
            label: 'Cancel',
            variant: BrkButtonVariant.secondary,
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          BrkButton(
            label: 'Add',
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
        child: BrkField(
          controller: field,
          label: 'Name',
          hint: 'e.g. Airfreeze, Section',
        ),
      ),
    );

    final name = field.text.trim();
    field.dispose();
    if (result != true || name.isEmpty || !mounted) return;
    await context.read<AppState>().categories.add(name);
    if (mounted) setState(() => _category = name);
  }
}

class _EmptyVocabulary extends StatelessWidget {
  const _EmptyVocabulary({required this.searching, required this.hasMoves});

  final bool searching;
  final bool hasMoves;

  @override
  Widget build(BuildContext context) {
    if (searching && hasMoves) {
      return const BrkEmptyState(
        icon: Icons.search_off,
        title: 'Nothing matches',
        message: 'Try another word, or clear the category filter.',
      );
    }
    return const BrkEmptyState(
      icon: Icons.menu_book_outlined,
      title: 'Your vocabulary is empty',
      message: 'Tap the plus to log your first move.',
    );
  }
}
