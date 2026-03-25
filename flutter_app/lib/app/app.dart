import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:focus_read/core/l10n/app_localizations.dart';
import '../features/settings/settings_provider.dart';
import '../shared/adaptive/adaptive_app.dart';
import 'router.dart';
import 'theme.dart';

class FocusReadApp extends ConsumerWidget {
  const FocusReadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return AdaptiveApp(
      title: 'Focus Read',
      materialTheme: focusReadTheme,
      cupertinoTheme: focusReadCupertinoTheme,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(settings.appLanguage),
    );
  }
}
