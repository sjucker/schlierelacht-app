import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Reports errors from users' phones to Firebase Crashlytics.
///
/// Release builds only: in debug builds collection is switched off and the
/// handlers are not installed, so errors keep showing in the console as
/// before and the dashboard holds real-world reports only.
///
/// Uncaught Dart errors (from the framework and from async code) are recorded
/// as non-fatal: they don't end the app, and counting them as crashes would
/// make the crash-free rate meaningless. Native crashes are still recorded as
/// crashes by the Crashlytics SDK itself.
abstract final class CrashReporting {
  /// Call once, after `Firebase.initializeApp` succeeded.
  static Future<void> enable() async {
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    if (kDebugMode) return;

    FlutterError.onError = crashlytics.recordFlutterError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack);
      return true; // handled: reported instead of only logged
    };
  }
}
