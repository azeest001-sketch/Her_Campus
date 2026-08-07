# Her Campus

Shared Flutter project folder layout for the team.

## Folders

| Folder | Who fills it |
|--------|----------------|
| `lib/screens/` | UI screens (splash, home, map, sos, escort, admin, report) |
| `lib/widgets/` | Reusable UI pieces |
| `lib/models/` | Data models |
| `lib/services/` | Supabase, location, SOS, etc. |
| `lib/providers/` | Riverpod state |
| `lib/theme/` | App theme / colors |

## How to work (GitHub)

1. `git pull origin main`
2. `git checkout -b yourname/your-part`
3. Add only YOUR files
4. Commit, push, open a Pull Request into `main`

Copy `.env.example` to `.env` locally and fill secrets — never commit `.env`.
