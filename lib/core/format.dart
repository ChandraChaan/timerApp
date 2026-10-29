/// Pure formatting helpers shared across the app. No Flutter imports so they
/// stay trivially unit-testable.

const List<String> kWeekdayShort = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> kWeekdayLong = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> kMonthShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> kMonthLong = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String twoDigits(int n) => n.toString().padLeft(2, '0');

/// "07:05" / "19:05" in 24h mode, "7:05" in 12h mode (use [amPm] for suffix).
String formatHourMinute(int hour, int minute, {required bool use24h}) {
  if (use24h) return '${twoDigits(hour)}:${twoDigits(minute)}';
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12:${twoDigits(minute)}';
}

String amPm(int hour) => hour < 12 ? 'AM' : 'PM';

/// "Thursday, 29 October"
String formatLongDate(DateTime d) =>
    '${kWeekdayLong[d.weekday - 1]}, ${d.day} ${kMonthLong[d.month - 1]}';

/// "Thu, 29 Oct"
String formatShortDate(DateTime d) =>
    '${kWeekdayShort[d.weekday - 1]}, ${d.day} ${kMonthShort[d.month - 1]}';

/// Stopwatch style: "01:02:03.45" or "02:03.45" when under an hour.
String formatStopwatch(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  final centis = (d.inMilliseconds.remainder(1000) ~/ 10);
  final core =
      '${twoDigits(minutes)}:${twoDigits(seconds)}.${twoDigits(centis)}';
  return hours > 0 ? '${twoDigits(hours)}:$core' : core;
}

/// Countdown style: "1:02:03" or "02:03". Rounds partial seconds up so the
/// display never shows 00:00 while time is still left.
String formatCountdown(Duration d) {
  var totalSeconds = (d.inMilliseconds / 1000).ceil();
  if (totalSeconds < 0) totalSeconds = 0;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
  return '${twoDigits(minutes)}:${twoDigits(seconds)}';
}

/// Human friendly duration: "1 h 5 min", "12 min", "45 sec".
String formatDurationWords(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  final parts = <String>[];
  if (hours > 0) parts.add('$hours h');
  if (minutes > 0) parts.add('$minutes min');
  if (hours == 0 && seconds > 0) parts.add('$seconds sec');
  return parts.isEmpty ? '0 sec' : parts.join(' ');
}

/// "in 7 h 30 min", "in 1 day 3 h", "in less than a minute".
String formatTimeUntil(Duration d) {
  if (d.inMinutes < 1) return 'in less than a minute';
  final days = d.inDays;
  final hours = d.inHours.remainder(24);
  final minutes = d.inMinutes.remainder(60);
  final parts = <String>[];
  if (days > 0) parts.add(days == 1 ? '1 day' : '$days days');
  if (hours > 0) parts.add('$hours h');
  if (days == 0 && minutes > 0) parts.add('$minutes min');
  return 'in ${parts.join(' ')}';
}

/// "+5:30", "-4", "Same time".
String formatOffsetDifference(Duration diff) {
  if (diff == Duration.zero) return 'Same time';
  final sign = diff.isNegative ? '-' : '+';
  final abs = diff.abs();
  final h = abs.inHours;
  final m = abs.inMinutes.remainder(60);
  final hours = m == 0 ? '$h' : '$h:${twoDigits(m)}';
  return '$sign$hours h';
}

/// "UTC+05:30"
String formatUtcOffset(Duration offset) {
  final sign = offset.isNegative ? '-' : '+';
  final abs = offset.abs();
  return 'UTC$sign${twoDigits(abs.inHours)}:${twoDigits(abs.inMinutes.remainder(60))}';
}

/// Summarises a set of ISO weekdays (1 = Monday ... 7 = Sunday).
String describeRepeatDays(Set<int> days) {
  if (days.isEmpty) return 'Once';
  if (days.length == 7) return 'Every day';
  if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
    return 'Weekdays';
  }
  if (days.length == 2 && days.contains(6) && days.contains(7)) {
    return 'Weekends';
  }
  final sorted = days.toList()..sort();
  return sorted.map((d) => kWeekdayShort[d - 1]).join(', ');
}
