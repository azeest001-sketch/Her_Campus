# Heatwave feature

Student-mode crowd density map for Safe Campus.

## What this does
- Scans nearby **Bluetooth LE** devices (Android + iOS)
- Scans nearby **WiFi / hotspot APs** (Android; iOS shows N/A)
- Shows **approx people / BT / WiFi counts** clearly
- Draws **hotspots only where crowd was detected** on a blank area (no map tiles)

## Entry points for merge
- Student home icon → `HeatwaveScreen` (`lib/features/heatwave/heatwave_screen.dart`)
- Route: `/heatwave` in `lib/app/routes.dart`
- Zone list: `ZoneService.demoZones` in `lib/shared/location/zone_service.dart`
  - Replace centers / IDs with your custom campus map zones

## Setup for shared multi-phone map
1. Create a Firebase project
2. Run:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
3. Set `DefaultFirebaseOptions.isConfigured = true` in `lib/app/firebase_options.dart`
4. Firestore collection: `crowd_zones/{zoneId}`

Without Firebase the app still runs in **local sync mode** (same phone only).

## Google Maps API key
Not required. The temporary map uses **OpenStreetMap** via `flutter_map` (no API key).
Your teammate can later replace it with a custom campus map.

## Permissions
Grant location + Bluetooth (+ nearby WiFi on Android) when prompted.
Use a **physical phone** — emulators are weak for BLE/WiFi demos.
