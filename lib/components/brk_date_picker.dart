import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brk_button.dart';
import 'brk_dialog.dart';

/// Calendar picker owned by the app. Replaces the Material date picker
/// entirely: our grid, our arrows, our confirm button.
Future<DateTime?> pickBrkDate(
  BuildContext context, {
  required DateTime initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showBrkDialog<DateTime>(
    context: context,
    builder: (_) => _BrkDatePicker(
      initial: initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime.now(),
    ),
  );
}

class _BrkDatePicker extends StatefulWidget {
  const _BrkDatePicker({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_BrkDatePicker> createState() => _BrkDatePickerState();
}

class _BrkDatePickerState extends State<_BrkDatePicker> {
  late DateTime _visibleMonth;
  DateTime? _selected;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];
  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _visibleMonth =
        DateTime(widget.initial.year, widget.initial.month, 1);
    _selected = widget.initial;
  }

  bool get _canGoBack {
    final prev = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    return !prev.isBefore(DateTime(widget.firstDate.year, widget.firstDate.month, 1));
  }

  bool get _canGoForward {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    return !next.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month, 1));
  }

  void _shift(int delta) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BrkDialog(
      title: 'Pick a date',
      actions: [
        BrkButton(
          label: 'Cancel',
          variant: BrkButtonVariant.secondary,
          expand: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        BrkButton(
          label: 'Use date',
          expand: false,
          onPressed: () => Navigator.of(context).pop(_selected),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              BrkIconButton(
                icon: Icons.chevron_left,
                size: 38,
                onTap: _canGoBack ? () => _shift(-1) : null,
              ),
              Expanded(
                child: Text(
                  '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: context.appTextTheme.titleMedium
                      ?.copyWith(color: AppColors.onSurface),
                ),
              ),
              BrkIconButton(
                icon: Icons.chevron_right,
                size: 38,
                onTap: _canGoForward ? () => _shift(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context.appTextTheme.labelSmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Flexible(child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final firstOfMonth = _visibleMonth;
    final leading = (firstOfMonth.weekday + 6) % 7;
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(_dayCell(day));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1,
      children: cells,
    );
  }

  Widget _dayCell(int day) {
    final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final outOfRange = date.isBefore(DateTime(
            widget.firstDate.year, widget.firstDate.month, widget.firstDate.day)) ||
        date.isAfter(DateTime(
            widget.lastDate.year, widget.lastDate.month, widget.lastDate.day));
    final selected = _selected != null &&
        _selected!.year == date.year &&
        _selected!.month == date.month &&
        _selected!.day == date.day;

    return GestureDetector(
      onTap: outOfRange ? null : () => setState(() => _selected = date),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
          ),
        ),
        child: Text(
          '$day',
          style: context.appTextTheme.titleSmall?.copyWith(
            color: outOfRange
                ? AppColors.outline
                : selected
                    ? AppColors.onAccent
                    : AppColors.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
