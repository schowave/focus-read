import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'platform_utils.dart';

class AdaptiveApp extends StatelessWidget {
  final String title;
  final ThemeData materialTheme;
  final CupertinoThemeData cupertinoTheme;
  final GoRouter routerConfig;
  final Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates;
  final Iterable<Locale> supportedLocales;
  final Locale? locale;

  const AdaptiveApp({
    super.key,
    required this.title,
    required this.materialTheme,
    required this.cupertinoTheme,
    required this.routerConfig,
    required this.localizationsDelegates,
    required this.supportedLocales,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    if (isIOSPlatform) {
      return CupertinoApp.router(
        title: title,
        theme: cupertinoTheme,
        routerConfig: routerConfig,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        locale: locale,
        builder: (context, child) {
          return Theme(
            data: materialTheme,
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
    }

    return MaterialApp.router(
      title: title,
      theme: materialTheme,
      routerConfig: routerConfig,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
    );
  }
}
