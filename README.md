# Schlierelacht Festapp

## Release

### Setup

Add the following files (all git-ignored, never commit them):

* `android/upload-keystore.p12` — the Play Console upload key
* `android/key.properties` — its credentials (`storeFile` is relative to `android/`):

  ```properties
  storeFile=upload-keystore.p12
  storePassword=...
  keyAlias=upload
  keyPassword=...
  ```

* `android/gradle.properties` — add `MAPBOX_DOWNLOADS_TOKEN=sk.your_token_here` (secret Mapbox token with the
  `Downloads:Read` scope, needed to download the Mapbox Android SDK)

Without `key.properties`, release builds are signed with the debug key, which Play Console rejects.

Also run `flutterfire configure` (see [Firebase](#firebase)): the Firebase config files are git-ignored too, and
without them the app does not build.

### Version

`version: 1.0.0+1` in `pubspec.yaml` is `<version name>+<build number>`; it becomes the Android `versionName` /
`versionCode` and the iOS `CFBundleShortVersionString` / `CFBundleVersion`, and the app shows it at the bottom of the
landing page ("Version 1.0.0 (1)").

* **Build number** (`+1`): must be higher for **every** upload to Play Console or App Store Connect — both stores
  reject a number they have seen. Both platforms share it, so raise it after each release.
* **Version name** (`1.0.0`): what users see in the stores. Raise the minor version for new features (`1.1.0`), the
  patch version for fixes only (`1.0.1`).

### Android

* `flutter build appbundle --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here`
* Upload [app-release.aab](build/app/outputs/bundle/release/app-release.aab) to Play Console

### iOS

* `flutter build ipa --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here`
* Upload [schlierelacht_app.ipa](build/ios/ipa/schlierelacht_app.ipa) using the Apple Transporter macOS app

After releasing, increase the build number in `pubspec.yaml` (see [Version](#version)).

### Website links open the app (App Links / Universal Links)

Links to `https://schlierelacht.ch` pages the app can show (Programm, Gastro, News, …)
open in the app. The claimed paths live in three places that must stay in sync:
`lib/utils/deep_links.dart`, the App Links `<intent-filter>` in
`android/app/src/main/AndroidManifest.xml`, and the website's
`public/.well-known/apple-app-site-association`.

Manual steps, once:

* **Android** — in Play Console → *Test and release → App integrity → App signing*, copy the **SHA-256** of the *App signing key* into the website's
  `public/.well-known/assetlinks.json`
  (replace `REPLACE_WITH_PLAY_APP_SIGNING_KEY_SHA256`) and deploy the website. To test a locally
  signed build, add its fingerprint too (`keytool -list -v -keystore android/upload-keystore.p12`).
  Check with `adb shell pm get-app-links ch.schlierelacht.schlierelacht_app` (`verified`).
* **iOS** — `ios/Runner/Runner.entitlements` declares `applinks:schlierelacht.ch`; the *Associated Domains* capability must be enabled for the App ID (Xcode's
  automatic signing does
  this on the next build; otherwise in the Apple Developer portal → Identifiers).

Until the website serves the files, links simply keep opening in the browser.

## Firebase

* Install the Firebase CLI: https://firebase.google.com/docs/cli
* `firebase login`
* `dart pub global activate flutterfire_cli`
* Production
    * `$HOME/.pub-cache/bin/flutterfire configure --project=schlierelacht-app` (macOS)
    * `& $env:userprofile\AppData\Local\Pub\Cache\bin\flutterfire.bat configure --project=schlierelacht-app` (Windows)

**Run this once after cloning.** The files it generates — `lib/firebase_options.dart`, `firebase.json` and
`android/app/google-services.json` — are gitignored, because this repository is public. Without them the app does
not compile (`main.dart` imports `firebase_options.dart`) and the Android build fails (the Google Services Gradle
plugin needs `google-services.json`). A CI build has to create them the same way, or restore them from secrets.

### Test crash reporting

Crash reports (Firebase Crashlytics) are only sent from **release** builds. To check that they arrive:

1. Install a release build on a device: `flutter run --release --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here`
2. On the landing page, scroll to the bottom and **long-press the version** ("Version 1.0.0 (1)").
3. **Testfehler senden** records a non-fatal `CrashReportingTest` error; **Testabsturz** crashes the app — start it
   again, the report is sent then.
4. Look in the Firebase console → Crashlytics. The first report can take a few minutes to show up.

## Development

### Run Configuration

* When using Android Studio or IntelliJ, copy the run configuration `main.dart (Example)`
    * add your Mapbox access token to `--dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here` under additional run args

### Xcode build problems

For cleaning and rebuilding everything regarding iOS perform the following commands:

```
flutter clean
flutter pub get
cd ios
rm -rf Pods
rm Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*
pod install
```

## Icons

* See [flutter_launcher_icons.yaml](flutter_launcher_icons.yaml)
* `dart run flutter_launcher_icons`
