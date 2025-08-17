# Sun Day — iOS Quick Start

## Prerequisites
- macOS with Xcode 14+ installed (includes command-line tools)
- Flutter SDK
- CocoaPods (`sudo gem install cocoapods`) if not already installed

## Open the Project
- In Xcode, open the workspace: `sunday_flutter/ios/Runner.xcworkspace` (not the `.xcodeproj`).
- Alternatively, use Flutter CLI to build/run without opening Xcode.

## App Identity & Capabilities
- Bundle Identifier: `dev.ognjen.sunday` (already set)
- Signing: select your Apple ID team (Target: Runner → Signing & Capabilities → Team)
- Capabilities: HealthKit is enabled via `Runner.entitlements`
- Permissions (Info.plist):
  - `NSLocationWhenInUseUsageDescription` — location for UV and sunrise/sunset
  - `NSHealthShareUsageDescription` — read for personalization
  - `NSHealthUpdateUsageDescription` — write vitamin D estimates

## Run (Xcode)
1. Open `Runner.xcworkspace`
2. Select a real device (recommended for HealthKit) or a simulator
3. Set Signing Team on Runner target (and RunnerTests if needed)
4. Press Run (⌘R)

Note: HealthKit is not available on the iOS Simulator; use a physical device to test Health reads/writes.

## Run (CLI)
- `cd sunday_flutter`
- `flutter clean && flutter pub get`
- `flutter run -d <ios_device_id>`

## Troubleshooting
- Signing errors: ensure a Team is selected and the Bundle Identifier is unique within your account.
- CocoaPods issues: run `cd ios && pod repo update && pod install`, then reopen the workspace.
- Health prompts not appearing: ensure the app is installed on a physical device and HealthKit capability is present; uninstall/reinstall after capability changes.
- Location permission: if denied, enable in Settings → Privacy & Security → Location Services → Sun Day.

## Notes
- Display name is set to “Sun Day”.
- Minimum iOS version is 12.0 (as configured in the project).
- Home screen widgets are not configured for the Flutter app on iOS in this repo; Android widget is supported.

