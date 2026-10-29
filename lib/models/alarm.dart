import 'dart:convert';

/// A single alarm. [days] holds ISO weekdays (1 = Monday ... 7 = Sunday);
/// an empty set means the alarm rings once and then switches itself off.
class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.days = const <int>{},
    this.enabled = true,
    this.vibrate = true,
    this.snoozeMinutes = 10,
    this.oneShotAt,
  });

  final int id;
  final int hour;
  final int minute;
  final String label;
  final Set<int> days;
  final bool enabled;
  final bool vibrate;
  final int snoozeMinutes;

  /// For non-repeating alarms: the moment it was armed for. Lets us switch the
  /// alarm off automatically once that moment has passed.
  final DateTime? oneShotAt;

  bool get repeats => days.isNotEmpty;

  /// The next moment (strictly after [from]) this alarm should ring.
  DateTime nextOccurrence(DateTime from) {
    var candidate = DateTime(from.year, from.month, from.day, hour, minute);
    if (!candidate.isAfter(from)) {
      candidate = DateTime(from.year, from.month, from.day + 1, hour, minute);
    }
    if (days.isEmpty) return candidate;
    for (var i = 0; i < 7; i++) {
      final c = DateTime(
          candidate.year, candidate.month, candidate.day + i, hour, minute);
      if (days.contains(c.weekday)) return c;
    }
    return candidate;
  }

  Alarm copyWith({
    int? hour,
    int? minute,
    String? label,
    Set<int>? days,
    bool? enabled,
    bool? vibrate,
    int? snoozeMinutes,
    DateTime? oneShotAt,
    bool clearOneShot = false,
  }) {
    return Alarm(
      id: id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
      vibrate: vibrate ?? this.vibrate,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      oneShotAt: clearOneShot ? null : (oneShotAt ?? this.oneShotAt),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'days': days.toList()..sort(),
        'enabled': enabled,
        'vibrate': vibrate,
        'snooze': snoozeMinutes,
        if (oneShotAt != null) 'oneShotAt': oneShotAt!.millisecondsSinceEpoch,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) {
    final oneShot = json['oneShotAt'];
    return Alarm(
      id: json['id'] as int,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: (json['label'] as String?) ?? '',
      days: ((json['days'] as List?) ?? const <dynamic>[])
          .map((e) => e as int)
          .toSet(),
      enabled: (json['enabled'] as bool?) ?? true,
      vibrate: (json['vibrate'] as bool?) ?? true,
      snoozeMinutes: (json['snooze'] as int?) ?? 10,
      oneShotAt:
          oneShot is int ? DateTime.fromMillisecondsSinceEpoch(oneShot) : null,
    );
  }

  static String encodeList(List<Alarm> alarms) =>
      jsonEncode(alarms.map((a) => a.toJson()).toList());

  static List<Alarm> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return <Alarm>[];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Alarm.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <Alarm>[];
    }
  }
}
