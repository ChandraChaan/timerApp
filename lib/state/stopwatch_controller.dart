import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A lap: its own duration and the total time when it was recorded.
class Lap {
  const Lap(this.number, this.split, this.total);

  final int number;
  final Duration split;
  final Duration total;
}

/// Wall-clock based stopwatch, so it keeps counting while the app is closed
/// and survives restarts.
class StopwatchController extends ChangeNotifier {
  StopwatchController(this._prefs, {DateTime Function()? clock})
      : _now = clock ?? _systemNow {
    _restore();
  }

  static const _kState = 'stopwatch.state';

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  DateTime? _startedAt;
  Duration _accumulated = Duration.zero;
  final List<Duration> _marks = <Duration>[];

  bool get isRunning => _startedAt != null;
  bool get isPristine => !isRunning && _accumulated == Duration.zero;

  Duration get elapsed {
    final started = _startedAt;
    if (started == null) return _accumulated;
    final running = _now().difference(started);
    return _accumulated + (running.isNegative ? Duration.zero : running);
  }

  Duration get currentLap =>
      elapsed - (_marks.isEmpty ? Duration.zero : _marks.last);

  /// Completed laps, newest first.
  List<Lap> get laps {
    final result = <Lap>[];
    var previous = Duration.zero;
    for (var i = 0; i < _marks.length; i++) {
      result.add(Lap(i + 1, _marks[i] - previous, _marks[i]));
      previous = _marks[i];
    }
    return result.reversed.toList();
  }

  /// Number of the fastest / slowest completed lap (only once there are at
  /// least two laps to compare).
  int? get fastestLap => _extremeLap(fastest: true);
  int? get slowestLap => _extremeLap(fastest: false);

  int? _extremeLap({required bool fastest}) {
    if (_marks.length < 2) return null;
    final all = laps;
    var best = all.first;
    for (final lap in all) {
      final better = fastest ? lap.split < best.split : lap.split > best.split;
      if (better) best = lap;
    }
    return best.number;
  }

  void start() {
    if (isRunning) return;
    _startedAt = _now();
    _save();
  }

  void pause() {
    if (!isRunning) return;
    _accumulated = elapsed;
    _startedAt = null;
    _save();
  }

  void toggle() => isRunning ? pause() : start();

  void lap() {
    if (!isRunning) return;
    _marks.add(elapsed);
    _save();
  }

  void reset() {
    _startedAt = null;
    _accumulated = Duration.zero;
    _marks.clear();
    _save();
  }

  /// Plain-text summary for copying to the clipboard.
  String exportText(String Function(Duration) format) {
    final buffer = StringBuffer('Stopwatch · ${format(elapsed)}\n');
    for (final lap in laps.reversed) {
      buffer.writeln(
          'Lap ${lap.number}\t${format(lap.split)}\t${format(lap.total)}');
    }
    return buffer.toString().trimRight();
  }

  void _restore() {
    final raw = _prefs.getString(_kState);
    if (raw == null) return;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final started = json['startedAt'] as int?;
      _startedAt =
          started == null ? null : DateTime.fromMillisecondsSinceEpoch(started);
      _accumulated = Duration(milliseconds: (json['acc'] as int?) ?? 0);
      _marks
        ..clear()
        ..addAll(((json['marks'] as List?) ?? const <dynamic>[])
            .map((e) => Duration(milliseconds: e as int)));
    } catch (_) {
      reset();
    }
  }

  void _save() {
    _prefs.setString(
      _kState,
      jsonEncode(<String, dynamic>{
        'startedAt': _startedAt?.millisecondsSinceEpoch,
        'acc': _accumulated.inMilliseconds,
        'marks': _marks.map((m) => m.inMilliseconds).toList(),
      }),
    );
    notifyListeners();
  }
}

DateTime _systemNow() => DateTime.now();
