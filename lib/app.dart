import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'state/app_services.dart';
import 'ui/screens/home_page.dart';

class ClockApp extends StatelessWidget {
  const ClockApp({Key? key, required this.services}) : super(key: key);

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final settings = services.settings;
    return AppScope(
      services: services,
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) => MaterialApp(
          title: 'Best Clock',
          debugShowCheckedModeBanner: false,
          navigatorKey: services.navigatorKey,
          themeMode: settings.themeMode,
          theme: AppTheme.build(
            brightness: Brightness.light,
            accent: settings.accent,
          ),
          darkTheme: AppTheme.build(
            brightness: Brightness.dark,
            accent: settings.accent,
            pureBlack: settings.pureBlack,
          ),
          home: const HomePage(),
        ),
      ),
    );
  }
}
