import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/world_city.dart';
import '../services/time_zone_service.dart';

/// The cities pinned to the world clock.
class WorldClockController extends ChangeNotifier {
  WorldClockController(this._prefs) {
    final raw = _prefs.getString(_kCities);
    if (raw == null) {
      _cities = List<WorldCity>.of(_defaults);
    } else {
      try {
        _cities = (jsonDecode(raw) as List)
            .map((e) => WorldCity.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((c) => TimeZoneService.isValid(c.timeZone))
            .toList();
      } catch (_) {
        _cities = <WorldCity>[];
      }
    }
  }

  static const _kCities = 'worldClock.cities';

  static const List<WorldCity> _defaults = <WorldCity>[
    WorldCity('London', 'United Kingdom', 'Europe/London'),
    WorldCity('New York', 'United States', 'America/New_York'),
    WorldCity('Tokyo', 'Japan', 'Asia/Tokyo'),
  ];

  final SharedPreferences _prefs;
  late List<WorldCity> _cities;

  List<WorldCity> get cities => List.unmodifiable(_cities);

  bool contains(WorldCity city) => _cities.contains(city);

  void add(WorldCity city) {
    if (_cities.contains(city)) return;
    _cities.add(city);
    _save();
  }

  void insert(int index, WorldCity city) {
    if (_cities.contains(city)) return;
    _cities.insert(index.clamp(0, _cities.length), city);
    _save();
  }

  int remove(WorldCity city) {
    final index = _cities.indexOf(city);
    if (index >= 0) {
      _cities.removeAt(index);
      _save();
    }
    return index;
  }

  void move(int from, int to) {
    if (from < 0 || from >= _cities.length) return;
    final city = _cities.removeAt(from);
    _cities.insert(to.clamp(0, _cities.length), city);
    _save();
  }

  void _save() {
    _prefs.setString(
        _kCities, jsonEncode(_cities.map((c) => c.toJson()).toList()));
    notifyListeners();
  }
}
