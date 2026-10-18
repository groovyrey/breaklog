import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/move.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class AddEditMoveScreen extends StatefulWidget {
  const AddEditMoveScreen({super.key, this.existing});

  final BboyMove? existing;

  @override
  State<AddEditMoveScreen> createState() => _AddEditMoveScreenState();
}

class _AddEditMoveScreenState extends State<AddEditMoveScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late final TextEditingController _video;
  late MoveCategory _category;
  late int _difficulty;
  late DateTime _learnedAt;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = TextEditingController(text: m?.name ?? '');
    _notes = TextEditingController(text: m?.notes ?? '');
    _video = TextEditingController(text: m?.videoUrl ?? '');
    _category = m?.category ?? MoveCategory.footwork;
    _difficulty = m?.difficulty ?? 3;
    _learnedAt = m?.learnedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit move' : 'Log move',
            style: context.appTextTheme.headlineSmall),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. 6-step, windmill, baby freeze',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            Text('Category', style: context.appTextTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in MoveCategory.values)
                  ChoiceChip(
                    label: Text(c.label),
                    selected: _category == c,
                    selectedColor: AppColors.accentSoft,
                    labelStyle: TextStyle(
                      color: _category == c
                          ? AppColors.accent
                          : AppColors.onSurfaceVariant,
                      fontWeight:
                          _category == c ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                        color: _category == c
                            ? AppColors.accent
                            : AppColors.outline),
                    backgroundColor: AppColors.surface,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Difficulty', style: context.appTextTheme.titleSmall),
                const Spacer(),
                Text(
                  BboyMove(
                    id: '',
                    name: '',
                    category: _category,
                    difficulty: _difficulty,
                    learnedAt: DateTime.now(),
                  ).difficultyLabel,
                  style: context.appTextTheme.titleSmall
                      ?.copyWith(color: AppColors.accent),
                ),
              ],
            ),
            Slider(
              value: _difficulty.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: AppColors.accent,
              inactiveColor: AppColors.surfaceVariant,
              onChanged: (v) => setState(() => _difficulty = v.round()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notes,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'What clicks, what to drill next…',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _video,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Video URL (optional)',
                hintText: 'https://…',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.hasAbsolutePath) {
                  return 'Enter a valid URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event,
                  color: AppColors.onSurfaceVariant),
              title: const Text('Learned on'),
              subtitle: Text(_learnedAt.toLocal().toString().split(' ').first),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _learnedAt,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _learnedAt = picked);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Save changes' : 'Log move'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final name = _name.text.trim();
    if (_isEdit) {
      await state.moves.update(widget.existing!.copyWith(
        name: name,
        category: _category,
        difficulty: _difficulty,
        notes: _notes.text.trim(),
        videoUrl: _video.text.trim(),
        learnedAt: _learnedAt,
      ));
    } else {
      await state.moves.add(BboyMove(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        category: _category,
        difficulty: _difficulty,
        notes: _notes.text.trim(),
        videoUrl: _video.text.trim(),
        learnedAt: _learnedAt,
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }
}
