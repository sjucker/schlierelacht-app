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
