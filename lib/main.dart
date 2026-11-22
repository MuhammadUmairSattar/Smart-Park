import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_core.dart';
import 'features/auth/auth_screen.dart';
import 'features/parking/dashboard_screen.dart';
import 'features/parking/parking_logic.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await AppLocalizations.init(prefs);
  await ParkingDatabase.instance.database;

  final apiService = ApiService();
  final storedSession = await apiService.readStoredSession();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        apiServiceProvider.overrideWithValue(apiService),
        initialSessionProvider.overrideWithValue(storedSession),
      ],
      child: const SmartParkEnterpriseApp(),
    ),
  );
}

class SmartParkEnterpriseApp extends ConsumerWidget {
  const SmartParkEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final themeData = settings.activeTheme.toThemeData(settings.activeStyle);

    return ValueListenableBuilder<LanguageModel>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: settings.businessName,
          theme: themeData,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales:
              AppLocalizations.supportedLanguages.map((e) => Locale(e.code)),
          locale: Locale(lang.code),
          builder: (context, child) => Directionality(
            textDirection: lang.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
          home: authState.isAuthenticated
              ? const ProDashboardScreen()
              : const AuthScreen(),
        );
      },
    );
  }
}
