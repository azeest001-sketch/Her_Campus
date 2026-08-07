# Her Campus

Shared Flutter project for the team.

## Important files

- `lib/main.dart` - app starting point
- `pubspec.yaml` - Flutter project + dependencies
- `map/` - shared OpenFreeMap kit (Liberty + 3D)

## Folder structure (placeholders for each teammate)

```
lib/
  main.dart
  screens/     splash, home, map, sos, escort, admin, report
  widgets/     sos_widget, escort_card, heat_map_overlay, transit_card
  models/      user, report, escort, crowd_data
  services/    supabase, location, barometer, bluetooth_wifi, sos
  providers/   auth, location, sos, escort
  theme/       app_theme
map/           shared map module (Liberty style + 3D)
```

Files are empty stubs marked TODO - fill in only YOUR assigned part.

## Run the app

```
flutter pub get
flutter run
```

Map demo (optional):

```
cd map
flutter pub get
flutter run
```

## How to work (GitHub)

1. `git pull origin main`
2. `git checkout -b yourname/your-part`
3. Edit only YOUR files
4. Commit, push, open a Pull Request into `main`

Copy `.env.example` to `.env` locally - never commit `.env`.