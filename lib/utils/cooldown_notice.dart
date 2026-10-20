import 'package:intl/intl.dart';

/// One line saying when the weekly profile window opens again. Days are counted
/// by calendar day, so a save made today reads as the full week it is. Shown
/// under Save while the window is shut, and in the toast when a save is
/// refused.
String cooldownNotice(DateTime lockEnds) {
  final now = DateTime.now();
  final days = DateTime(lockEnds.year, lockEnds.month, lockEnds.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  final date = DateFormat.yMMMd().format(lockEnds);
  if (days >= 1) {
    return 'Edits open again in $days ${days == 1 ? 'day' : 'days'} ($date)';
  }
  return 'Edits open again today ($date)';
}
