import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';
import '../services/notification_service.dart';
import 'settings_controller.dart';

/// Owns the alarm list: persistence, notification scheduling and detecting
/// when an alarm should ring while the app is open.
class AlarmController extends ChangeNotifier {
  AlarmController(
    this._prefs,
    this._notifications,
    this._settings, {
    DateTime Function()? clock,
  }) : _now = clock ?? _systemNow {
    _alarms = Alarm.decodeList(_prefs.getString(_kAlarms));
    _sort();
    _snoozes = _decodeSnoozes(_prefs.getString(_kSnoozes));
    _expireOneShots();
  }

  static const _kAlarms = 'alarms.list';
  static const _kSnoozes = 'alarms.snoozes';
  static const _kNextId = 'alarms.nextId';

  /// How long after an alarm's time a tapped notification still opens the
  /// ringing screen.
  static const Duration ringWindow = Duration(minutes: 30);

  final SharedPreferences _prefs;
  final NotificationService _notifications;
  final SettingsController _settings;
  final DateTime Function() _now;

  late List<Alarm> _alarms;
  late Map<int, DateTime> _snoozes;
  Timer? _watcher;
  final Set<String> _firedKeys = <String>{};

  /// The alarm currently ringing, if any. The UI shows the ring screen while
  /// this is non-null.
  final ValueNotifier<Alarm?> ringing = ValueNotifier<Alarm?>(null);

  List<Alarm> get alarms => List.unmodifiable(_alarms);

  Alarm? byId(int id) {
    for (final a in _alarms) {
      if (a.id == id) return a;
    }
    return null;
  }

  DateTime? snoozedUntil(int id) => _snoozes[id];

  /// The soonest upcoming ring across all enabled alarms and snoozes.
  MapEntry<Alarm, DateTime>? get nextRing {
    final now = _now();
    MapEntry<Alarm, DateTime>? best;
    for (final alarm in _alarms) {
      if (!alarm.enabled) continue;
      final at = alarm.repeats
          ? alarm.nextOccurrence(now)
          : (alarm.oneShotAt ?? alarm.nextOccurrence(now));
      if (!at.isAfter(now)) continue;
      if (best == null || at.isBefore(best.value)) best = MapEntry(alarm, at);
    }
    _snoozes.forEach((id, at) {
      final alarm = byId(id);
      if (alarm == null || !at.isAfter(now)) return;
      if (best == null || at.isBefore(best!.value)) best = MapEntry(alarm, at);
    });
    return best;
  }

  /// Re-syncs every scheduled notification and starts watching the clock.
  Future<void> start() async {
    await rescheduleAll();
    _watcher?.cancel();
    _watcher = Timer.periodic(const Duration(seconds: 1), (_) => checkDue());
  }

  Future<void> rescheduleAll() async {
    final use24h = _settings.use24hWithoutContext;
    for (final alarm in _alarms) {
      await _notifications.scheduleAlarm(alarm, use24h: use24h);
    }
  }

  int _takeId() {
    final maxExisting = _alarms.fold<int>(0, (m, a) => a.id > m ? a.id : m);
    var next = _prefs.getInt(_kNextId) ?? 1;
    if (next <= maxExisting) next = maxExisting + 1;
    // Keep notification ids (id * 10 + slot) well inside a 32-bit int.
    if (next > 100000000) next = 1;
    _prefs.setInt(_kNextId, next + 1);
    return next;
  }

  Alarm create({
    required int hour,
    required int minute,
    String label = '',
    Set<int> days = const <int>{},
    bool vibrate = true,
    int? snoozeMinutes,
  }) {
    final alarm = _arm(Alarm(
      id: _takeId(),
      hour: hour,
      minute: minute,
      label: label,
      days: days,
      vibrate: vibrate,
      snoozeMinutes: snoozeMinutes ?? _settings.defaultSnooze,
    ));
    _alarms.add(alarm);
    _commit(alarm);
    return alarm;
  }

  void update(Alarm alarm) {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index < 0) return;
    final armed =
        alarm.enabled ? _arm(alarm) : alarm.copyWith(clearOneShot: true);
    _alarms[index] = armed;
    _clearSnooze(alarm.id);
    _commit(armed);
  }

  void setEnabled(Alarm alarm, bool enabled) =>
      update(alarm.copyWith(enabled: enabled));

  void delete(Alarm alarm) {
    _alarms.removeWhere((a) => a.id == alarm.id);
    _clearSnooze(alarm.id);
    _notifications.cancelAlarm(alarm.id);
    _save();
  }

  /// Puts back an alarm removed with [delete] (undo).
  void restore(Alarm alarm) {
    if (byId(alarm.id) != null) return;
    final armed = alarm.enabled ? _arm(alarm) : alarm;
    _alarms.add(armed);
    _commit(armed);
  }

  Alarm _arm(Alarm alarm) {
    if (alarm.repeats || !alarm.enabled) {
      return alarm.copyWith(enabled: alarm.enabled, clearOneShot: true);
    }
    return alarm.copyWith(oneShotAt: alarm.nextOccurrence(_now()));
  }

  void _commit(Alarm alarm) {
    _sort();
    _notifications.scheduleAlarm(alarm, use24h: _settings.use24hWithoutContext);
    _save();
  }

  void _sort() {
    _alarms.sort((a, b) {
      final t = (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
      return t != 0 ? t : a.id.compareTo(b.id);
    });
  }

  void _save() {
    _prefs.setString(_kAlarms, Alarm.encodeList(_alarms));
    _prefs.setString(_kSnoozes, _encodeSnoozes());
    notifyListeners();
  }

  /// Switches off one-shot alarms whose moment has already passed (they
  /// rang while the app was closed).
  void _expireOneShots() {
    final now = _now();
    var changed = false;
    for (var i = 0; i < _alarms.length; i++) {
      final a = _alarms[i];
      if (a.enabled && !a.repeats && a.oneShotAt != null) {
        if (now.difference(a.oneShotAt!) > const Duration(minutes: 1)) {
          _alarms[i] = a.copyWith(enabled: false, clearOneShot: true);
          changed = true;
        }
      }
    }
    _snoozes.removeWhere((_, at) => now.difference(at) > ringWindow);
    if (changed) {
      _prefs.setString(_kAlarms, Alarm.encodeList(_alarms));
    }
  }

  /// Called every second while the app runs. Public for tests.
  void checkDue() {
    final now = _now();
    for (final alarm in _alarms) {
      if (!alarm.enabled) continue;
      if (alarm.hour != now.hour || alarm.minute != now.minute) continue;
      if (alarm.repeats && !alarm.days.contains(now.weekday)) continue;
      if (!alarm.repeats &&
          alarm.oneShotAt != null &&
          (alarm.oneShotAt!.day != now.day ||
              alarm.oneShotAt!.month != now.month)) {
        continue;
      }
      _fire(
          alarm,
          'a${alarm.id}@${now.year}-${now.month}-${now.day}'
          ' ${now.hour}:${now.minute}');
    }
    final dueSnoozes = <int>[];
    _snoozes.forEach((id, at) {
      if (!now.isBefore(at)) dueSnoozes.add(id);
    });
    for (final id in dueSnoozes) {
      final at = _snoozes.remove(id)!;
      _prefs.setString(_kSnoozes, _encodeSnoozes());
      final alarm = byId(id);
      if (alarm != null) _fire(alarm, 's$id@${at.millisecondsSinceEpoch}');
    }
  }

  void _fire(Alarm alarm, String key) {
    if (!_firedKeys.add(key)) return;
    if (ringing.value?.id == alarm.id) return;
    ringing.value = alarm;
  }

  /// Opens the ringing screen when the user taps an alarm notification.
  void ringFromNotification(String payload) {
    final snooze = payload.startsWith(kSnoozePayloadPrefix);
    final rawId = payload.substring(
        snooze ? kSnoozePayloadPrefix.length : kAlarmPayloadPrefix.length);
    final alarm = byId(int.tryParse(rawId) ?? -1);
    if (alarm == null || ringing.value?.id == alarm.id) return;
    if (!snooze) {
      final now = _now();
      final recent = alarm.nextOccurrence(now.subtract(ringWindow));
      if (recent.isAfter(now)) return;
    } else {
      _snoozes.remove(alarm.id);
      _prefs.setString(_kSnoozes, _encodeSnoozes());
    }
    ringing.value = alarm;
  }

  /// Stops the ringing alarm. One-time alarms switch themselves off.
  void dismiss() {
    final alarm = ringing.value;
    ringing.value = null;
    if (alarm == null) return;
    _notifications.cancelSnooze(alarm.id);
    final current = byId(alarm.id);
    if (current == null) return;
    if (current.repeats) {
      // Cancelling clears the ringing notification; scheduling re-arms it.
      _commit(current);
    } else {
      update(current.copyWith(enabled: false));
    }
  }

  /// Rings again after the alarm's snooze length.
  void snooze() {
    final alarm = ringing.value;
    ringing.value = null;
    if (alarm == null) return;
    final current = byId(alarm.id) ?? alarm;
    final at = _now().add(Duration(minutes: current.snoozeMinutes));
    if (current.repeats) {
      _notifications.scheduleAlarm(current,
          use24h: _settings.use24hWithoutContext);
    } else {
      final index = _alarms.indexWhere((a) => a.id == current.id);
      if (index >= 0) {
        _alarms[index] = current.copyWith(enabled: false, clearOneShot: true);
      }
      _notifications.cancelAlarm(current.id);
    }
    _snoozes[current.id] = at;
    _notifications.scheduleSnooze(current, at);
    _save();
  }

  void _clearSnooze(int id) {
    if (_snoozes.remove(id) != null) {
      _notifications.cancelSnooze(id);
    }
  }

  Map<int, DateTime> _decodeSnoozes(String? raw) {
    if (raw == null || raw.isEmpty) return <int, DateTime>{};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return map.map((k, v) => MapEntry(
          int.parse(k), DateTime.fromMillisecondsSinceEpoch(v as int)));
    } catch (_) {
      return <int, DateTime>{};
    }
  }

  String _encodeSnoozes() => jsonEncode(
      _snoozes.map((k, v) => MapEntry(k.toString(), v.millisecondsSinceEpoch)));

  @override
  void dispose() {
    _watcher?.cancel();
    ringing.dispose();
    super.dispose();
  }
}

DateTime _systemNow() => DateTime.now();
