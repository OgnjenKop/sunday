# Sun Day — Android Studio Quick Start

## Prerequisites
- Flutter SDK + Android toolchain installed
- Android Studio with Flutter and Dart plugins
- Android SDK Platforms: API 33+ (Android 13) or API 34 (Android 14)
- Health Connect app (built-in on Android 14; install from Play Store on 13)

## Open the Project
- In Android Studio, open the `sunday_flutter` folder (not the repo root).
- Let Studio run “Pub get” automatically, or run Tools → Flutter → Pub get.

## Configure JDK/SDK
- Gradle JDK: Settings → Build, Execution, Deployment → Gradle → Gradle JDK = Embedded JDK (17+)
- Ensure an emulator (AVD) with Google APIs, API 33/34, or connect a physical device with USB debugging enabled.

## Run
- Select your device in the toolbar.
- Click Run.
- If an older install exists with a different package name, uninstall it first.

## Permissions & Features
- Location: allow “While using the app” to fetch local UV.
- Notifications (Android 13+): allow to receive alerts.
- Health Connect: when saving/reading Vitamin D, accept requested permissions.
  - Emulators may not support Health Connect — prefer a physical device.

## App ID (Package Name)
- Current applicationId: `dev.ognjen.sunday`
- To change: edit `android/gradle.properties` → `APPLICATION_ID=your.package.id`, then Run.

## Widgets
- After first run, long-press home screen → Widgets → add “Sun Day”.
- Widget values update when the app is active.

## CLI (optional)
- `make get` — flutter pub get
- `make analyze` — static analysis
- `make fmt` — format Dart code
- `make run DEVICE=<device_id>` — run on a specific device
- `make apk` — debug APK build

## Troubleshooting
- Health Connect missing: install/update it, then retry Health actions.
- No UV data: ensure network is available; set emulator location (… → Location).
- Build issues: run `flutter clean`, then `flutter pub get`, then Run again.

