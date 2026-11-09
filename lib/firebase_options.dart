// PLACEHOLDER — replaced by `flutterfire configure`.
//
// Until you run `flutterfire configure` (which regenerates this file with your
// Firebase project's real values), Firebase and push notifications stay
// disabled: [DefaultFirebaseOptions.currentPlatform] throws and the guarded
// init in `main.dart` swallows it, so the rest of the app runs normally.
//
// Using options-based initialization means Firebase Messaging works without a
// `google-services.json` / `GoogleService-Info.plist` or the Gradle
// google-services plugin. On iOS you still need to enable the Push
// Notifications capability and upload an APNs key in the Firebase console.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase is not configured. Run `flutterfire configure` to generate '
    'lib/firebase_options.dart with your project credentials.',
  );
}
