import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/practice_reminder_messages.dart';

/// Practice reminders are the core of the app: every reminder time gets a
/// notification on each of the next [_daysAhead] days, each with a different
/// line from the message pool. The schedule is rebuilt whenever the times
/// change, and the pool is shuffled again so the app never feels scripted.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'breaklog_practice';
  static const _channelName = 'Practice reminder';
  static const _channelDescription = 'A nudge to practice and log it.';
  static const _daysAhead = 30;
  static const _firstId = 1000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initializing;
  bool _ready = false;

  /// Prepares the plugin, the channel and the Android permission. Safe to
  /// call from anywhere; a device that refuses notifications leaves the app
  /// working, just without reminders.
  Future<void> init() => _initializing ??= _setup();

  Future<void> _setup() async {
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } on Exception {
        // Some devices withhold the zone name; UTC keeps the reminder times at
        // a stable offset instead of failing the whole service.
        tz.setLocalLocation(tz.UTC);
      }

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      final android = _androidPlugin();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
        ),
      );
      // Android 13 and up show the system prompt here; older versions grant it
      // at install and this does nothing.
      await android?.requestNotificationsPermission();

      _ready = true;
    } on Exception {
      // Reminders are optional at the platform level. The app keeps running.
    }
  }

  /// Replaces the schedule with [minutes] (minutes after midnight) on each of
  /// the next [_daysAhead] days. Call it whenever the times change and on
  /// every app start, so the window never runs dry.
  Future<void> configure(List<int> minutes) async {
    await init();
    if (!_ready || minutes.isEmpty) return;
    try {
      final exactAllowed =
          await _androidPlugin()?.canScheduleExactNotifications() ?? false;
      final mode = exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.cancelAll();
      final lines = List<String>.from(practiceReminderMessages)..shuffle();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
        ),
      );

      var id = _firstId;
      var line = 0;
      for (final minute in minutes) {
        final first = _nextAt(minute);
        for (var day = 0; day < _daysAhead; day++) {
          await _plugin.zonedSchedule(
            id: id++,
            title: _channelName,
            body: lines[line++ % lines.length],
            scheduledDate: tz.TZDateTime(
              tz.local,
              first.year,
              first.month,
              first.day + day,
              minute ~/ 60,
              minute % 60,
            ),
            notificationDetails: details,
            androidScheduleMode: mode,
          );
        }
      }
    } on Exception {
      // A refusal here costs the reminders, not the app; the next start retries.
    }
  }

  AndroidFlutterLocalNotificationsPlugin? _androidPlugin() =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// The next time this reminder happens, today or tomorrow.
  tz.TZDateTime _nextAt(int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minute ~/ 60,
      minute % 60,
    );
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }
}
