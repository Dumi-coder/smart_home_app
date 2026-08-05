# Smart Home App — Camera / Analysis / Notifications / Profile

## What's new
Replaced the 4 "Coming soon" placeholder tabs in `main_shell.dart` with full
screens, matching your Figma UI and reusing the existing theme, models, and
`FirestoreService` pattern from the Home screen.

### New files
- `lib/models/notification_alert.dart`
- `lib/models/house_member.dart`
- `lib/models/energy_reading.dart`
- `lib/widgets/notification_card.dart`
- `lib/widgets/energy_bar_chart.dart` (hand-painted, no new dependency)
- `lib/widgets/energy_donut_chart.dart` (hand-painted, no new dependency)
- `lib/widgets/preference_tile.dart`
- `lib/widgets/member_tile.dart`
- `lib/screens/camera_screen.dart`
- `lib/screens/analysis_screen.dart`
- `lib/screens/notifications_screen.dart`
- `lib/screens/profile_screen.dart`

### Modified files
- `lib/screens/main_shell.dart` — wired the 4 real screens in, removed the placeholder widget
- `lib/services/firestore_service.dart` — added alerts/energyUsage/houseMembers/scenes/preferences/camera-group methods
- `lib/services/seed_data.dart` — now also seeds exterior cameras, 5 realistic alerts, ~30 days of energy readings across 5 rooms, 3 house members, 4 scenes, and default preferences

## New Firestore collections
| Collection | Purpose |
|---|---|
| `floors/exterior/devices` | Exterior cameras (Entrance, Backyard, Driveway) — lives under a pseudo-floor with no floor doc, so it never shows as a Home-screen floor tab, only in the Camera tab's pill list |
| `alerts` | Extended with `title`, `severity` (critical/warning/info), `room`, `icon` — powers the Notifications screen |
| `energyUsage` | Daily kWh per room/device — powers the Analysis screen's charts and totals |
| `houseMembers` | Name, email, role, online status — Profile screen |
| `scenes` | Just used for the Profile screen's "Scenes" stat |
| `settings/preferences` | Dark Mode / Push Notifications / Firebase Sync toggle values |

## To run it
1. Drop this `lib/` folder into your project (overwrite the existing one).
2. `flutter pub get` (no new packages needed — everything here uses what you already have: `firebase_core`, `cloud_firestore`, `google_fonts`).
3. Re-seed your database so the new collections exist — tap the cloud-upload icon on the Floors screen (`SeedData.seedDatabase()`), or call it from wherever you trigger it today. **Note:** re-running seed adds a second Ground Floor and duplicate data since it always does `.add()` — clear your Firestore data first if you've already seeded once.
4. Copy `firestore.rules` into your Firebase project and deploy it (`firebase deploy --only firestore:rules`) — it's currently open read/write for development since there's no login flow yet.

## Known simplifications (given this is a university project, not a production IoT deployment)
- **Camera feed is a static demo image**, not a real RTSP/WebRTC stream — you confirmed this is fine for now. The LIVE/REC badges pulse to look alive; the PTZ dpad, zoom, mic, and snapshot buttons show a "demo — no physical camera connected" snackbar instead of doing anything real.
- **Dark Mode toggle is stored in Firestore but doesn't actually re-theme the app yet** — flipping it just persists the value. Wiring an actual dark `ThemeData` and reading this flag in `main.dart` is a follow-up if you want it.
- **No login/auth** — Profile always shows "Alex Morgan" as a static owner. House Members (add/list) and preferences are real and Firestore-backed, just not gated behind sign-in.
- **Analysis totals are computed client-side** from the `energyUsage` collection (today / week / month / room split / top consumers) rather than via a Cloud Function — fine at this data volume, but if this ever needs to scale you'd move the aggregation server-side.
