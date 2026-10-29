import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/alarm.dart';
import '../../state/app_services.dart';
import 'wheel_picker.dart';

class AlarmEditorResult {
  const AlarmEditorResult(this.alarm, {this.deleted = false});

  final Alarm alarm;
  final bool deleted;
}

Future<AlarmEditorResult?> showAlarmEditor(
  BuildContext context, {
  required Alarm initial,
  bool isNew = false,
}) {
  return showModalBottomSheet<AlarmEditorResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AlarmEditor(initial: initial, isNew: isNew),
  );
}

class AlarmEditor extends StatefulWidget {
  const AlarmEditor({Key? key, required this.initial, this.isNew = false})
      : super(key: key);

  final Alarm initial;
  final bool isNew;

  @override
  State<AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends State<AlarmEditor> {
  late int _hour = widget.initial.hour;
  late int _minute = widget.initial.minute;
  late Set<int> _days = Set<int>.of(widget.initial.days);
  late bool _vibrate = widget.initial.vibrate;
  late int _snooze = widget.initial.snoozeMinutes;
  late final TextEditingController _label =
      TextEditingController(text: widget.initial.label);

  static const List<int> _snoozeChoices = <int>[5, 10, 15, 20, 30];

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Alarm get _draft => widget.initial.copyWith(
        hour: _hour,
        minute: _minute,
        days: _days,
        vibrate: _vibrate,
        snoozeMinutes: _snooze,
        label: _label.text.trim(),
      );

  void _setPreset(Set<int> days) => setState(() => _days = Set<int>.of(days));

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final settings = services.settings;
    final scheme = Theme.of(context).colorScheme;
    final use24h = settings.use24h(context);
    final now = DateTime.now();
    final next = _draft.nextOccurrence(now);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  Expanded(
                    child: Text(
                      widget.isNew ? 'New alarm' : 'Edit alarm',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      settings.tap();
                      Navigator.pop(context, AlarmEditorResult(_draft));
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              WheelFrame(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (use24h)
                      WheelColumn(
                        itemCount: 24,
                        initialItem: _hour,
                        haptics: settings.haptics,
                        labelBuilder: (i) => twoDigits(i),
                        onChanged: (i) => setState(() => _hour = i),
                      )
                    else
                      WheelColumn(
                        itemCount: 12,
                        initialItem: _hour % 12,
                        haptics: settings.haptics,
                        labelBuilder: (i) => i == 0 ? '12' : '$i',
                        onChanged: (i) =>
                            setState(() => _hour = i + (_hour >= 12 ? 12 : 0)),
                      ),
                    const WheelSeparator(':'),
                    WheelColumn(
                      itemCount: 60,
                      initialItem: _minute,
                      haptics: settings.haptics,
                      labelBuilder: (i) => twoDigits(i),
                      onChanged: (i) => setState(() => _minute = i),
                    ),
                    if (!use24h)
                      WheelColumn(
                        itemCount: 2,
                        initialItem: _hour >= 12 ? 1 : 0,
                        looping: false,
                        width: 72,
                        fontSize: 24,
                        haptics: settings.haptics,
                        labelBuilder: (i) => i == 0 ? 'AM' : 'PM',
                        onChanged: (i) => setState(
                            () => _hour = (_hour % 12) + (i == 1 ? 12 : 0)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rings ${formatTimeUntil(next.difference(now))}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Repeat · ${describeRepeatDays(_days)}'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  for (var d = 1; d <= 7; d++)
                    _DayToggle(
                      label: kWeekdayShort[d - 1].substring(0, 1),
                      tooltip: kWeekdayLong[d - 1],
                      selected: _days.contains(d),
                      onTap: () {
                        settings.tick();
                        setState(() {
                          _days = Set<int>.of(_days);
                          if (!_days.remove(d)) _days.add(d);
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  _presetChip('Once', <int>{}),
                  _presetChip('Weekdays', <int>{1, 2, 3, 4, 5}),
                  _presetChip('Weekends', <int>{6, 7}),
                  _presetChip('Every day', <int>{1, 2, 3, 4, 5, 6, 7}),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Label'),
              const SizedBox(height: 10),
              TextField(
                controller: _label,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Wake up, Gym, Meds…',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Snooze'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final m in _snoozeChoices)
                    ChoiceChip(
                      label: Text('$m min'),
                      selected: _snooze == m,
                      selectedColor: scheme.primary.withOpacity(0.25),
                      onSelected: (_) => setState(() => _snooze = m),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _vibrate,
                onChanged: (v) => setState(() => _vibrate = v),
                secondary: const Icon(Icons.vibration_rounded),
                title: const Text('Vibrate'),
              ),
              if (!widget.isNew) ...<Widget>[
                const SizedBox(height: 4),
                TextButton.icon(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(scheme.error),
                  ),
                  onPressed: () => Navigator.pop(
                    context,
                    AlarmEditorResult(widget.initial, deleted: true),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete alarm'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, Set<int> days) {
    final selected = _days.length == days.length && _days.containsAll(days);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.25),
      onSelected: (_) => _setPreset(days),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      );
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    Key? key,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        selected: selected,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? scheme.primary
                  : scheme.onSurface.withOpacity(0.07),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color:
                    selected ? Colors.white : scheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
