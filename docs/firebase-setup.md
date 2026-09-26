# Firebase / Push notifications setup

Push notifications use **Firebase Cloud Messaging (FCM)**. The code is already in
place but stays **dormant until Firebase is configured** — the app runs normally
without it (`main.dart` guards `Firebase.initializeApp` in a try/catch, and
`lib/firebase_options.dart` ships as a throwing placeholder).

There are two independent halves:

1. **App (this repo)** — receives notifications and registers its device token.
2. **Backend (`schlierelacht-admin`)** — sends notifications via the Firebase
   Admin SDK (the "Push senden" admin view + `POST /api/push/register`).

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

This **overwrites `lib/firebase_options.dart`** with your project's real values
and downloads the platform config files. Because the app uses **options-based
init** (`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`),
Android needs **no** `google-services.json` and **no** `com.google.gms.google-services`
Gradle plugin — `firebase_options.dart` is sufficient.

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
2. Point the backend at it via the `FIREBASE_CREDENTIALS` environment variable
   (absolute path to the file). It maps to `app.firebase-credentials` in
   `application.properties` and is read by `config/FirebaseConfig.java`.

   ```bash
   # from schlierelacht-admin/
   FIREBASE_CREDENTIALS=/absolute/path/to/service-account.json mvn spring-boot:run
   ```

   When `FIREBASE_CREDENTIALS` is unset, the `FirebaseMessaging` bean is `null`
   and the admin "Push senden" view shows sending as disabled — the rest of the
   backend runs normally.

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

- **`Firebase not configured` in logs** → `lib/firebase_options.dart` is still the
  placeholder; re-run `flutterfire configure`.
- **No token registered / no `push_device_token` row** → notification permission
  was denied, or the backend base URL is wrong (`API_BASE_URL`). Registration is
  best-effort and never blocks the app.
- **iOS: no notifications** → missing APNs key in Firebase, Push Notifications
  capability not enabled, or testing on the Simulator (use a real device).
- **Admin view says sending disabled** → `FIREBASE_CREDENTIALS` is unset or points
  at a missing/invalid file.
