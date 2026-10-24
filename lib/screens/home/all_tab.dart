import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../models/note.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'date_filter.dart';
import 'note_card.dart';

/// All tab: every note matching the shared search and the date filter, grouped
/// by the day they were written, newest groups first.
class AllTab extends StatefulWidget {
  const AllTab({super.key, required this.query});

  final String query;

  @override
  State<AllTab> createState() => _AllTabState();
}

class _AllTabState extends State<AllTab> {
  int? _year;
  int? _month;
  int? _day;

  bool _passes(LogNote note) =>
      (_year == null || note.createdAt.year == _year) &&
      (_month == null || note.createdAt.month == _month) &&
      (_day == null || note.createdAt.day == _day);

  String _heading(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference =
        today.difference(DateTime(day.year, day.month, day.day)).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('MMMM d, y').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<AppState>().notes;
    final results = notes.query(search: widget.query).where(_passes).toList();
    final nothingWritten = notes.count == 0;

    final groups = <DateTime, List<LogNote>>{};
    for (final note in results) {
      final day =
          DateTime(note.createdAt.year, note.createdAt.month, note.createdAt.day);
      groups.putIfAbsent(day, () => []).add(note);
    }

    final years = notes.notes.map((n) => n.createdAt.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DateFilter(
          year: _year,
          month: _month,
          day: _day,
          years: years,
          onYear: (value) => setState(() => _year = value),
          onMonth: (value) => setState(() => _month = value),
          onDay: (value) => setState(() => _day = value),
        ),
        Expanded(
          child: results.isEmpty
              ? BrkEmptyState(
                  icon: Icons.event_note_outlined,
                  title: nothingWritten ? 'No notes yet' : 'Nothing matches',
                  message: nothingWritten
                      ? 'Tap the plus in the bar to write one.'
                      : 'Clear the search or the date filter.',
                )
              : ListView(
                  padding:
                      EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 90),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                        child: Text(
                          _heading(entry.key).toUpperCase(),
                          style: context.appTextTheme.labelSmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                      for (var i = 0; i < entry.value.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: NoteCard(note: entry.value[i]),
                        ),
                      ],
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
