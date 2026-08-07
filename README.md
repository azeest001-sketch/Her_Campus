# Her Campus

Shared Flutter project for the team.

## Important files

- `lib/main.dart` - app starting point (everyone runs from here)
- `pubspec.yaml` - Flutter project + dependencies

## Folders

| Folder | Purpose |
|--------|---------|
| `lib/screens/` | UI screens (login, map, sos, escort, ...) |
| `lib/widgets/` | Reusable UI pieces |
| `lib/models/` | Data models |
| `lib/services/` | Supabase, location, SOS, etc. |
| `lib/providers/` | Riverpod state |
| `lib/theme/` | App theme / colors |

## Run the app

``
flutter pub get
flutter run
``

## How to work (GitHub)

1. `git pull origin main`
2. `git checkout -b yourname/your-part`
3. Add only YOUR files
4. Commit, push, open a Pull Request into `main`

Copy `.env.example` to `.env` locally and fill secrets - never commit `.env`.