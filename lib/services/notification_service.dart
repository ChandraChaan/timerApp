import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/format.dart';
import '../models/alarm.dart';

/// Channel used for push messages coming from Firebase Cloud Messaging.
const AndroidNotificationChannel kPushChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
  playSound: true,
);

const AndroidNotificationChannel kAlarmChannel = AndroidNotificationChannel(
  'alarm_channel',
  'Alarms',
  description: 'Rings when one of your alarms goes off.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

const AndroidNotificationChannel kTimerChannel = AndroidNotificationChannel(
  'timer_channel',
  'Timers',
  description: 'Rings when a countdown timer finishes.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

/// Payload prefixes so a tapped notification can route to the right screen.
const String kAlarmPayloadPrefix = 'alarm:';
const String kSnoozePayloadPrefix = 'snooze:';
const String kTimerPayload = 'timer';

/// Android `Notification.FLAG_INSISTENT`: keep playing the sound until the
/// notification is dismissed, like a real alarm clock.
const int _flagInsistent = 4;

const int _timerNotificationId = 1;

typedef NotificationTapHandler = void Function(String payload);

/// Wraps flutter_local_notifications so the rest of the app never touches the
/// plugin directly. A disabled instance (tests, web) silently does nothing.
class NotificationService {
  NotificationService({this.enabled = true});

  factory NotificationService.disabled() => NotificationService(enabled: false);

  final bool enabled;

  NotificationTapHandler? onTap;

  FlutterLocalNotificationsPlugin? _pluginInstance;

  FlutterLocalNotificationsPlugin get plugin =>
      _pluginInstance ??= FlutterLocalNotificationsPlugin();

  bool get _active => enabled && !kIsWeb;

  /// Initialises the plugin and returns the payload of the notification that
  /// launched the app, if any.
  Future<String?> init() async {
    if (!_active) return null;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: IOSInitializationSettings(),
        macOS: MacOSInitializationSettings(),
      );
      await plugin.initialize(settings, onSelectNotification: _handleSelect);

      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(kPushChannel);
      await android?.createNotificationChannel(kAlarmChannel);
      await android?.createNotificationChannel(kTimerChannel);

      final launch = await plugin.getNotificationAppLaunchDetails();
      if (launch != null && launch.didNotificationLaunchApp) {
        return launch.payload;
      }
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
    return null;
  }

  Future<void> _handleSelect(String? payload) async {
    if (payload != null && payload.isNotEmpty) onTap?.call(payload);
  }

  AndroidNotificationDetails _ringingAndroid(
    AndroidNotificationChannel channel, {
    required bool vibrate,
    required Color color,
  }) {
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.max,
      category: 'alarm',
      fullScreenIntent: true,
      playSound: true,
      enableVibration: vibrate,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      additionalFlags: Int32List.fromList(<int>[_flagInsistent]),
      color: color,
      icon: '@mipmap/ic_launcher',
    );
  }

  NotificationDetails _alarmDetails(Alarm alarm) => NotificationDetails(
        android: _ringingAndroid(kAlarmChannel,
            vibrate: alarm.vibrate, color: const Color(0xFF8B7CFF)),
        iOS: const IOSNotificationDetails(
            presentAlert: true, presentSound: true),
      );

  static int _alarmNotificationId(int alarmId, int slot) => alarmId * 10 + slot;

  static String _alarmTitle(Alarm alarm) =>
      alarm.label.isEmpty ? 'Alarm' : alarm.label;

  static String _alarmBody(Alarm alarm, bool use24h) {
    final time = formatHourMinute(alarm.hour, alarm.minute, use24h: use24h);
    return use24h
        ? '$time · tap to open'
        : '$time ${amPm(alarm.hour)} · tap to open';
  }

  /// Cancels then (re)schedules every notification belonging to [alarm].
  Future<void> scheduleAlarm(Alarm alarm,
      {DateTime? now, bool use24h = false}) async {
    await cancelAlarm(alarm.id);
    if (!_active || !alarm.enabled) return;
    final from = now ?? DateTime.now();
    try {
      if (!alarm.repeats) {
        final at = alarm.oneShotAt ?? alarm.nextOccurrence(from);
        if (!at.isAfter(from)) return;
        await plugin.zonedSchedule(
          _alarmNotificationId(alarm.id, 0),
          _alarmTitle(alarm),
          _alarmBody(alarm, use24h),
          tz.TZDateTime.from(at, tz.local),
          _alarmDetails(alarm),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: '$kAlarmPayloadPrefix${alarm.id}',
        );
        return;
      }
      for (final day in alarm.days) {
        final at = alarm.copyWith(days: <int>{day}).nextOccurrence(from);
        await plugin.zonedSchedule(
          _alarmNotificationId(alarm.id, day),
          _alarmTitle(alarm),
          _alarmBody(alarm, use24h),
          tz.TZDateTime.from(at, tz.local),
          _alarmDetails(alarm),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: '$kAlarmPayloadPrefix${alarm.id}',
        );
      }
    } catch (e) {
      debugPrint('Could not schedule alarm ${alarm.id}: $e');
    }
  }

  /// Cancels the scheduled (and any showing) notifications of an alarm,
  /// excluding a pending snooze.
  Future<void> cancelAlarm(int alarmId) async {
    if (!_active) return;
    try {
      for (var slot = 0; slot <= 7; slot++) {
        await plugin.cancel(_alarmNotificationId(alarmId, slot));
      }
    } catch (e) {
      debugPrint('Could not cancel alarm $alarmId: $e');
    }
  }

  Future<void> scheduleSnooze(Alarm alarm, DateTime at) async {
    if (!_active) return;
    try {
      await plugin.zonedSchedule(
        _alarmNotificationId(alarm.id, 8),
        '${_alarmTitle(alarm)} (snoozed)',
        'Snoozed for ${alarm.snoozeMinutes} min · tap to open',
        tz.TZDateTime.from(at, tz.local),
        _alarmDetails(alarm),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$kSnoozePayloadPrefix${alarm.id}',
      );
    } catch (e) {
      debugPrint('Could not schedule snooze: $e');
    }
  }

  Future<void> cancelSnooze(int alarmId) async {
    if (!_active) return;
    try {
      await plugin.cancel(_alarmNotificationId(alarmId, 8));
    } catch (_) {}
  }

  Future<void> scheduleTimer(DateTime at, {String label = ''}) async {
    await cancelTimer();
    if (!_active || !at.isAfter(DateTime.now())) return;
    try {
      await plugin.zonedSchedule(
        _timerNotificationId,
        label.isEmpty ? "Time's up!" : label,
        'Your timer has finished · tap to stop',
        tz.TZDateTime.from(at, tz.local),
        NotificationDetails(
          android: _ringingAndroid(kTimerChannel,
              vibrate: true, color: const Color(0xFF3DA9FC)),
          iOS: const IOSNotificationDetails(
              presentAlert: true, presentSound: true),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: kTimerPayload,
      );
    } catch (e) {
      debugPrint('Could not schedule timer: $e');
    }
  }

  Future<void> cancelTimer() async {
    if (!_active) return;
    try {
      await plugin.cancel(_timerNotificationId);
    } catch (_) {}
  }

  /// Shows a push message received while the app is in the foreground.
  Future<void> showPush(int id, String? title, String? body) async {
    if (!_active) return;
    try {
      await plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            kPushChannel.id,
            kPushChannel.name,
            channelDescription: kPushChannel.description,
            importance: Importance.high,
            color: const Color(0xFF8B7CFF),
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Could not show push notification: $e');
    }
  }
}
