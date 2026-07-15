import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'config.dart';
import 'firebase_options.dart';
import 'screens/landing_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/prefs.dart';
import 'services/push.dart';

const Color _festBlue = Color(0xFF2B3585);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required for de_CH date formatting (weekday names) used across the app.
  await initializeDateFormatting('de_CH');
  await Prefs.init();

  if (mapboxAccessToken.isNotEmpty) {
    MapboxOptions.setAccessToken(mapboxAccessToken);
  }

  // Firebase is optional at runtime: until `flutterfire configure` has added
  // the platform config, initialization throws and push stays dormant.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    PushService.instance.markAvailable();
    PushService.instance.setupHandlers();
  } catch (_) {
    debugPrint('Firebase not configured — push notifications disabled.');
  }

  runApp(const SchlierelachtApp());
}

class SchlierelachtApp extends StatelessWidget {
  const SchlierelachtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schliere lacht',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _festBlue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de', 'CH')],
      locale: const Locale('de', 'CH'),
      home: Prefs.instance.onboardingComplete
          ? const LandingScreen()
          : const OnboardingScreen(),
    );
  }
}
