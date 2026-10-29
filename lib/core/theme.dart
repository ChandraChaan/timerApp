import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Accent colours the user can choose from in Settings.
class AccentOption {
  const AccentOption(this.name, this.color, this.secondary);

  final String name;
  final Color color;
  final Color secondary;
}

const List<AccentOption> kAccentOptions = <AccentOption>[
  AccentOption('Violet', Color(0xFF8B7CFF), Color(0xFF5CE1E6)),
  AccentOption('Ocean', Color(0xFF3DA9FC), Color(0xFF7CF4C8)),
  AccentOption('Mint', Color(0xFF22C3A6), Color(0xFFB8F35A)),
  AccentOption('Sunset', Color(0xFFFF7A59), Color(0xFFFFC145)),
  AccentOption('Rose', Color(0xFFFF5FA2), Color(0xFFB57CFF)),
  AccentOption('Gold', Color(0xFFF5A300), Color(0xFFFFE066)),
];

/// Digits that keep a constant width so running clocks never jitter.
const List<FontFeature> kTabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];

class AppTheme {
  AppTheme._();

  static ThemeData build({
    required Brightness brightness,
    required AccentOption accent,
    bool pureBlack = false,
  }) {
    final dark = brightness == Brightness.dark;
    final background = dark
        ? (pureBlack ? Colors.black : const Color(0xFF0D0E12))
        : const Color(0xFFF4F5FA);
    final surface = dark
        ? (pureBlack ? const Color(0xFF101114) : const Color(0xFF17181E))
        : Colors.white;
    final onSurface = dark ? const Color(0xFFF2F3F7) : const Color(0xFF15161B);

    final scheme = dark
        ? ColorScheme.dark(
            primary: accent.color,
            onPrimary: Colors.white,
            secondary: accent.secondary,
            onSecondary: Colors.black,
            surface: surface,
            onSurface: onSurface,
            background: background,
            onBackground: onSurface,
            error: const Color(0xFFFF6B6B),
          )
        : ColorScheme.light(
            primary: accent.color,
            onPrimary: Colors.white,
            secondary: accent.secondary,
            onSecondary: Colors.black,
            surface: surface,
            onSurface: onSurface,
            background: background,
            onBackground: onSurface,
            error: const Color(0xFFD93A3A),
          );

    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: onSurface.withOpacity(0.08),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final applied = base.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );
    // Secondary text (list subtitles, captions) is muted.
    final text = applied.copyWith(
      caption: applied.caption?.copyWith(color: onSurface.withOpacity(0.6)),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle:
            dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.color.withOpacity(dark ? 0.22 : 0.16),
        height: 70,
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: onSurface.withOpacity(0.85),
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: selected ? accent.color : onSurface.withOpacity(0.6),
            size: 26,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return dark ? const Color(0xFF8A8C96) : const Color(0xFFBFC1C9);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return accent.color;
          return onSurface.withOpacity(0.15);
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            dark ? const Color(0xFF2A2B33) : const Color(0xFF22232A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: onSurface.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(accent.color),
          textStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent.color,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
