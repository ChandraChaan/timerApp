import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/app_services.dart';
import '../../state/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: <Widget>[
            const _Group('Appearance'),
            _Card(children: <Widget>[
              _ChoiceRow<ThemeMode>(
                icon: Icons.brightness_6_rounded,
                title: 'Theme',
                value: settings.themeMode,
                options: const <ThemeMode, String>{
                  ThemeMode.system: 'System',
                  ThemeMode.light: 'Light',
                  ThemeMode.dark: 'Dark',
                },
                onChanged: settings.setThemeMode,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.contrast_rounded),
                title: const Text('Pure black'),
                subtitle: const Text('Deep black background for OLED screens'),
                value: settings.pureBlack,
                onChanged: settings.setPureBlack,
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Accent colour'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      for (var i = 0; i < kAccentOptions.length; i++)
                        _AccentDot(
                          option: kAccentOptions[i],
                          selected: settings.accentIndex == i,
                          onTap: () {
                            settings.tick();
                            settings.setAccent(i);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ]),
            const _Group('Clock'),
            _Card(children: <Widget>[
              _ChoiceRow<TimeFormatPreference>(
                icon: Icons.schedule_rounded,
                title: 'Time format',
                value: settings.timeFormat,
                options: const <TimeFormatPreference, String>{
                  TimeFormatPreference.system: 'System',
                  TimeFormatPreference.twelveHour: '12-hour',
                  TimeFormatPreference.twentyFourHour: '24-hour',
                },
                onChanged: settings.setTimeFormat,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.watch_later_outlined),
                title: const Text('Analog clock'),
                subtitle: const Text('Show a clock face on the Clock tab'),
                value: settings.analogClock,
                onChanged: settings.setAnalogClock,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.timer_10_rounded),
                title: const Text('Show seconds'),
                value: settings.showSeconds,
                onChanged: settings.setShowSeconds,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.motion_photos_on_outlined),
                title: const Text('Smooth second hand'),
                subtitle: const Text('Sweeping motion instead of ticking'),
                value: settings.smoothSeconds,
                onChanged: settings.showSeconds && settings.analogClock
                    ? settings.setSmoothSeconds
                    : null,
              ),
            ]),
            const _Group('Alarms & feedback'),
            _Card(children: <Widget>[
              _ChoiceRow<int>(
                icon: Icons.snooze_rounded,
                title: 'Default snooze',
                value: settings.defaultSnooze,
                options: const <int, String>{
                  5: '5 min',
                  10: '10 min',
                  15: '15 min',
                  20: '20 min',
                },
                onChanged: settings.setDefaultSnooze,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration_rounded),
                title: const Text('Haptic feedback'),
                subtitle: const Text('Subtle vibrations when you tap'),
                value: settings.haptics,
                onChanged: settings.setHaptics,
              ),
            ]),
            const _Group('About'),
            const _Card(children: <Widget>[
              ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Best Clock'),
                subtitle: Text(
                    'Version 2.0 · World clock, alarms, stopwatch & timer'),
              ),
              ListTile(
                leading: Icon(Icons.notifications_active_outlined),
                title: Text('Reliable alarms'),
                subtitle: Text(
                    'Alarms and timers ring through notifications, even when the app is closed. Keep notifications enabled for Best Clock.'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({Key? key, required this.children}) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: children),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final entry in options.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: entry.key == value,
                selectedColor: scheme.primary.withOpacity(0.25),
                onSelected: (_) => onChanged(entry.key),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({
    Key? key,
    required this.option,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  final AccentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${option.name} accent',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? option.color : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[option.color, option.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        ),
      ),
    );
  }
}
