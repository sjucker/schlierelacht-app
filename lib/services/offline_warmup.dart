import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_cache.dart';
import '../api/attraction_api.dart';
import '../api/location_api.dart';
import '../api/meetup_api.dart';
import '../api/news_api.dart';
import '../api/ok_api.dart';
import '../api/programm_api.dart';
import '../api/sponsoring_api.dart';
import '../models/attraction_type.dart';
import 'notifications.dart';

/// Pre-loads the whole public API into [ApiCache] in the background, so every
/// screen — including act, Gastro, location and news details never opened —
/// works without a connection. Runs at startup and whenever the app returns
/// to the foreground, at most every [interval] (the API is ~100 small requests).
abstract final class OfflineWarmup {
  static const interval = Duration(hours: 3);
  static const _kLastRun = 'offline_warmup_at';
  static bool _running = false;
  static AppLifecycleListener? _listener;

  /// Runs a warm-up now and on every resume. Call once from `main`.
  static void start() {
    _listener ??= AppLifecycleListener(onResume: () => unawaited(run()));
    unawaited(run());
  }

  static Future<void> run() async {
    if (_running) return;
    _running = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = DateTime.tryParse(prefs.getString(_kLastRun) ?? '');
      if (last != null && DateTime.now().difference(last) < interval) return;

      // Lists first. If the first one had to come from the cache we are
      // offline — stop instead of walking every detail into a timeout.
      final programm = await ProgrammApi().fetchProgramm();
      if (ApiCache.offlineSince.value != null) return;
      // A moved slot moves its favorite reminder.
      NotificationService.instance.syncReminders(programm);
      final attractions = AttractionApi();
      final gastro = await attractions.fetchAttractions(types: {AttractionType.food});
      final locations = await LocationApi().fetchLocations();
      final news = await NewsApi().fetchNews();
      final sponsoring = SponsoringApi();
      await Future.wait([sponsoring.fetchSponsorings(), sponsoring.fetchTypes(), OkApi().fetchOk(), MeetupApi().fetchEntries()]);

      // Then every detail page, a few at a time. Single failures are fine.
      final actIds = {for (final p in programm) p.attraction.externalId, for (final a in gastro) a.externalId};
      final locationIds = {for (final p in programm) p.entry.location.externalId, for (final l in locations) l.externalId};
      final locationApi = LocationApi();
      final newsApi = NewsApi();
      final details = <Future<Object?> Function()>[
        for (final id in actIds) () => attractions.fetchAttraction(id),
        for (final id in locationIds) () => locationApi.fetchLocation(id),
        for (final n in news) () => newsApi.fetchNewsById(n.id),
      ];
      for (var i = 0; i < details.length; i += 4) {
        await Future.wait(details.skip(i).take(4).map((load) => load().then<Object?>((v) => v, onError: (_) => null)));
      }
      await prefs.setString(_kLastRun, DateTime.now().toIso8601String());
    } catch (_) {
      // Offline or backend down: keep what is cached, try again next time.
    } finally {
      _running = false;
    }
  }
}
