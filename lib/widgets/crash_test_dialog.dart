import 'package:material_ui/material_ui.dart';

import '../services/crash_reporting.dart';

/// Hidden check that crash reports reach Crashlytics, opened by a long press
/// on the version at the bottom of the landing page. Sends a non-fatal test
/// error, or crashes the app for real (reported on the next start). In debug
/// builds, or without Firebase, it only says that reporting is off.
Future<void> showCrashTestDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      void close() => Navigator.of(dialogContext).pop();
      if (!CrashReporting.active) {
        return AlertDialog(
          title: const Text('Crash-Reporting testen'),
          content: const Text('Crash-Reporting ist in diesem Build ausgeschaltet. Es läuft nur in Release-Builds mit Firebase.'),
          actions: [TextButton(onPressed: close, child: const Text('OK'))],
        );
      }
      return AlertDialog(
        title: const Text('Crash-Reporting testen'),
        content: const Text(
          'Ein Testfehler erscheint nach einigen Minuten in Firebase Crashlytics.\n\n'
          'Ein Testabsturz schliesst die App; der Bericht wird beim nächsten Start gesendet.',
        ),
        actions: [
          TextButton(onPressed: close, child: const Text('Abbrechen')),
          TextButton(onPressed: CrashReporting.crash, child: const Text('Testabsturz')),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              close();
              await CrashReporting.sendTestError();
              messenger?.showSnackBar(const SnackBar(content: Text('Testfehler an Crashlytics gesendet.')));
            },
            child: const Text('Testfehler senden'),
          ),
        ],
      );
    },
  );
}
