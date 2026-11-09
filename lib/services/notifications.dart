import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../api/programm_api.dart';
import '../models/programm_point.dart';
import '../utils/deep_links.dart';
import 'prefs.dart';

/// Local notifications: the OS notification permission (shared with push) and
/// reminders before favorited acts.
///
/// Reminders are scheduled on the device — no backend, and they fire offline.
/// They are re-planned from the programm whenever the favorites or the
/// reminder switch change, at startup, and when [OfflineWarmup] reloads the
/// programm (so a moved slot moves its reminder). Tapping one opens the act.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// How long before an act starts its reminder fires.
  static const reminderLead = Duration(minutes: 15);

  /// iOS keeps at most 64 pending notifications per app; stay below that.
  static const maxReminders = 50;

  /// The programm's wall-clock times are Swiss local time, wherever the phone is.
  static const _festTimeZone = 'Europe/Zurich';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<void> _syncing = Future.value();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'favorite_reminders',
      'Erinnerungen an Favoriten',
      channelDescription: 'Kurz bevor ein favorisierter Act beginnt',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Sets up the plugin, opens the act when the app was launched from a
  /// reminder, and keeps reminders in sync with the favorites. Call once from
  /// `main` after `runApp`.
  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is asked in onboarding / the Mitteilungen screen, not here.
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        ),
        onDidReceiveNotificationResponse: (response) => openDeepLink(response.payload),
      );
      _ready = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        openDeepLink(launch!.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('Local notifications unavailable: $e');
      return;
    }
    Prefs.instance.favorites.addListener(resyncReminders);
    Prefs.instance.remindersEnabled.addListener(resyncReminders);
    resyncReminders();
  }

  // --- Permission (one OS switch for reminders and push) -------------------

  /// Whether the OS currently lets the app show notifications.
  Future<bool> isPermitted() async {
    if (!_ready) return false;
    try {
      if (Platform.isAndroid) {
        return await _android?.areNotificationsEnabled() ?? false;
      }
      return (await _ios?.checkPermissions())?.isEnabled ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Shows the OS prompt (if the OS still allows asking) and returns whether
  /// notifications are now permitted.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (Platform.isAndroid) {
        return await _android?.requestNotificationsPermission() ?? false;
      }
      return await _ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the app's notification settings — the only way back once the user
  /// has declined the prompt.
  Future<void> openSettings() async {
    try {
      await _plugin.openAppNotificationSettings();
    } catch (_) {}
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  // --- Favorite reminders ---------------------------------------------------

  /// Loads the programm (cache fallback included) and re-plans the reminders.
  void resyncReminders() {
    _enqueue(() async {
      List<ProgrammPoint> points;
      try {
        points = await ProgrammApi().fetchProgramm();
      } catch (_) {
        return; // nothing cached yet: keep what is scheduled
      }
      await _schedule(points);
    });
  }

  /// Re-plans the reminders from an already loaded programm.
  void syncReminders(List<ProgrammPoint> points) => _enqueue(() => _schedule(points));

  /// Runs re-plans one after another, so two quick favorite toggles can't
  /// interleave their cancel + schedule steps.
  void _enqueue(Future<void> Function() task) {
    if (!_ready) return;
    _syncing = _syncing.then((_) => task()).catchError((Object e) => debugPrint('Reminder sync failed: $e'));
  }

  Future<void> _schedule(List<ProgrammPoint> points) async {
    await _plugin.cancelAllPendingNotifications();
    if (!Prefs.instance.remindersEnabled.value) return;
    final zone = tz.getLocation(_festTimeZone);
    final planned = planReminders(points, Prefs.instance.favorites.value, tz.TZDateTime.now(zone), zone);
    for (var i = 0; i < planned.length; i++) {
      final r = planned[i];
      await _plugin.zonedSchedule(
        id: i,
        scheduledDate: r.at,
        notificationDetails: _details,
        // Inexact: exact alarms need an extra permission on Android 14+, and a
        // few minutes' drift is fine for a 15-minute heads-up.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
        payload: r.route,
      );
    }
  }
}

/// One reminder to schedule: when, what it says, and the screen a tap opens.
typedef PlannedReminder = ({tz.TZDateTime at, String title, String body, String route});

/// The reminders for [favorites] (attraction `externalId`s): one
/// [NotificationService.reminderLead] before every favorited entry with a start
/// time whose reminder is still ahead of [now], earliest first, capped at
/// [NotificationService.maxReminders]. Entries without a start time (all-day)
/// get none. Times in the programm are wall-clock times in [zone].
List<PlannedReminder> planReminders(List<ProgrammPoint> points, Set<String> favorites, tz.TZDateTime now, tz.Location zone) {
  final planned = <PlannedReminder>[];
  for (final p in points) {
    if (!favorites.contains(p.attraction.externalId)) continue;
    final time = p.entry.fromTime?.split(':');
    if (time == null || time.length < 2) continue;
    final hour = int.tryParse(time[0]);
    final minute = int.tryParse(time[1]);
    if (hour == null || minute == null) continue;
    final d = p.entry.fromDate;
    final start = tz.TZDateTime(zone, d.year, d.month, d.day, hour, minute);
    final at = start.subtract(NotificationService.reminderLead);
    if (!at.isAfter(now)) continue;
    final hhmm = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    planned.add((at: at, title: '${p.attraction.name} beginnt um $hhmm', body: p.entry.location.name, route: '/programm/${p.attraction.externalId}'));
  }
  planned.sort((a, b) => a.at.compareTo(b.at));
  return planned.take(NotificationService.maxReminders).toList();
}
