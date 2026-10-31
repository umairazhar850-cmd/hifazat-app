# HIFAZAT — lib/ changes

Drop-in replacement for your `lib/` folder. **No new pub packages were added**, so `pubspec.yaml` does not need to change. Everything below builds on what you already had: `cloud_firestore`, `firebase_auth`, `firebase_core`, `firebase_messaging`, `fl_chart`, `pdf`, `printing`, `shared_preferences`.

---

## 1. Things you MUST do after dropping this in

### a) Create your admin account manually

The register screen **no longer offers "Admin"** as a signup option. Previously anyone could tick Admin during signup and immediately get the vendor verification queue, everyone's data, and the alert broadcast tool. That's a real hole — a self-declared admin could approve their own shop and push fake safety alerts to every user.

To make yourself an admin:
1. Register normally as a Consumer.
2. Firebase Console → Firestore → `users` → your uid.
3. Change `role` from `"consumer"` to `"admin"`.
4. Restart the app. The Admin Dashboard tile appears on Home.

### b) Firestore indexes

Two collectionGroup queries need indexes. Firestore prints a **one-click creation link in your debug console** the first time each runs — just click it.

- `tests` collectionGroup (already needed for Insights)
- `tests` collectionGroup filtered by `vendorId` (new — vendor dashboard)

### c) Security rules

The UI role checks are convenience, not security — anyone can decompile an APK and hit Firestore directly. Paste this into Firestore Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() { return request.auth != null; }
    function myRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    function isAdmin() { return isSignedIn() && myRole() == 'admin'; }

    match /users/{uid} {
      allow read: if isSignedIn() && (request.auth.uid == uid || isAdmin());
      // A user creates/updates their OWN profile, but can never write
      // role: 'admin' to it themselves.
      allow create: if request.auth.uid == uid
                    && request.resource.data.role in ['consumer', 'vendor'];
      allow update: if (request.auth.uid == uid
                        && request.resource.data.role in ['consumer', 'vendor'])
                    || isAdmin();
      // The `isAdmin()` branch is what makes the in-app "Manage Users" screen
      // work: an EXISTING admin can promote/demote any other user's role,
      // including granting a new admin. A non-admin can never reach this
      // branch, so the very first admin still has to be seeded manually in
      // the Firebase console — everyone after that can be promoted from
      // inside the app.

      match /tests/{testId} {
        allow read: if request.auth.uid == uid || isAdmin();
        allow create: if request.auth.uid == uid;
        allow update, delete: if false;   // history is append-only
      }
    }

    match /vendors/{vendorId} {
      allow read: if isSignedIn();
      // A vendor edits their own business details, but can NEVER set their own
      // verificationStatus — only an admin can.
      allow create: if request.auth.uid == vendorId
                    && request.resource.data.verificationStatus == 'pending';
      allow update: if isAdmin()
                    || (request.auth.uid == vendorId
                        && request.resource.data.verificationStatus == resource.data.verificationStatus);
    }

    match /alerts/{alertId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }
  }
}
```

> Note: the `vendors` update rule intentionally allows any signed-in user to increment `totalTests`/`safeTests` via the trust-score batch write. That is loose. The correct fix is to move that increment into a Cloud Function so clients can't touch the counters at all. Worth mentioning in your defense as a known hardening step rather than pretending it's solved.

---

## 2. What changed

### The 80% confidence rule — now actually enforced

Your scope document says a result below 80% confidence must not be shown as a verdict. The old code showed the verdict anyway with a small warning banner underneath. A user who sees a big green **SAFE** badge does not read the small print.

Now:
- `TestResultModel.severity` = what the model guessed.
- `TestResultModel.verdict` = what we're allowed to display (a new `DisplayVerdict` enum, including `inconclusive`).
- **Every screen renders `verdict`, never `severity`.** Result screen, history list, chatbot greeting, vendor dashboard.
- Below 80%: no verdict, no contaminant name, no purity number. Just INCONCLUSIVE + a re-test button + the Sensor Flush reminder.
- Inconclusive tests are **excluded** from community stats and vendor trust scores. A reading the model didn't trust is missing information, not a data point.

This is the one change most likely to come up in your defense, so it's worth being able to explain the `severity` vs `verdict` split.

### Milk purity percentage

- `purityPercent` (0–100) added to `TestResultModel`, milk only. Null for water — a "purity %" for water isn't a meaningful quantity and inventing one would be dishonest.
- New `PurityGauge` widget on the result screen: big number, pure/impure split bar, plain-language reading ("Slightly adulterated").
- Shown in history list, vendor dashboard, Insights (average milk purity), and the PDF export.
- `TestResultModel.dummy()` now generates a purity consistent with the severity, and a **varying confidence** so the INCONCLUSIVE path is actually reachable in a demo instead of being dead code you can't show an examiner.

### All six sensors, for both samples

`SensorConfig` previously showed 4 sensors for water and 5 for milk. Your scope doc says all six run for both — what changes is what each reading *means*. Now every sensor is shown for both, with a per-sample-type meaning line under it (pH → "souring/spoilage" for milk, "acidity/alkalinity imbalance" for water, etc.). An examiner reading the scope doc and then opening the app would have noticed the old mismatch.

### Vendor role (new)

- `VendorModel` — business details, `verificationStatus` (pending/verified/rejected), `totalTests`/`safeTests` counters.
- **Vendor registration screen** — business name, type, address, city, CNIC/registration number. Always submits as `pending`; a vendor cannot self-verify.
- **Vendor dashboard** — verification status banner, public trust score, and the consumer tests tagged to their shop (read-only — they can't edit or delete them, which is what makes the score worth anything).
- **Vendor lookup** (consumer-facing) — searchable list of **verified vendors only**, sorted by trust score.
- **Vendor tagging during a test** — optional, defaulted off, on the device-connect screen. Deliberately opt-in: most tests are someone checking their own tap water, and auto-attributing those to a nearby shop would poison the trust scores.
- **Trust score** = `safeTests / totalTests`, but shows *"Not enough data yet"* below 5 tests. A "100% safe" badge earned from one test is worse than no badge.

### Admin role (new)

- **Admin dashboard** — live stats (total tests, unsafe rate, inconclusive rate), vendor queue badge, links to broadcast/insights/map.
- **Vendor verification queue** — approve/reject with a reason the vendor actually sees.
- **Broadcast area alert** — publishes an alert doc; every user's home screen shows it above everything else.
- **Manage users** (new) — lets an existing admin promote/demote any user's role (Consumer / Vendor / Admin) from inside the app, with a confirmation dialog before granting admin. This is the ONLY way to create a second admin — the security rule only allows the `admin` role to be written by someone who is already an admin, so the very first admin account still has to be seeded manually in the Firebase console (see section 1a). Every promotion after that can happen entirely in-app.

### Other

- **Help screen** (Home top-right + Settings) — the Sensor Flush protocol, why "Inconclusive" happens, water vs milk testing tips, why internet is required.
- **Home screen** is role-aware: Consumer → "Verified Vendors" tile; Vendor → "My Business"; Admin → "Admin Dashboard". Plus an alerts banner at the top.
- **PostLoginRouter** — a vendor who signed up but never filled in business details used to land on a home screen that couldn't help them. They now go straight to vendor registration.
- Stale "food and water" copy fixed to "water and milk".

### Placeholder text and validation (this round)

- Every form field now uses standard, generic placeholder text instead of an example that could read as pre-filled real data — "Enter your full name" instead of "Umair Khan", "Enter your email address" instead of "you@example.com", etc. Applied across Register, Login, Forgot Password, Edit Profile, and Vendor Registration.
- **Register now has a real password policy**: 8+ characters, at least one uppercase letter, one lowercase letter, one number — plus a **Confirm Password** field that has to match. Login intentionally keeps the old, lenient check (6+ characters) so accounts created before this rule can still sign in; tightening that retroactively would lock existing users out.
- Full name / business name fields reject empty input, single characters, and digits-only strings ("12345" is not a name).
- Vendor registration number field now requires at least 5 digits rather than accepting anything non-empty, while staying loose enough to accept both CNIC and other business registration formats — an admin verifies it manually anyway.

### Flaws fixed this round

1. **Edit Profile still had a working "Admin" role chip.** This is the same self-promotion hole that was removed from the Register screen — but it was still live here. Any signed-in user could tap Admin and hit Save. The Firestore security rule would have rejected the actual write, but showing a button that always silently fails is its own bug. Fixed: the Admin option is gone from the picker; if the signed-in user IS an admin, the role section becomes a read-only notice pointing them to Admin Dashboard → Manage Users instead.
2. **Broadcasting an area alert had no confirmation step.** One mistap sent a real (fake) safety warning to every user immediately. Vendor promotion already asks "are you sure?" for a much smaller action; broadcasting to the entire user base now does too, showing exactly what will be sent before it goes out.
3. **Nothing stopped demoting the last remaining admin.** Doing that would lock the whole app out of every admin function, with no way back in except editing Firestore by hand again — defeating the point of the in-app promotion screen. `Manage Users` now checks the current admin count first and blocks the change with an explanation if the target is the only admin left.
4. **`AuthService.friendlyError` was missing several common Firebase error codes** (`too-many-requests`, `user-disabled`, `requires-recent-login`, `operation-not-allowed`, `user-token-expired`) — these previously fell through to Firebase's raw internal error string, which isn't something a user can act on. All five now have a plain-language message.

---

## 3. Still TODO (deliberately not faked)

| Item | Why it's not done |
|---|---|
| **Real ESP32 data** | Still `TestResultModel.dummy()`. Needs `device_service.dart` + your real endpoint. |
| **Real ML inference** | Still dummy. Needs `ml_api_service.dart` calling your cloud model. |
| **Google Maps hotspot map** | Still the placeholder shell — needs `google_maps_flutter` + an API key in `AndroidManifest.xml`. That's outside `lib/`, so I didn't add a package you'd have to configure. |
| **Vendor document photo upload** | Needs `firebase_storage` + `image_picker`. Currently collects a registration *number* as text, and the UI says so honestly rather than pretending. |
| **Push notifications for alerts** | The alert document is written to Firestore and the app reads it. Turning it into an actual push needs a Cloud Function on the `alerts` collection calling FCM — backend work, not app work. |
| **GPS coordinates on tests** | `latitude`/`longitude` exist on the model but nothing populates them (needs `geolocator`). The hotspot map depends on this. |

---

## 4. Files added

```
core/constants/app_constants.dart          80% threshold, min tests for trust score
core/services/post_login_router.dart       role-aware landing route
core/widgets/purity_gauge.dart             milk purity visual
models/vendor_model.dart
models/alert_model.dart
models/test_flow_args.dart                 carries the optional vendor tag through the test flow
features/vendor/screens/vendor_registration_screen.dart
features/vendor/screens/vendor_dashboard_screen.dart
features/vendor/screens/vendor_lookup_screen.dart
features/admin/screens/admin_dashboard_screen.dart
features/admin/screens/vendor_verification_screen.dart
features/admin/screens/broadcast_alert_screen.dart
features/admin/screens/user_management_screen.dart
features/help/screens/help_screen.dart
```

## 5. Files modified

`main.dart` untouched. Modified: `models/test_result_model.dart`, `models/community_stats_model.dart`, `core/utils/sensor_config.dart`, `core/services/firestore_service.dart`, `core/routes/app_routes.dart`, `core/routes/route_generator.dart`, `core/widgets/severity_badge.dart`, `core/localization/app_strings.dart`, `features/auth/screens/register_screen.dart`, `features/auth/screens/verify_email_screen.dart`, `features/splash/screens/splash_screen.dart`, `features/home/screens/home_screen.dart`, `features/testing/screens/device_connect_screen.dart`, `features/testing/screens/testing_progress_screen.dart`, `features/testing/screens/result_screen.dart`, `features/history/screens/history_list_screen.dart`, `features/insights/screens/insights_screen.dart`, `features/settings/screens/settings_screen.dart`, `features/assistant/controllers/chatbot_controller.dart`, `features/assistant/screens/chat_screen.dart`.

---

**I could not run `flutter analyze` here** (no Dart SDK in this environment). I verified every relative import resolves and checked syntax balance across all 63 files, but run `flutter analyze` yourself first — if anything trips, it'll be a small fix, not a structural one.
