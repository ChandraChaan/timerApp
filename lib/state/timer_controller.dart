import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

enum TimerStatus { idle, running, paused, ringing }

/// Countdown timer. The end moment is stored as wall-clock time, so the timer
/// keeps going when the app is closed and a scheduled notification rings.
class TimerController extends ChangeNotifier {
  TimerController(this._prefs, this._notifications,
      {DateTime Function()? clock})
      : _now = clock ?? _systemNow {
    _restore();
  }

  static const _kState = 'timer.state';
  static const _kRecent = 'timer.recent';
  static const _kLastDuration = 'timer.lastDuration';

  /// A timer that ended less than this long ago is restored as ringing.
  static const Duration recentlyFinished = Duration(minutes: 10);

  static const List<Duration> presets = <Duration>[
    Duration(minutes: 1),
    Duration(minutes: 3),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 25),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  final SharedPreferences _prefs;
  final NotificationService _notifications;
  final DateTime Function() _now;

  TimerStatus _status = TimerStatus.idle;
  Duration _total = Duration.zero;
  DateTime? _endAt;
  Duration _pausedRemaining = Duration.zero;
  String _label = '';
  Timer? _ticker;

  TimerStatus get status => _status;
  Duration get total => _total;
  DateTime? get endAt => _status == TimerStatus.running ? _endAt : null;
  String get label => _label;
  bool get isActive => _status != TimerStatus.idle;

  Duration get remaining {
    switch (_status) {
      case TimerStatus.running:
        final left = _endAt!.difference(_now());
        return left.isNegative ? Duration.zero : left;
      case TimerStatus.paused:
        return _pausedRemaining;
      case TimerStatus.ringing:
        return Duration.zero;
      case TimerStatus.idle:
        return _total;
    }
  }

  /// 1.0 when just started, 0.0 when finished.
  double get progress {
    if (_total.inMilliseconds <= 0) return 0;
    return (remaining.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
  }

  /// The duration last picked on the wheel, so it is preselected next time.
  Duration get lastDuration =>
      Duration(seconds: _prefs.getInt(_kLastDuration) ?? 300);

  List<Duration> get recent => (_prefs.getStringList(_kRecent) ?? <String>[])
      .map((s) => Duration(seconds: int.tryParse(s) ?? 0))
      .where((d) => d > Duration.zero)
      .toList();

  void start(Duration duration, {String label = ''}) {
    if (duration <= Duration.zero) return;
    _total = duration;
    _label = label;
    _endAt = _now().add(duration);
    _status = TimerStatus.running;
    _prefs.setInt(_kLastDuration, duration.inSeconds);
    _remember(duration);
    _notifications.scheduleTimer(_endAt!, label: label);
    _startTicker();
    _save();
  }

  void pause() {
    if (_status != TimerStatus.running) return;
    _pausedRemaining = remaining;
    _status = TimerStatus.paused;
    _stopTicker();
    _notifications.cancelTimer();
    _save();
  }

  void resume() {
    if (_status != TimerStatus.paused) return;
    _endAt = _now().add(_pausedRemaining);
    _status = TimerStatus.running;
    _notifications.scheduleTimer(_endAt!, label: _label);
    _startTicker();
    _save();
  }

  void toggle() => _status == TimerStatus.running ? pause() : resume();

  /// Adds time to a running, paused or just-finished timer.
  void addTime(Duration extra) {
    switch (_status) {
      case TimerStatus.running:
        _endAt = _endAt!.add(extra);
        _total += extra;
        _notifications.scheduleTimer(_endAt!, label: _label);
        break;
      case TimerStatus.paused:
        _pausedRemaining += extra;
        _total += extra;
        break;
      case TimerStatus.ringing:
        _notifications.cancelTimer();
        _total = extra;
        _endAt = _now().add(extra);
        _status = TimerStatus.running;
        _notifications.scheduleTimer(_endAt!, label: _label);
        _startTicker();
        break;
      case TimerStatus.idle:
        return;
    }
    _save();
  }

  /// Starts the same duration again.
  void restart() => start(_total, label: _label);

  void cancel() {
    _status = TimerStatus.idle;
    _endAt = null;
    _pausedRemaining = Duration.zero;
    _stopTicker();
    _notifications.cancelTimer();
    _save();
  }

  /// Silences a finished timer.
  void dismiss() => cancel();

  /// Called periodically while running. Public for tests.
  void checkFinished() {
    if (_status != TimerStatus.running) return;
    if (_now().isBefore(_endAt!)) return;
    _status = TimerStatus.ringing;
    _stopTicker();
    _save();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
        const Duration(milliseconds: 200), (_) => checkFinished());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _remember(Duration duration) {
    final list = recent..remove(duration);
    list.insert(0, duration);
    _prefs.setStringList(
        _kRecent, list.take(4).map((d) => d.inSeconds.toString()).toList());
  }

  void _restore() {
    final raw = _prefs.getString(_kState);
    if (raw == null) return;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final status = TimerStatus.values[json['status'] as int];
      _total = Duration(milliseconds: json['total'] as int);
      _label = (json['label'] as String?) ?? '';
      _pausedRemaining = Duration(milliseconds: (json['paused'] as int?) ?? 0);
      final end = json['endAt'] as int?;
      _endAt = end == null ? null : DateTime.fromMillisecondsSinceEpoch(end);
      final wasCounting =
          status == TimerStatus.running || status == TimerStatus.ringing;
      if (wasCounting && _endAt != null) {
        if (status == TimerStatus.running && _now().isBefore(_endAt!)) {
          _status = TimerStatus.running;
          _startTicker();
        } else if (_now().difference(_endAt!) < recentlyFinished) {
          // Finished while the app was closed and is probably still ringing:
          // show the ring screen so the user can stop it.
          _status = TimerStatus.ringing;
        } else {
          // Finished long ago; clear any stale notification and start fresh.
          _status = TimerStatus.idle;
          _notifications.cancelTimer();
        }
      } else if (status == TimerStatus.paused) {
        _status = TimerStatus.paused;
      } else {
        _status = TimerStatus.idle;
      }
    } catch (_) {
      _status = TimerStatus.idle;
    }
  }

  void _save() {
    _prefs.setString(
      _kState,
      jsonEncode(<String, dynamic>{
        'status': _status.index,
        'total': _total.inMilliseconds,
        'label': _label,
        'paused': _pausedRemaining.inMilliseconds,
        'endAt': _endAt?.millisecondsSinceEpoch,
      }),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}

DateTime _systemNow() => DateTime.now();
