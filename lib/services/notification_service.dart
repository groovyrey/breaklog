import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/engaging_messages.dart';

/// Morning notifications at 6am, one per day, each carrying a different line
/// from the message pool. The schedule is rebuilt on every app start so the
/// next month always sits ready, and the Settings screen can fire one on the
/// spot to show what it looks like.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'breaklog_morning';
  static const _channelName = 'Morning practice';
  static const _channelDescription = 'A daily note at 6am to practice and log it.';
  static const _morningHour = 6;
  static const _daysAhead = 30;
  static const _firstDailyId = 1000;
  static const _testId = 999;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Prepares the plugin, the channel and the next month of mornings. Safe to
  /// call more than once; a failure leaves notifications off, not the app.
  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } on Exception {
        // Some devices withhold the zone name; UTC keeps 6am at a stable
        // offset instead of failing the whole service.
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
      // Android 13 and up show the system prompt here; older versions grant
      // it at install and this does nothing.
      await android?.requestNotificationsPermission();

      _ready = true;
      await scheduleMorningNotifications();
    } on Exception {
      // Notifications are optional. A device that refuses them keeps the app.
    }
  }

  /// Replaces the schedule with the next [_daysAhead] mornings at 6am, each
  /// with its own message. Runs on every app start so the window never runs
  /// dry and the pool does not repeat itself.
  Future<void> scheduleMorningNotifications() async {
    if (!_ready) return;
    final exactAllowed =
        await _androidPlugin()?.canScheduleExactNotifications() ?? false;
    final mode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.cancelAll();
    final lines = List<String>.from(engagingMorningMessages)..shuffle();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
      ),
    );

    for (var day = 0; day < _daysAhead; day++) {
      await _plugin.zonedSchedule(
        id: _firstDailyId + day,
        title: _channelName,
        body: lines[day % lines.length],
        scheduledDate: _nextMorning().add(Duration(days: day)),
        notificationDetails: details,
        androidScheduleMode: mode,
      );
    }
  }

  /// Fires one of the lines right now, the same way 6am will. Reports whether
  /// it could be shown, so the caller can say when notifications are off.
  Future<bool> showTestNow() async {
    if (!_ready) return false;
    final android = _androidPlugin();
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission();
    if (granted != true) return false;

    final lines = List<String>.from(engagingMorningMessages)..shuffle();
    await _plugin.show(
      id: _testId,
      title: _channelName,
      body: lines.first,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
        ),
      ),
    );
    return true;
  }

  AndroidFlutterLocalNotificationsPlugin? _androidPlugin() =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// The next 6am in the device's zone, tomorrow when today's has passed.
  tz.TZDateTime _nextMorning() {
    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _morningHour,
    );
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }
}
