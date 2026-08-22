# Safe Campus — Heatwave slice

Flutter prototype for the hackathon Safe Campus app.

## Your flow
1. Mode select → **Student mode**
2. Student login (demo: any ID + password)
3. Student home → **Heatwave** icon
4. Heatwave map scans Bluetooth / WiFi and shares zone crowd density

Admin mode and other feature icons are placeholders for teammates.

## Run
```bash
flutter pub get
flutter run
```

Use a physical Android/iOS device for real Bluetooth and WiFi scanning.

## Required keys (for full demo)
- **Maps**: none for now (OpenStreetMap via `flutter_map`)
- **Firebase** (shared heatwave across phones): `flutterfire configure`, then set `isConfigured = true` in `lib/app/firebase_options.dart`

## Merge guide
| Piece | Location |
|-------|----------|
| Student login | `lib/features/auth/` |
| Student home icons | `lib/features/home/student_home_page.dart` |
| Heatwave feature | `lib/features/heatwave/` |
| Admin placeholder | `lib/features/admin/` |
| Zone coordinates | `lib/shared/location/zone_service.dart` |
| Map abstraction | `lib/shared/map/campus_map_controller.dart` |

Add new student features as new tiles next to Heatwave on the home grid.
