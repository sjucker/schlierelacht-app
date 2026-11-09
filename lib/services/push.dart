import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../api/push_api.dart';
import '../utils/deep_links.dart';

/// Global messenger key so [PushService] can surface foreground notifications
/// as SnackBars from outside the widget tree. Wired into `MaterialApp`.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Firebase Cloud Messaging integration.
///
/// All entry points are guarded by [_available] (set true only after
/// `Firebase.initializeApp` succeeds in `main.dart`), so the app runs normally
/// before `flutterfire configure` has been run — FCM simply stays dormant.
///
/// The admin's "Push senden" broadcasts to the `general` topic with an
/// optional `route` (a website path such as `news`); tapping the notification
/// opens that screen via [openDeepLink]. Reminders for favorited acts are
/// local notifications instead (see `NotificationService`).
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  static const generalTopic = 'general';

  final PushApi _api = PushApi();
  bool _available = false;
  StreamSubscription<String>? _tokenRefresh;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Marks FCM usable. Called by `main.dart` after a successful Firebase init.
  void markAvailable() => _available = true;

  /// Startup wiring, once from `main`: foreground SnackBars, opening the
  /// `route` of a tapped push (also when the tap launched the app), and
  /// re-registering the device when permission is already granted — so a
  /// rotated token reaches the backend on every launch, not just the first.
  Future<void> start() async {
    if (!_available) return;
    try {
      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen((message) => openDeepLink(_route(message)));
      final initial = await _messaging.getInitialMessage();
      if (initial != null) openDeepLink(_route(initial));
    } catch (_) {
      // Best-effort: the app works without push.
    }
    await registerIfPermitted();
  }

  /// Asks for notification permission and, if granted, registers the device.
  /// Used by onboarding; no-op without FCM.
  Future<void> requestAndRegister() async {
    if (!_available) return;
    try {
      if (_permitted(await _messaging.requestPermission())) await _registerDevice();
    } catch (_) {
      // Best-effort: never block onboarding on push setup.
    }
  }

  /// Registers the device if notifications are already permitted (e.g. after
  /// the user enabled them in the system settings). Never prompts.
  Future<void> registerIfPermitted() async {
    if (!_available) return;
    try {
      if (_permitted(await _messaging.getNotificationSettings())) await _registerDevice();
    } catch (_) {}
  }

  static bool _permitted(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional;

  /// Registers the token with the backend (an upsert, so repeating it is
  /// harmless), follows token rotation, and subscribes to the broadcast topic.
  Future<void> _registerDevice() async {
    // iOS delivers the FCM token only once the APNS token is available.
    if (Platform.isIOS) {
      await _messaging.getAPNSToken();
    }

    // getToken/onTokenRefresh are deprecated in firebase_messaging 17 in
    // favour of register()/onRegistered, which yield a Firebase Installation
    // ID instead of a registration token. The backend (PushService) sends to
    // registration tokens, so migrating needs a coordinated backend change.
    // ignore: deprecated_member_use
    final token = await _messaging.getToken();
    if (token != null) {
      await _register(token);
    }
    // ignore: deprecated_member_use
    _tokenRefresh ??= _messaging.onTokenRefresh.listen(_register);

    await _messaging.subscribeToTopic(generalTopic);
  }

  Future<void> _register(String token) async {
    try {
      await _api.register(token: token, platform: Platform.isIOS ? 'ios' : 'android', locale: 'de');
    } catch (_) {
      // Backend registration is best-effort; topic subscription still works.
    }
  }

  static String? _route(RemoteMessage message) {
    final route = message.data['route'];
    return route is String && route.trim().isNotEmpty ? route.trim() : null;
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final title = notification.title;
    final body = notification.body ?? '';
    final route = _route(message);
    messenger.showSnackBar(
      SnackBar(
        content: Text(title == null ? body : '$title\n$body'),
        duration: const Duration(seconds: 6),
        action: deepLinkPage(route) == null ? null : SnackBarAction(label: 'Öffnen', onPressed: () => openDeepLink(route)),
      ),
    );
  }
}
