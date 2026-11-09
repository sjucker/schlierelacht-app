import 'package:flutter/material.dart';

import '../screens/attraction_detail_screen.dart';
import '../screens/festplan_screen.dart';
import '../screens/gastro_screen.dart';
import '../screens/info_screen.dart';
import '../screens/jahrgangstreffen_screen.dart';
import '../screens/location_detail_screen.dart';
import '../screens/news_detail_screen.dart';
import '../screens/news_list_screen.dart';
import '../screens/programm_screen.dart';
import '../screens/sponsoring_screen.dart';

/// Website links that open in the app (Android App Links / iOS Universal
/// Links), e.g. a shared `https://schlierelacht.ch/programm/A12`.
///
/// Flutter hands the link's path to the navigator as a route name. On a cold
/// start it pushes every prefix (`/`, `/programm`, `/programm/A12`), which
/// yields a natural back stack; prefixes without a screen are skipped. A link
/// arriving while the app runs pushes just the full path.
///
/// Only the paths below are claimed, in three places that must stay in sync:
/// this function, the `<intent-filter android:autoVerify="true">` in
/// `android/app/src/main/AndroidManifest.xml`, and the website's
/// `public/.well-known/apple-app-site-association`. Everything else — notably
/// the Jahrgangstreffen registration and Datenschutz — keeps opening in the
/// browser.
Route<void>? deepLinkRoute(RouteSettings settings) {
  final page = deepLinkPage(settings.name);
  return page == null ? null : MaterialPageRoute(settings: settings, builder: (_) => page);
}

/// The screen for a website path, or null if the app has none for it.
Widget? deepLinkPage(String? routeName) {
  final segments = Uri.tryParse(routeName ?? '')?.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments == null) return null;
  return switch (segments) {
    ['news'] => Scaffold(
      appBar: AppBar(title: const Text('News')),
      body: const NewsListScreen(),
    ),
    ['news', final id] => switch (int.tryParse(id)) {
      final newsId? => NewsDetailScreen(newsId: newsId),
      null => null,
    },
    ['programm'] => const ProgrammScreen(),
    ['programm', final id] => AttractionDetailScreen(externalId: id),
    ['gastro'] => const GastroScreen(),
    ['gastro', final id] => AttractionDetailScreen(externalId: id, section: AttractionSection.gastro),
    ['locations', final id] => LocationDetailScreen(externalId: id),
    ['festplan'] => const FestplanScreen(),
    ['jahrgangstreffen', 'liste'] => const JahrgangstreffenScreen(),
    ['sponsoren'] => const SponsoringScreen(),
    ['info'] => const InfoScreen(),
    _ => null,
  };
}
