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

### Android

* `flutter build appbundle --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here`
* Upload [app-release.aab](build/app/outputs/bundle/release/app-release.aab) to Play Console

### iOS

* `flutter build ipa --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here`
* Upload [schlierelacht_app.ipa](build/ios/ipa/schlierelacht_app.ipa) using the Apple Transporter macOS app

After releasing, increase the build number of the version in `pubspec.yaml`.

### Website links open the app (App Links / Universal Links)

Links to `https://schlierelacht.ch` pages the app can show (Programm, Gastro, News, …)
open in the app. The claimed paths live in three places that must stay in sync:
`lib/utils/deep_links.dart`, the App Links `<intent-filter>` in
`android/app/src/main/AndroidManifest.xml`, and the website's
`public/.well-known/apple-app-site-association`.

Manual steps, once:

* **Android** — in Play Console → *Test and release → App integrity → App signing*, copy the
  **SHA-256** of the *App signing key* into the website's `public/.well-known/assetlinks.json`
  (replace `REPLACE_WITH_PLAY_APP_SIGNING_KEY_SHA256`) and deploy the website. To test a locally
  signed build, add its fingerprint too (`keytool -list -v -keystore android/upload-keystore.p12`).
  Check with `adb shell pm get-app-links ch.schlierelacht.schlierelacht_app` (`verified`).
* **iOS** — `ios/Runner/Runner.entitlements` declares `applinks:schlierelacht.ch`; the
  *Associated Domains* capability must be enabled for the App ID (Xcode's automatic signing does
  this on the next build; otherwise in the Apple Developer portal → Identifiers).

Until the website serves the files, links simply keep opening in the browser.

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
