# Firebase / Push notifications setup

Push notifications use **Firebase Cloud Messaging (FCM)**. `main.dart` guards
`Firebase.initializeApp` in a try/catch, so the app still runs if initialization
fails. The Firebase client config is **not committed** (this repository is public):
`lib/firebase_options.dart`, `firebase.json` and `android/app/google-services.json`
are gitignored and generated on each machine by `flutterfire configure` (step 2).
Without them the app does not compile.

There are two independent halves:

1. **App (this repo)** — receives notifications and registers its device token.
2. **Backend (`schlierelacht-admin`)** — sends notifications via the Firebase
   Admin SDK (the "Push senden" admin view + `POST /api/v1/push/register`).

Both talk to the **same Firebase project**.

---

## 0. Prerequisites (one-time tooling)

```bash
# Firebase CLI (needs Node.js); then log in with the Google account that owns the project
npm install -g firebase-tools
firebase login

# FlutterFire CLI
dart pub global activate flutterfire_cli
# ensure the pub global bin dir is on PATH, e.g. on Windows:
#   %LOCALAPPDATA%\Pub\Cache\bin
```

---

## 1. Create the Firebase project

1. Go to <https://console.firebase.google.com/> → **Add project** (e.g.
   `schlierelacht`). Analytics is optional.
2. Nothing else to click here — `flutterfire configure` registers the apps for you.

---

## 2. Configure the app (client)

From `schlierelacht-app/`:

```bash
flutterfire configure
```

- Select the Firebase project from step 1.
- Select the platforms: **android** and **ios**.
- Confirm the bundle/application id **`ch.schlierelacht.schlierelacht_app`**
  (must match `android/app/build.gradle.kts` `applicationId` and the iOS bundle id).

This writes **`lib/firebase_options.dart`** (the options the app initializes with:
`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`),
**`firebase.json`** (the project and app IDs, for the next configure run) and
**`android/app/google-services.json`**, which the `com.google.gms.google-services`
Gradle plugin in `android/app/build.gradle.kts` requires. All three are gitignored;
run this on every new clone and in CI.

Verify:

```bash
flutter pub get
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk...
```

On launch you should no longer see `Firebase not configured — push notifications
disabled.` in the logs. On first run, the onboarding screen asks for notification
permission; granting it registers the device token with the backend and
subscribes the device to the `general` topic.

### iOS extra steps (required for push on iOS)

Push does **not** work in the iOS Simulator — use a real device.

1. In **Xcode** (`ios/Runner.xcworkspace`) → *Signing & Capabilities* → **+ Capability**
   → add **Push Notifications**. (Background Modes → *Remote notifications* is
   already declared in `ios/Runner/Info.plist` via `UIBackgroundModes`.)
2. In the **Apple Developer** portal create an **APNs Auth Key** (`.p8`).
3. In the **Firebase console** → *Project settings* → *Cloud Messaging* →
   *Apple app configuration* → upload the APNs key (with Key ID + Team ID).

Android needs nothing beyond `flutterfire configure`; the `POST_NOTIFICATIONS`
permission is already declared in the manifest.

---

## 3. Configure the backend (sending)

The backend sends pushes with the **Firebase Admin SDK**, authenticated by a
**service-account JSON** (a server credential — different from the client config).

1. Firebase console → *Project settings* → **Service accounts** → **Generate new
   private key** → download the JSON. Keep it secret; **do not commit it.**
2. Pass the **content** of that JSON file (not its path) in the
   `FIREBASE_CREDENTIALS` environment variable. It maps to
   `app.firebase-credentials` in `application.properties` and is read by
   `config/FirebaseConfig.java`.

   ```bash
   # Heroku (PROD)
   heroku config:set FIREBASE_CREDENTIALS="$(cat service-account.json)" --app schlierelacht-admin

   # locally, from schlierelacht-admin/
   FIREBASE_CREDENTIALS="$(cat /path/to/service-account.json)" mvn spring-boot:run
   ```

   On startup the log shows `Firebase Admin SDK initialised for project …`.
   When `FIREBASE_CREDENTIALS` is unset or not a valid service-account JSON, the
   `FirebaseMessaging` bean is `null` (an invalid value is logged as an error,
   never its content) and the admin "Push senden" view shows sending as
   disabled — the rest of the backend runs normally.

---

## 4. Send a test notification

**From the admin UI:** log into the Vaadin admin → **Push senden** → enter a
title + message and send. This goes through `PushService.sendToGeneralTopic(...)`
and reaches every device subscribed to the `general` topic.

**From the Firebase console** (no backend needed): *Messaging* → *New campaign* →
*Notifications* → target the topic **`general`**.

Optionally include a `route` data value (e.g. `news`) — the app reads
`message.data['route']` when a notification is tapped.

---

## Troubleshooting

- **`Target of URI doesn't exist: 'firebase_options.dart'`** or **`File
  google-services.json is missing`** → this clone was never configured; run
  `flutterfire configure` (step 2).
- **`Firebase not configured` in logs** → initialization failed; re-run
  `flutterfire configure` and check the platforms you selected.
- **No token registered / no `push_device_token` row** → notification permission
  was denied, or the backend base URL is wrong (`API_BASE_URL`). Registration is
  best-effort and never blocks the app.
- **iOS: no notifications** → missing APNs key in Firebase, Push Notifications
  capability not enabled, or testing on the Simulator (use a real device).
- **Admin view says sending disabled** → `FIREBASE_CREDENTIALS` is unset or is not
  a valid service-account JSON (check the startup log).
