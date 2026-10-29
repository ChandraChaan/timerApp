import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/world_city.dart';
import '../../services/time_zone_service.dart';
import '../../state/app_services.dart';

/// Searchable list of cities; pops with the chosen [WorldCity].
class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({Key? key}) : super(key: key);

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final TextEditingController _search = TextEditingController();
  late final List<WorldCity> _all = <WorldCity>[
    ...kPopularCities,
    ...TimeZoneService.allZonesAsCities(),
  ];
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<WorldCity> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kPopularCities;
    final starts = <WorldCity>[];
    final contains = <WorldCity>[];
    for (final city in _all) {
      final name = city.name.toLowerCase();
      if (name.startsWith(q)) {
        starts.add(city);
      } else if (name.contains(q) ||
          city.country.toLowerCase().contains(q) ||
          city.timeZone.toLowerCase().contains(q)) {
        contains.add(city);
      }
    }
    return <WorldCity>[...starts, ...contains];
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final use24h = services.settings.use24h(context);
    final results = _results;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add city'),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search city, country or time zone',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      'No places match "$_query"',
                      style:
                          TextStyle(color: scheme.onSurface.withOpacity(0.6)),
                    ),
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final city = results[i];
                      final added = services.worldClock.contains(city);
                      final there = TimeZoneService.nowIn(city.timeZone, now);
                      final diff =
                          TimeZoneService.offsetOf(city.timeZone, now) -
                              now.timeZoneOffset;
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        title: Text(
                          city.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${city.country} · ${formatOffsetDifference(diff)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              formatHourMinute(there.hour, there.minute,
                                      use24h: use24h) +
                                  (use24h ? '' : ' ${amPm(there.hour)}'),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              added
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              color: added
                                  ? scheme.primary
                                  : scheme.onSurface.withOpacity(0.4),
                            ),
                          ],
                        ),
                        onTap:
                            added ? null : () => Navigator.pop(context, city),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
