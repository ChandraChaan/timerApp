import 'package:flutter_test/flutter_test.dart';
import 'package:timerapp/models/world_city.dart';
import 'package:timerapp/services/time_zone_service.dart';

void main() {
  setUpAll(TimeZoneService.ensureInitialized);

  test('every curated city has a valid time zone', () {
    for (final city in kPopularCities) {
      expect(TimeZoneService.isValid(city.timeZone), isTrue,
          reason: '${city.name}: ${city.timeZone}');
    }
  });

  test('converts instants to other zones', () {
    final instant = DateTime.utc(2026, 7, 1, 12);
    final tokyo = TimeZoneService.nowIn('Asia/Tokyo', instant);
    expect(tokyo.hour, 21);
    expect(TimeZoneService.offsetOf('Asia/Kolkata', instant),
        const Duration(hours: 5, minutes: 30));
    // Daylight saving time is applied.
    expect(TimeZoneService.offsetOf('Europe/London', instant),
        const Duration(hours: 1));
  });

  test('all zones are searchable as cities', () {
    final all = TimeZoneService.allZonesAsCities();
    expect(all.length, greaterThan(200));
    expect(all.any((c) => c.timeZone == 'America/Argentina/Cordoba'), isTrue);
  });
}
