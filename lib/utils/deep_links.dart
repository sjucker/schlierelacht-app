import 'package:flutter/material.dart';

import '../screens/attraction_detail_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/festplan_screen.dart';
import '../screens/gastro_screen.dart';
import '../screens/info_screen.dart';
import '../screens/jahrgangstreffen_screen.dart';
import '../screens/location_detail_screen.dart';
import '../screens/messages_screen.dart';
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

/// The app's navigator, so links arriving outside the widget tree (push and
/// reminder taps) can open their screen. Wired into `MaterialApp`.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Opens the screen for [route] on top of the current one — the target of a
/// tapped push (`route` data, e.g. `news` or `/programm/A12`) or reminder.
/// Accepts a path with or without leading slash, or a full website URL;
/// anything the app can't show is ignored. Before the first frame (cold start
/// from a notification) it waits until the navigator exists.
void openDeepLink(String? route) {
  final page = deepLinkPage(route);
  if (page == null) return;
  final navigator = navigatorKey.currentState;
  if (navigator == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => openDeepLink(route));
    return;
  }
  navigator.push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: route),
      builder: (_) => page,
    ),
  );
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
    // App-only (the website has no such page), so not claimed as an App Link:
    // reached through a push with route `meldungen`.
    ['meldungen'] => const MessagesScreen(),
    // App-only too: a push with route `faq`.
    ['faq'] => const FaqScreen(),
    _ => null,
  };
}
