import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/category.dart';
import '../../models/media.dart';
import '../../models/move.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'media_picker.dart';

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
  late String _category;
  late int _difficulty;
  late MoveDepth _depth;
  late DateTime _learnedAt;
  late List<MoveMedia> _media;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = TextEditingController(text: m?.name ?? '');
    _notes = TextEditingController(text: m?.notes ?? '');
    _category = m?.category ?? '';
    _difficulty = m?.difficulty ?? 3;
    _depth = m?.depth ?? MoveDepth.universal;
    _learnedAt = m?.learnedAt ?? DateTime.now();
    _media = [...?m?.media];
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final categories = state.categories.categories;
    final category = _resolveCategory(categories);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              BrkHeader(
                title: _isEdit ? 'Edit move' : 'Log move',
                leading: Icons.arrow_back,
                onLeading: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    BrkField(
                      controller: _name,
                      label: 'Name',
                      hint: 'e.g. 6-step, windmill, baby freeze',
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    _label('Move type'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in categories)
                          BrkChip(
                            label: c.name,
                            selected: category == c.name,
                            onTap: () => setState(() => _category = c.name),
                          ),
                        BrkChip(
                          label: 'New',
                          selected: false,
                          leading: const Icon(Icons.add,
                              size: 15, color: AppColors.accent),
                          onTap: () => _addCategory(state),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _label('Difficulty'),
                        const Spacer(),
                        Text(
                          '${_difficulty} / 5 · ${BboyMove.labelFor(_difficulty)}',
                          style: context.appTextTheme.titleSmall?.copyWith(
                              color: AppColors.difficulty(_difficulty)),
                        ),
                      ],
                    ),
                    Slider(
                      value: _difficulty.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: AppColors.difficulty(_difficulty),
                      inactiveColor: AppColors.surfaceVariant,
                      onChanged: (v) => setState(() => _difficulty = v.round()),
                    ),
                    const SizedBox(height: 24),
                    _label('Depth'),
                    const SizedBox(height: 10),
                    BrkSegmented<MoveDepth>(
                      value: _depth,
                      options: [
                        for (final d in MoveDepth.values)
                          (value: d, label: d.label),
                      ],
                      onChanged: (d) => setState(() => _depth = d),
                    ),
                    const SizedBox(height: 24),
                    BrkField(
                      controller: _notes,
                      label: 'Notes',
                      hint: 'What clicks, what to drill next',
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),
                    _label('Media'),
                    const SizedBox(height: 10),
                    if (_media.isNotEmpty) ...[
                      for (var i = 0; i < _media.length; i++) ...[
                        BrkMediaTile(
                          media: _media[i],
                          onOpen: () {},
                          onRemove: () =>
                              setState(() => _media.removeAt(i)),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                    BrkButton(
                      label: 'Attach media',
                      variant: BrkButtonVariant.secondary,
                      icon: Icons.attach_file,
                      onPressed: _addMedia,
                    ),
                    const SizedBox(height: 24),
                    _label('Learned on'),
                    const SizedBox(height: 10),
                    BrkCard(
                      onTap: _pickDate,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      child: Row(
                        children: [
                          const Icon(Icons.event_outlined,
                              size: 19, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text(
                            _learnedAt.toLocal().toString().split(' ').first,
                            style: context.appTextTheme.titleSmall
                                ?.copyWith(color: AppColors.onSurface),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.onSurfaceVariant),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    BrkButton(
                      label: _isEdit ? 'Save changes' : 'Log move',
                      onPressed: () => _save(category),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveCategory(List<MoveCategory> cats) {
    if (cats.any((c) => c.name == _category)) return _category;
    return cats.isEmpty ? _category : cats.first.name;
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style:
            context.appTextTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _learnedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _learnedAt = picked);
  }

  Future<void> _addMedia() async {
    final media = await pickBrkMedia(context);
    if (media != null && mounted) setState(() => _media.add(media));
  }

  Future<void> _addCategory(AppState state) async {
    final field = TextEditingController();
    final confirmed = await showBrkDialog<bool>(
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
        child: BrkField(controller: field, label: 'Name', hint: 'e.g. Airfreeze'),
      ),
    );
    final name = field.text.trim();
    field.dispose();
    if (confirmed != true || name.isEmpty || !mounted) return;
    await state.categories.add(name);
    if (mounted) setState(() => _category = name);
  }

  Future<void> _save(String category) async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final name = _name.text.trim();
    if (_isEdit) {
      await state.moves.update(widget.existing!.copyWith(
        name: name,
        category: category,
        difficulty: _difficulty,
        depth: _depth,
        notes: _notes.text.trim(),
        media: _media,
        learnedAt: _learnedAt,
      ));
    } else {
      await state.moves.add(BboyMove(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        category: category,
        difficulty: _difficulty,
        depth: _depth,
        notes: _notes.text.trim(),
        media: _media,
        learnedAt: _learnedAt,
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }
}
