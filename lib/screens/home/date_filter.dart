import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/index.dart';
import '../../theme/app_theme.dart';

/// Year, month and day choices for the All list. Each button opens a sheet
/// whose first row is Any, so a filter can be cleared the same way it is set.
class DateFilter extends StatelessWidget {
  const DateFilter({
    super.key,
    required this.year,
    required this.month,
    required this.day,
    required this.years,
    required this.onYear,
    required this.onMonth,
    required this.onDay,
  });

  final int? year;
  final int? month;
  final int? day;

  /// Every year present in the notes, newest first.
  final List<int> years;

  final ValueChanged<int?> onYear;
  final ValueChanged<int?> onMonth;
  final ValueChanged<int?> onDay;

  /// Longest month the current year and month can have, so the day list never
  /// offers a date that cannot exist.
  int get _daysInMonth =>
      year != null && month != null ? DateTime(year!, month! + 1, 0).day : 31;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: _FilterButton(
              label: 'Year',
              value: year?.toString() ?? 'Any',
              active: year != null,
              onTap: () => _pickYear(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterButton(
              label: 'Month',
              value: month == null
                  ? 'Any'
                  : DateFormat.MMM().format(DateTime(2000, month!)),
              active: month != null,
              onTap: () => _pickMonth(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterButton(
              label: 'Day',
              value: day?.toString() ?? 'Any',
              active: day != null,
              onTap: () => _pickDay(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickYear(BuildContext context) async {
    final result = await _pick(
      context,
      title: 'Year',
      options: [
        const (label: 'Any', value: null),
        for (final y in years) (label: '$y', value: y),
      ],
    );
    if (result.apply) onYear(result.value);
  }

  Future<void> _pickMonth(BuildContext context) async {
    final result = await _pick(
      context,
      title: 'Month',
      options: [
        const (label: 'Any', value: null),
        for (var m = 1; m <= 12; m++)
          (label: DateFormat.MMM().format(DateTime(2000, m)), value: m),
      ],
    );
    if (result.apply) onMonth(result.value);
  }

  Future<void> _pickDay(BuildContext context) async {
    final result = await _pick(
      context,
      title: 'Day',
      options: [
        const (label: 'Any', value: null),
        for (var d = 1; d <= _daysInMonth; d++) (label: '$d', value: d),
      ],
    );
    if (result.apply) onDay(result.value);
  }

  /// Runs the option sheet. Dismissing it does not change the filter, so a
  /// choice of null (Any) stays distinguishable from backing out.
  Future<({bool apply, int? value})> _pick(
    BuildContext context, {
    required String title,
    required List<({String label, int? value})> options,
  }) async {
    var apply = false;
    int? chosen;
    await showBrkSheet<void>(
      context: context,
      builder: (ctx) => BrkSheet(
        title: title,
        child: BrkSheetOptions(
          children: [
            for (final option in options)
              BrkOptionTile(
                title: option.label,
                onTap: () {
                  apply = true;
                  chosen = option.value;
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    );
    return (apply: apply, value: chosen);
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTextTheme;

    return BrkCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.titleSmall?.copyWith(
              color: active ? AppColors.accent : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
