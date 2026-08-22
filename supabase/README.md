# Supabase setup (safety features)

1. Open Supabase → **SQL Editor**
2. Paste and run [`schema_safety_features.sql`](schema_safety_features.sql)
3. Auth → Providers → Email → turn **Confirm email** OFF for demos (avoids rate limits)
4. Rebuild the app APK after `.env` is filled

Tables created: `profiles`, `trusted_circle`, `buddy_requests`, `buddy_notifications`, `escort_volunteers`, `escort_requests`
