import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'config.dart';
import 'firebase_options.dart';
import 'screens/landing_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/offline_warmup.dart';
import 'services/prefs.dart';
import 'services/push.dart';
import 'theme.dart';
import 'utils/deep_links.dart';
import 'widgets/offline_banner.dart';

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
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    PushService.instance.markAvailable();
  } catch (_) {
    debugPrint('Firebase not configured — push notifications disabled.');
  }

  runApp(const SchlierelachtApp());

  // A tapped push opens its screen (via navigatorKey), and the device token
  // is re-registered.
  unawaited(PushService.instance.start());

  // Fill the offline cache in the background (and again on resume).
  OfflineWarmup.start();
}

class SchlierelachtApp extends StatelessWidget {
  const SchlierelachtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schliere lacht',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,
      theme: buildFestTheme(),
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: const [Locale('de', 'CH')],
      locale: const Locale('de', 'CH'),
      home: Prefs.instance.onboardingComplete ? const LandingScreen() : const OnboardingScreen(),
      // Website links (App Links / Universal Links) open the matching screen.
      onGenerateRoute: deepLinkRoute,
      // A claimed link the app can't map (e.g. a malformed id) shows the
      // landing page instead of failing.
      onUnknownRoute: (settings) => MaterialPageRoute(settings: settings, builder: (_) => const LandingScreen()),
      // Below every screen: a notice while saved (offline) data is shown.
      builder: (context, child) => OfflineBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
