import 'package:flutter/foundation.dart';
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
      await _setLocalZone();

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
      // Android 12 and up gate exact alarms; older versions always allow them
      // and this is a no-op.
      await android?.requestExactAlarmsPermission();

      _ready = true;
      debugPrint('reminders ready in zone ${tz.local.name}');
    } on Object catch (error, stack) {
      // Reminders are optional at the platform level. The app keeps running,
      // and the reason is logged so a device that never shows one can be read.
      debugPrint('reminders setup failed: $error\n$stack');
    }
  }

  /// Resolves the device zone, keeping the plugin's value when it is one the
  /// time zone database knows. Falls back to UTC only as a last resort, which
  /// shifts the reminder times by the device offset.
  Future<void> _setLocalZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      return;
    } on Object catch (error) {
      debugPrint('reminders zone lookup failed: $error');
    }
    tz.setLocalLocation(tz.UTC);
    debugPrint('reminders fell back to UTC');
  }

  /// Replaces the schedule with [minutes] (minutes after midnight) on each of
  /// the next [_daysAhead] days. Call it whenever the times change and on
  /// every app start, so the window never runs dry.
  Future<void> configure(List<int> minutes) async {
    await init();
    if (!_ready) {
      debugPrint('reminders skipped: setup not ready');
      return;
    }
    if (minutes.isEmpty) return;
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
      var scheduled = 0;
      Object? firstError;
      for (final minute in minutes) {
        final first = _nextAt(minute);
        for (var day = 0; day < _daysAhead; day++) {
          try {
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
            scheduled++;
          } on Object catch (error) {
            // One refused slot must not cost the rest of the window.
            firstError ??= error;
          }
        }
      }
      debugPrint(
        'reminders scheduled $scheduled in ${tz.local.name} mode $mode'
        '${firstError == null ? '' : ', first error: $firstError'}',
      );
    } on Object catch (error, stack) {
      debugPrint('reminders configure failed: $error\n$stack');
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
