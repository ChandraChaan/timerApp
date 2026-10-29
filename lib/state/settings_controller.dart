import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';

enum TimeFormatPreference { system, twelveHour, twentyFourHour }

/// User preferences, persisted to SharedPreferences.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _themeMode = ThemeMode.values[
        _readIndex(_kTheme, ThemeMode.values.length, ThemeMode.dark.index)];
    _accentIndex = _readIndex(_kAccent, kAccentOptions.length, 0);
    _pureBlack = _prefs.getBool(_kPureBlack) ?? false;
    _timeFormat = TimeFormatPreference.values[
        _readIndex(_kTimeFormat, TimeFormatPreference.values.length, 0)];
    _showSeconds = _prefs.getBool(_kShowSeconds) ?? true;
    _analogClock = _prefs.getBool(_kAnalog) ?? true;
    _smoothSeconds = _prefs.getBool(_kSmooth) ?? true;
    _haptics = _prefs.getBool(_kHaptics) ?? true;
    _defaultSnooze = _prefs.getInt(_kSnooze) ?? 10;
  }

  static const _kTheme = 'settings.themeMode';
  static const _kAccent = 'settings.accent';
  static const _kPureBlack = 'settings.pureBlack';
  static const _kTimeFormat = 'settings.timeFormat';
  static const _kShowSeconds = 'settings.showSeconds';
  static const _kAnalog = 'settings.analogClock';
  static const _kSmooth = 'settings.smoothSeconds';
  static const _kHaptics = 'settings.haptics';
  static const _kSnooze = 'settings.defaultSnooze';
  static const _kLastTab = 'settings.lastTab';

  final SharedPreferences _prefs;

  late ThemeMode _themeMode;
  late int _accentIndex;
  late bool _pureBlack;
  late TimeFormatPreference _timeFormat;
  late bool _showSeconds;
  late bool _analogClock;
  late bool _smoothSeconds;
  late bool _haptics;
  late int _defaultSnooze;

  ThemeMode get themeMode => _themeMode;
  AccentOption get accent => kAccentOptions[_accentIndex];
  int get accentIndex => _accentIndex;
  bool get pureBlack => _pureBlack;
  TimeFormatPreference get timeFormat => _timeFormat;
  bool get showSeconds => _showSeconds;
  bool get analogClock => _analogClock;
  bool get smoothSeconds => _smoothSeconds;
  bool get haptics => _haptics;
  int get defaultSnooze => _defaultSnooze;
  int get lastTab => _readIndex(_kLastTab, 4, 0);

  int _readIndex(String key, int length, int fallback) {
    final value = _prefs.getInt(key);
    if (value == null || value < 0 || value >= length) return fallback;
    return value;
  }

  /// Resolves the 12/24h preference, falling back to the OS setting.
  bool use24h(BuildContext context) {
    if (_timeFormat == TimeFormatPreference.twelveHour) return false;
    if (_timeFormat == TimeFormatPreference.twentyFourHour) return true;
    return MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
  }

  /// Same as [use24h] for places without a [BuildContext] (notifications).
  bool get use24hWithoutContext {
    if (_timeFormat == TimeFormatPreference.twelveHour) return false;
    if (_timeFormat == TimeFormatPreference.twentyFourHour) return true;
    return PlatformDispatcher.instance.alwaysUse24HourFormat;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setInt(_kTheme, mode.index);
    notifyListeners();
  }

  void setAccent(int index) {
    _accentIndex = index.clamp(0, kAccentOptions.length - 1);
    _prefs.setInt(_kAccent, _accentIndex);
    notifyListeners();
  }

  void setPureBlack(bool value) {
    _pureBlack = value;
    _prefs.setBool(_kPureBlack, value);
    notifyListeners();
  }

  void setTimeFormat(TimeFormatPreference value) {
    _timeFormat = value;
    _prefs.setInt(_kTimeFormat, value.index);
    notifyListeners();
  }

  void setShowSeconds(bool value) {
    _showSeconds = value;
    _prefs.setBool(_kShowSeconds, value);
    notifyListeners();
  }

  void setAnalogClock(bool value) {
    _analogClock = value;
    _prefs.setBool(_kAnalog, value);
    notifyListeners();
  }

  void setSmoothSeconds(bool value) {
    _smoothSeconds = value;
    _prefs.setBool(_kSmooth, value);
    notifyListeners();
  }

  void setHaptics(bool value) {
    _haptics = value;
    _prefs.setBool(_kHaptics, value);
    notifyListeners();
  }

  void setDefaultSnooze(int minutes) {
    _defaultSnooze = minutes;
    _prefs.setInt(_kSnooze, minutes);
    notifyListeners();
  }

  void setLastTab(int index) => _prefs.setInt(_kLastTab, index);

  /// Light tap feedback, honouring the user's haptics preference.
  void tick() {
    if (_haptics) HapticFeedback.selectionClick();
  }

  void tap() {
    if (_haptics) HapticFeedback.lightImpact();
  }

  void thud() {
    if (_haptics) HapticFeedback.mediumImpact();
  }
}
