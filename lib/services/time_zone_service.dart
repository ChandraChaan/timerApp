import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/world_city.dart';

/// Loads the IANA time zone database and works out the device's own zone so
/// repeating alarms keep ringing at the right wall-clock time across DST.
class TimeZoneService {
  TimeZoneService._();

  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(_guessLocalLocation());
    _initialized = true;
  }

  /// The device does not expose its IANA id without a native plugin, so pick
  /// the zone whose current offset and abbreviation match the device clock,
  /// preferring well-known cities.
  static tz.Location _guessLocalLocation() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset.inMilliseconds;
    final abbreviation = now.timeZoneName;
    final millis = now.millisecondsSinceEpoch;

    final candidates = <tz.Location>[
      for (final city in kPopularCities)
        if (tz.timeZoneDatabase.locations.containsKey(city.timeZone))
          tz.getLocation(city.timeZone),
      ...tz.timeZoneDatabase.locations.values,
    ];

    tz.Location? sameOffset;
    for (final location in candidates) {
      final zone = location.timeZone(millis);
      if (zone.offset != offset) continue;
      if (zone.abbreviation == abbreviation) return location;
      sameOffset ??= location;
    }
    return sameOffset ?? tz.UTC;
  }

  static bool isValid(String name) =>
      tz.timeZoneDatabase.locations.containsKey(name);

  /// Current wall-clock time in [timeZone], as a plain [DateTime] whose
  /// fields read as that zone's local time.
  static DateTime nowIn(String timeZone, [DateTime? at]) {
    final instant = at ?? DateTime.now();
    final local = tz.TZDateTime.from(instant, tz.getLocation(timeZone));
    return DateTime(local.year, local.month, local.day, local.hour,
        local.minute, local.second, local.millisecond);
  }

  static Duration offsetOf(String timeZone, [DateTime? at]) {
    final instant = at ?? DateTime.now();
    return tz.TZDateTime.from(instant, tz.getLocation(timeZone)).timeZoneOffset;
  }

  static const Set<String> _regions = <String>{
    'Africa',
    'America',
    'Antarctica',
    'Asia',
    'Atlantic',
    'Australia',
    'Europe',
    'Indian',
    'Pacific',
  };

  /// Every zone as a "city" (e.g. America/Argentina/Buenos_Aires ->
  /// "Buenos Aires, America"), so users can find places outside the curated
  /// list.
  static List<WorldCity> allZonesAsCities() {
    final known = kPopularCities.map((c) => c.timeZone).toSet();
    final result = <WorldCity>[];
    for (final name in tz.timeZoneDatabase.locations.keys) {
      final parts = name.split('/');
      if (parts.length < 2 || !_regions.contains(parts.first)) continue;
      if (known.contains(name)) continue;
      final city = parts.last.replaceAll('_', ' ');
      result.add(WorldCity(city, parts.first, name));
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }
}
