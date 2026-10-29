import 'package:flutter_test/flutter_test.dart';
import 'package:timerapp/core/format.dart';

void main() {
  test('formatHourMinute handles 12h and 24h', () {
    expect(formatHourMinute(0, 5, use24h: true), '00:05');
    expect(formatHourMinute(0, 5, use24h: false), '12:05');
    expect(formatHourMinute(13, 30, use24h: false), '1:30');
    expect(amPm(11), 'AM');
    expect(amPm(12), 'PM');
  });

  test('formatStopwatch shows centiseconds and hours when needed', () {
    expect(formatStopwatch(const Duration(milliseconds: 62345)), '01:02.34');
    expect(
        formatStopwatch(const Duration(hours: 1, seconds: 3)), '01:00:03.00');
  });

  test('formatCountdown rounds partial seconds up', () {
    expect(formatCountdown(const Duration(milliseconds: 59001)), '01:00');
    expect(formatCountdown(const Duration(milliseconds: 1)), '00:01');
    expect(formatCountdown(Duration.zero), '00:00');
    expect(formatCountdown(const Duration(hours: 2, minutes: 3)), '2:03:00');
  });

  test('duration words', () {
    expect(formatDurationWords(const Duration(minutes: 25)), '25 min');
    expect(
        formatDurationWords(const Duration(hours: 1, minutes: 5)), '1 h 5 min');
    expect(formatDurationWords(const Duration(seconds: 45)), '45 sec');
    expect(formatTimeUntil(const Duration(hours: 7, minutes: 30)),
        'in 7 h 30 min');
    expect(
        formatTimeUntil(const Duration(seconds: 20)), 'in less than a minute');
  });

  test('offsets', () {
    expect(formatOffsetDifference(const Duration(hours: 5, minutes: 30)),
        '+5:30 h');
    expect(formatOffsetDifference(const Duration(hours: -4)), '-4 h');
    expect(formatOffsetDifference(Duration.zero), 'Same time');
    expect(formatUtcOffset(const Duration(hours: 5, minutes: 30)), 'UTC+05:30');
  });

  test('describeRepeatDays', () {
    expect(describeRepeatDays(<int>{}), 'Once');
    expect(describeRepeatDays(<int>{1, 2, 3, 4, 5}), 'Weekdays');
    expect(describeRepeatDays(<int>{6, 7}), 'Weekends');
    expect(describeRepeatDays(<int>{1, 2, 3, 4, 5, 6, 7}), 'Every day');
    expect(describeRepeatDays(<int>{3, 1}), 'Mon, Wed');
  });
}
