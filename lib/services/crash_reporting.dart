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
  /// Whether reports are being sent: Firebase initialized, release build.
  static bool get active => _active;
  static bool _active = false;

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
    _active = true;
  }

  // --- Manual test (long-press the version on the landing page) -----------

  /// Records a non-fatal test error, the path every uncaught Dart error
  /// takes, and asks for it to be sent right away.
  static Future<void> sendTestError() async {
    if (!_active) return;
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.recordError(const CrashReportingTest(), StackTrace.current, reason: 'manual test from the app');
    await crashlytics.sendUnsentReports();
  }

  /// Crashes the app natively — the path of a real crash. The report is sent
  /// when the app is started again.
  static void crash() {
    if (_active) FirebaseCrashlytics.instance.crash();
  }
}

/// The error [CrashReporting.sendTestError] records, easy to find and to
/// ignore in the Crashlytics dashboard.
class CrashReportingTest implements Exception {
  const CrashReportingTest();

  @override
  String toString() => 'CrashReportingTest: manual test, not a real error';
}
