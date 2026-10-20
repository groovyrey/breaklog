import 'package:intl/intl.dart';

/// Formats a reminder kept as minutes after midnight, for the Settings rows.
String reminderTimeLabel(int minute) =>
    DateFormat.jm().format(DateTime(2000, 1, 1, minute ~/ 60, minute % 60));
