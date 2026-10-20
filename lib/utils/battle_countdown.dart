import 'package:intl/intl.dart';

/// How far off a battle is, in plain words. Falls back to the date once the
/// event is more than a week out, so the line stays useful without a countdown.
String battleCountdown(DateTime eventAt, {DateTime? now}) {
  final today = _dayOf(now ?? DateTime.now());
  final eventDay = _dayOf(eventAt);
  final days = eventDay.difference(today).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days > 1 && days <= 7) return 'In $days days';
  if (days == -1) return 'Yesterday';
  if (days < -1) return '${-days} days ago';
  return DateFormat('MMM d, y').format(eventAt);
}

DateTime _dayOf(DateTime value) =>
    DateTime(value.year, value.month, value.day);
