import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/battle.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/battle_countdown.dart';

/// Starts a plan with the common stages, or edits the one already running.
Future<void> showPlanSheet(BuildContext context) async {
  await showBrkSheet(
    context: context,
    builder: (_) => const PlanSheet(),
  );
}

class PlanSheet extends StatefulWidget {
  const PlanSheet({super.key});

  @override
  State<PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<PlanSheet> {
  late final AppState _state = context.read<AppState>();
  late final BattlePlan? _existing = _state.battle.plan;

  final _name = TextEditingController();
  DateTime _eventAt = DateTime.now().add(const Duration(days: 30));

  bool get _canSave => _name.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    if (existing != null) {
      _name.text = existing.name;
      _eventAt = existing.eventAt;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = _existing != null;

    return BrkSheet(
      title: editing ? 'Edit battle' : 'New battle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          BrkField(
            controller: _name,
            label: 'Battle',
            hint: 'Event or battle name',
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          BrkCard(
            onTap: _pickDate,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 19, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Event date',
                          style: context.appTextTheme.titleSmall
                              ?.copyWith(color: AppColors.onSurface)),
                      const SizedBox(height: 3),
                      Text(battleCountdown(_eventAt),
                          style: context.appTextTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BrkButton(
            label: editing ? 'Save battle' : 'Start plan',
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null || !mounted) return;
    setState(() => _eventAt = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final existing = _existing;
    if (existing == null) {
      await _state.battle.start(name: name, eventAt: _eventAt);
    } else {
      await _state.battle.save(
        existing.copyWith(name: name, eventAt: _eventAt),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
