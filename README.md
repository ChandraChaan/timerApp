# Best Clock

A beautiful, reliable clock app built with Flutter: world clock, alarms,
stopwatch and timer in one place, with dark/light themes and custom accent
colours.

## Features

### Clock
- Large analog clock face with a smooth sweeping (or ticking) second hand
- Big digital time, date and your time zone / UTC offset
- "Next alarm" banner showing when your next alarm rings
- **World clock**: add any city on earth (curated popular cities plus every
  IANA time zone), see its time, day/night, "Today/Tomorrow" and the hour
  difference. Swipe to remove (with undo), long-press to reorder.

### Alarm
- Smooth wheel time picker (12 h or 24 h)
- Repeat on any days, with Once / Weekdays / Weekends / Every day shortcuts
- Labels, per-alarm snooze length (5–30 min) and vibration
- Alarms ring through scheduled notifications even when the app is closed,
  play on the alarm audio stream, keep sounding until dismissed and survive
  reboots
- Full-screen ringing page with **Dismiss** and **Snooze**
- One-time alarms switch themselves off after ringing
- "Rings in 7 h 30 min" summaries everywhere

### Stopwatch
- Centisecond precision with a sweeping dial
- Laps with fastest / slowest lap highlighted
- Copy all laps to the clipboard
- Keeps running when the app is closed and survives restarts

### Timer
- Hours / minutes / seconds wheel, optional label
- One-tap quick starts (1 min … 1 h) and recently used timers
- Animated progress ring showing remaining time and when it ends
- Pause, resume, cancel and **+1 min**
- Rings via notification when the app is closed; full-screen "Time's up"
  page with **Stop** and **+1 min**

### Settings
- Theme: System / Light / Dark, plus a pure-black OLED mode
- Six accent colours
- Time format: System / 12-hour / 24-hour
- Analog clock, seconds and smooth second hand toggles
- Default snooze length and haptic feedback

Push messages from Firebase Cloud Messaging still work when Firebase is
configured; the app runs fine without it.

## Project structure

```
lib/
  main.dart                 bootstraps services and runs the app
  app.dart                  MaterialApp + themes
  core/                     formatting helpers and theme
  models/                   Alarm, WorldCity (+ curated city list)
  services/                 notifications, time zones, Firebase messaging
  state/                    controllers (settings, alarms, stopwatch, timer,
                            world clock) and the AppScope that exposes them
  ui/screens/               Clock, Alarm, Stopwatch, Timer, Settings, ring page
  ui/widgets/               analog clock, progress ring, wheel picker, ...
test/                       unit and widget tests
```

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

On Android 12+ make sure notifications (and "Alarms & reminders") are
allowed for Best Clock so alarms can ring on time.
