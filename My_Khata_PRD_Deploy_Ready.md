# My Khata — Complete Product Requirements Document
### (Deploy-Ready: Build → Test → Release to Google Play Store)

**Version:** 1.0 (MVP)
**Doc type:** Single-source PRD for AI coding agents (Cursor / Kiro Code / Claude Code)
**Last updated:** June 2026

---

## 0. How to Use This Document

This PRD is written to be pasted directly into an AI coding agent as a build prompt. It is organized so the agent can work top-to-bottom: app identity → architecture → data model → screens → security → release. Nothing here is "TBD" — every value an agent would normally have to guess (package name, colors, min SDK, security rules) is filled in.

If you want to hand this to an agent in one shot, copy everything from **Section 1** onward as your prompt.

---

## 1. App Identity

| Item | Value |
|---|---|
| App Name | My Khata |
| Tagline | Simple Money Tracking |
| Package Name (Application ID) | `com.mykhata.ask` |
| Category (Play Store) | Finance |
| Content Rating | Everyone |
| Primary Language | English (India) — `en-IN` |
| Secondary Language (v1.1+) | Bengali (`bn`), Hindi (`hi`) — structure for this now, ship later |
| Minimum Android Version | Android 8.0 (API 26) |
| Target/Compile SDK | API 35 (Android 15) — **mandatory minimum for new Play Store submissions in 2026; verify current requirement at submission time, Google updates this yearly** |
| App Bundle Format | `.aab` (Android App Bundle) — required by Play Store, not `.apk` |

> **Why this package name:** `com.mykhata.ask` is short, has no trademark collisions with existing "khata" apps on the Play Store (verify at submission time — "khata" is a common term in Indian fintech apps), and is namespaced under its own domain-style prefix so the app stands on its own brand identity (distinct from any other personal dev umbrella you may use for other apps, like Pay2Bee or MindEase).

---

## 2. Product Overview

My Khata is a lightweight personal ledger ("khata" = ledger/account book in Hindi/Bengali/Urdu) that helps users track money given to and received from customers, friends, or family. It focuses on speed: a transaction must be recordable in under 5 seconds.

**Out of scope for v1:** invoicing, GST, multi-currency, reports/analytics, PDF export, reminders. These are explicitly deferred to v2 (see Section 14) so the agent does not over-build.

**Target users:** small shop owners, freelancers, personal lenders, friends/family tracking shared money, small business owners — primarily in India (hence ₹ as the only currency symbol in v1, no currency picker).

---

## 3. Core Principles

1. Fast entry creation — under 5 seconds per transaction
2. Clean, modern Material 3 UI
3. Offline-first — full functionality without internet
4. Automatic cloud sync — zero user action required
5. Minimal learning curve — no onboarding tutorial needed; UI is self-explanatory

---

## 4. Technology Stack

| Layer | Choice | Notes |
|---|---|---|
| Frontend | Flutter (latest stable channel) | Pin exact version in `pubspec.yaml` at project start; do not float on `any` |
| Language | Dart (latest stable, null-safety enabled) | |
| Backend Auth | Firebase Authentication | Google Sign-In provider only |
| Database | Cloud Firestore | Native offline persistence |
| State Management | Riverpod (`flutter_riverpod` + `riverpod_generator`) | Use code-generation (`@riverpod`) over manual providers for less boilerplate |
| Local Storage | Firestore offline persistence (`Settings(persistenceEnabled: true)`) | No separate local DB (no Hive/SQLite) needed — Firestore cache covers it |
| Architecture | Clean Architecture (data / domain / presentation layers) | See Section 5 |
| Routing | `go_router` | Recommended for Flutter + deep-link readiness, even though v1 has no deep links |
| Platform | Android first (no iOS in v1) | |
| Crash/Analytics | Firebase Crashlytics + Firebase Analytics | Not in original PRD — **required** for any serious Play Store launch; lets you see crashes post-launch |
| App Icon Generator | `flutter_launcher_icons` package | Generates all density buckets from one 1024×1024 PNG |
| Splash Screen | `flutter_native_splash` package | Native splash (not a Flutter widget) avoids the white-flash-before-load problem |

---

## 5. Architecture (Clean Architecture, Flutter-specific)

```
lib/
├── main.dart
├── app.dart                          # MaterialApp.router, theme, providers root
├── core/
│   ├── constants/                    # colors, dimens, strings
│   ├── theme/                        # light_theme.dart, dark_theme.dart
│   ├── router/                       # go_router config + route guards
│   ├── utils/                        # currency formatter, date formatter
│   └── errors/                       # failure classes, exception mapping
├── features/
│   ├── auth/
│   │   ├── data/                     # FirebaseAuth wrapper, repository impl
│   │   ├── domain/                   # entities, repository interface, use cases
│   │   └── presentation/             # screens, widgets, riverpod providers
│   ├── customers/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── transactions/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── shared/
    └── widgets/                      # buttons, cards, bottom sheets reused across features
```

**Rule for the agent:** domain layer has zero Flutter/Firebase imports (pure Dart). Data layer implements domain repository interfaces using Firestore. Presentation layer only talks to domain via use cases/providers — never imports Firestore directly.

---

## 6. App Flow

```
Splash Screen
   │ (check auth state)
   ▼
┌─────────────┐         ┌─────────────┐
│ Login Screen │ ──────▶ │ Home Screen │
└─────────────┘  success └─────────────┘
                              │ tap customer
                              ▼
                    ┌──────────────────┐
                    │ Customer Details │
                    └──────────────────┘
                              │ tap "I Gave" / "I Got"
                              ▼
                    ┌────────────────────────┐
                    │ Add Transaction Sheet  │
                    └────────────────────────┘

Settings ◀── accessible from Home App Bar (top-right icon)
```

---

## 7. Authentication

**Method:** Google Sign-In only, via Firebase Authentication.

**Explicitly excluded from v1:** email/password, phone OTP, Apple Sign-In, anonymous auth.

**Required user data captured at first login:**
- `uid` (Firebase Auth UID — primary key for all user data)
- `displayName`
- `email`
- `photoUrl`

**Implementation notes for the agent:**
- Use `google_sign_in` + `firebase_auth` packages together.
- On Android, you must generate a SHA-1 (debug) and SHA-1 (release) fingerprint and register both in the Firebase Console under Project Settings → Your Android App, or Google Sign-In will fail silently in release builds. **This is the #1 cause of "Google Sign-In works in debug but not in the signed release APK/AAB" bugs.**
- Handle the case where the user cancels the Google account picker (don't show an error toast for user-initiated cancellation — only show errors for actual failures).
- On sign-out, also call `googleSignIn.signOut()` in addition to `firebaseAuth.signOut()`, or the account picker will auto-select the same account on next login attempt.

---

## 8. Screen Specifications

### 8.1 Splash Screen

- Purpose: initialize Firebase, check `FirebaseAuth.instance.authStateChanges()`.
- UI: My Khata logo, tagline "Simple Money Tracking" below it.
- Implemented via `flutter_native_splash` for the native (pre-Flutter-engine) splash, with a thin Flutter-side splash route for the auth check itself if initialization takes longer than ~500ms.
- Routing: → Login if unauthenticated; → Home if authenticated.

### 8.2 Login Screen

- UI: App logo, "My Khata", subtext "Track Every Rupee".
- Single button: **Continue with Google** (Material 3 `FilledButton` with Google "G" logo icon — use the official Google branding guidelines asset, not a generic icon).
- On success → Home. On failure → inline error text below the button (no dialog interruptions).

### 8.3 Home Screen

**App Bar:**
- Title: "My Khata"
- Actions: Search icon, Settings icon (in that order, right-aligned)

**Summary Cards (horizontal row or grid, 3 cards):**

| Card | Value Source |
|---|---|
| Total Receivable | Sum of all customers where balance > 0 |
| Total Payable | Sum of absolute value of all customers where balance < 0 |
| Net Balance | Total Receivable − Total Payable |

**Customer List:**
- Sorted by most recently active by default (most recent transaction timestamp, descending).
- Each row shows: customer name, balance (colored green if positive/owed-to-you, red if negative/you-owe, gray "Settled" if zero).
- Swipe-to-delete or long-press → delete (with confirmation dialog — see 8.7).
- Tap row → Customer Details screen.

**FAB:** "+ Add Customer", bottom-right, standard Material 3 FAB.

**Search:** Tapping search icon expands an inline search bar in the app bar (not a separate screen) that filters the customer list by name as you type — no separate "search results" screen needed for this scale of data.

**Empty state (zero customers):** Centered illustration/icon + text "No customers yet. Tap + to add your first one." — **this was missing from the original PRD and matters a lot for first-run UX.**

### 8.4 Add Customer Screen (Modal Bottom Sheet, not full screen)

- Fields: Customer Name (required, max 50 chars), Phone Number (optional, with basic 10-digit Indian mobile format validation if entered), Notes (optional, max 200 chars).
- Validation: name cannot be empty or whitespace-only; show inline error, don't block typing.
- Button: **Save Customer** — disabled until name field is non-empty.
- After save: bottom sheet dismisses, returns to Home, new customer appears in list (optimistic UI — don't wait for Firestore round-trip if offline-persistence is on).

### 8.5 Customer Details Screen

**Header (sticky/pinned at top):**
- Customer name (large title)
- Current balance, large and colored:
  - Positive: "+₹700 — Customer should give you"
  - Negative: "−₹500 — You should give customer" (note: original PRD's wording is correct and should be preserved verbatim — it's clearer than generic "owes/owed" language for the target audience)
  - Zero: "₹0 — Settled" (gray)

**Transaction List (newest first):**
Each row: amount (colored), type label ("I Gave" / "I Got"), date, time, optional note shown as a smaller secondary line.

**Bottom action bar (always visible, not scrolling away):**
- Two large buttons side by side: **I Gave** (opens Add Transaction sheet, type=gave) | **I Got** (type=got)

**Empty state (zero transactions for this customer):** "No transactions yet. Record your first one below."

### 8.6 Add Transaction Bottom Sheet

- Triggered by "I Gave" or "I Got" — title of the sheet reflects which ("Add: I Gave ₹___" etc.)
- Fields: Amount (required, numeric keyboard, must be > 0), Note (optional, max 150 chars).
- Timestamp, date, time: captured automatically as `DateTime.now()` at save — **no date picker in v1**, per original spec. This is a deliberate simplicity choice; don't let the agent "improve" this by adding a date picker.
- Buttons: **Save**, **Cancel**.
- On save: customer's `balance` field updates atomically (see Section 10 for the exact transaction logic — must use a Firestore transaction, not a read-then-write, to avoid race conditions on rapid double-taps).

### 8.7 Transaction Management

- Long-press a transaction row → bottom sheet/menu with **Edit** and **Delete** options.
- **Edit:** reopens the Add Transaction sheet pre-filled with existing values; saving recalculates balance as `(old balance) − (old transaction's signed amount) + (new transaction's signed amount)`.
- **Delete:** confirmation dialog — "Delete this transaction? This action cannot be undone." with **Delete** (destructive/red) and **Cancel** buttons. On confirm, balance recalculates by reversing that transaction's effect.

### 8.8 Settings Screen

| Section | Contents |
|---|---|
| Appearance | Light / Dark / System Default (radio selection, persisted in Firestore under `profile.themePreference` so it syncs across devices, not just local `SharedPreferences`) |
| Account | Profile photo, name, email (read-only, pulled from Google account) |
| Data | Cloud Sync Status ("Connected" / "Offline — will sync when online"), Last Sync Time |
| About | App Version (read from `package_info_plus`, don't hardcode), Privacy Policy (link), Terms of Service (link) |
| — | **Logout** button at the bottom, visually separated, with confirmation dialog |

> **Play Store requirement, not in original PRD:** You must have a real, hosted **Privacy Policy URL** before you can publish. Since this app collects personal data (Google profile, financial ledger data) via Firebase, this is mandatory, not optional. See Section 12.3 for what it must cover and where to host it for free.

---

## 9. Firestore Database Structure

```
users (collection)
 └── {uid} (document)
      ├── profile: {
      │     name: string,
      │     email: string,
      │     photoUrl: string,
      │     themePreference: "light" | "dark" | "system",
      │     createdAt: timestamp
      │   }
      │
      └── customers (subcollection)
           └── {customerId} (document)
                ├── name: string
                ├── phone: string | null
                ├── notes: string | null
                ├── balance: number          // in paise (integer) — see note below
                ├── createdAt: timestamp
                ├── updatedAt: timestamp      // for "most recently active" sort
                │
                └── transactions (subcollection)
                     └── {transactionId} (document)
                          ├── type: "gave" | "got"
                          ├── amount: number  // in paise (integer)
                          ├── note: string | null
                          └── createdAt: timestamp
```

> **Critical correction to the original PRD:** store all monetary amounts as **integers in paise**, not as floating-point rupees. `balance: 700.0` will eventually produce floating-point rounding errors (₹700.00000001) after enough additions/subtractions. Store `balance: 70000` (paise) and divide by 100 only at the UI display layer. This is the same paise-based-integer pattern you've used in Pay2Bee for INR amounts — apply it here too for consistency and correctness.

---

## 10. Balance Calculation Logic

**Formula:** `balance = Σ(gave amounts) − Σ(got amounts)`

- Positive balance → customer owes the user.
- Negative balance → user owes the customer.
- Zero → settled.

**Implementation requirement (not in original PRD, but necessary):** balance must NOT be recalculated client-side by summing all transactions on every read — that doesn't scale and risks drift. Instead:
- Maintain `balance` as a denormalized field on the customer document.
- Every write (new transaction, edit, delete) updates `balance` **inside a Firestore transaction** (`runTransaction`) that reads the current balance, applies the delta, and writes both the transaction document and updated customer balance atomically.
- This guarantees correctness even with rapid taps or (eventually) multi-device concurrent edits.

**Example:**
```
I Gave ₹1000, I Got ₹300 → balance = 700  (customer owes user ₹700)
I Gave ₹100,  I Got ₹500 → balance = -400 (user owes customer ₹400)
```

---

## 11. Offline Support

**Requirement:** Firestore offline persistence enabled (`Settings(persistenceEnabled: true)` — this is actually the default on mobile, but set it explicitly for clarity).

**User can, while offline:**
- Add a customer
- Add a transaction
- Edit a transaction
- Delete a transaction
- View all previously-synced data

**On reconnect:** automatic sync, no user action. The "Cloud Sync Status" indicator in Settings should reflect this in real time using `FirebaseFirestore.instance.snapshotsInSync()` or connectivity listeners — don't fake it with a static "Connected" label.

**Edge case to handle (not in original PRD):** what happens if the same customer is edited offline on two devices before either syncs? Firestore's default last-write-wins resolves this automatically — acceptable for v1, but document this as a known limitation rather than silently ignoring it.

---

## 12. Security & Compliance

### 12.1 Firestore Security Rules

Replace the vague "each user can only access their own data" with the actual rules file the agent should deploy:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read, update, delete: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;

      match /customers/{customerId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;

        match /transactions/{transactionId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }

    // Deny everything else by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

- Authentication required for all reads/writes — anonymous/unauthenticated access is denied everywhere.
- Users cannot read or write another user's `customers` or `transactions` subcollections, enforced server-side (not just hidden in the UI).
- **Recommended addition:** validate field types and required fields server-side too (e.g. `request.resource.data.amount is number && request.resource.data.amount > 0`) so a compromised/modified client can't write garbage data. Worth adding before launch, even for a personal-finance-adjacent app.

### 12.2 Play Store Data Safety Form

Google requires every app to disclose what data it collects via the **Data Safety** section in Play Console. For My Khata, based on this spec, you will need to declare:

| Data Type | Collected? | Shared with third parties? | Purpose |
|---|---|---|---|
| Name | Yes | No | Account management |
| Email address | Yes | No | Account management |
| User profile photo | Yes | No | App functionality |
| Financial info (ledger amounts, customer names you enter) | Yes | No | App functionality |
| Encrypted in transit | Yes (Firebase uses TLS) | — | — |
| User can request data deletion | Yes (must implement — see 12.4) | — | — |

You fill this in during Play Console submission, not in code — but the agent should be aware these categories exist so the app's actual behavior matches what you'll declare (e.g., don't silently add a third-party analytics SDK that shares data, or your declaration becomes false).

### 12.3 Privacy Policy (mandatory before submission)

Must be a publicly accessible URL (not a PDF in your repo). Free hosting options:
- A GitHub Pages page (free, simple, fits your existing GitHub workflow)
- A single static HTML page hosted via Firebase Hosting (you already have a Firebase project for this app — zero extra setup)

Minimum content required by Google: what data is collected (name, email, photo, ledger entries), how it's used, that it's stored via Firebase/Google Cloud, that users can request deletion, and a contact email.

### 12.4 Account/Data Deletion (mandatory, not in original PRD)

Since May 2022, Google Play requires apps that support account creation to also provide **in-app account and data deletion**, not just a logout. Add to Settings:
- "Delete My Account" option (separate from Logout) that deletes the user's Firestore document tree (`users/{uid}` and all subcollections) and the Firebase Auth account, with a confirmation step ("This permanently deletes all your customers and transactions. This cannot be undone.").
- Use a callable Cloud Function or batched client-side recursive delete for subcollections, since Firestore doesn't cascade-delete subcollections automatically when you delete a parent document.

---

## 13. Design System

| Property | Value |
|---|---|
| Design language | Material 3 (Material You) |
| Theme | Modern, minimal |
| Corner radius | 16px on cards, buttons, bottom sheets |
| Animations | Subtle — use Material 3 default transitions, no custom flashy animations |
| Typography | Material 3 type scale (e.g. `Roboto` or `Noto Sans` for better Bengali/Hindi glyph support later, given your localization plans) |
| Dark mode | Fully supported, including correct contrast for the green/red balance colors (don't use pure `Colors.red`/`Colors.green` — pick Material-3-compliant tones that pass contrast in both themes) |
| Color seed | Suggest a seed color of a deep teal or indigo (`ColorScheme.fromSeed(seedColor: ...)`) — fits "fintech-adjacent but personal/friendly" branding, distinct from your Pay2Bee yellow/black so the two apps don't look like the same product family |

---

## 14. Explicitly Out of Scope for v1 (Future v2)

Do not build these now — listing them so the agent doesn't scope-creep:
- PDF export of ledger/statements
- WhatsApp sharing of balance/statement
- Payment reminders / notifications
- Customer-facing statements (shareable read-only view)
- Multiple ledger "books"/accounts per user
- Data export (CSV)
- Monthly/periodic reports
- Categories/tags on transactions
- Home screen widgets
- Multi-currency support
- iOS build

---

## 15. MVP Success Criteria (Definition of Done)

The build is complete when a user can:

- [ ] Log in with Google
- [ ] Create a customer
- [ ] Add a transaction (both "I Gave" and "I Got")
- [ ] View correct, auto-calculated balance at customer and home-summary level
- [ ] Edit a transaction and see balance recalculate correctly
- [ ] Delete a transaction and see balance recalculate correctly
- [ ] Delete a customer
- [ ] Use the app fully offline, then watch it sync automatically on reconnect
- [ ] Switch between Light / Dark / System theme
- [ ] Log out
- [ ] Delete their account and all associated data from within the app
- [ ] App has zero crashes in a 15-minute manual smoke test covering every screen

---

## 16. Pre-Submission Release Checklist (Play Store)

This is the section most "vibe-coded" apps skip, and it's where most first-time submissions stall. Work through it in order.

### 16.1 Firebase Project Setup
- [ ] Create production Firebase project (separate from any dev/test project)
- [ ] Enable Google Sign-In provider in Firebase Authentication
- [ ] Add Android app to Firebase project with package name `com.mykhata.ask`
- [ ] Generate and register **debug** SHA-1 (`./gradlew signingReport`)
- [ ] Generate and register **release** SHA-1 (from your release keystore — see 16.2)
- [ ] Download `google-services.json`, place in `android/app/`
- [ ] Deploy the Firestore security rules from Section 12.1 (`firebase deploy --only firestore:rules`)
- [ ] Set Firestore production mode (not test mode) before launch

### 16.2 App Signing
- [ ] Generate a release keystore: `keytool -genkey -v -keystore my-khata-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mykhata`
- [ ] **Back up this keystore file and its passwords somewhere durable and offline.** If lost, you cannot update this app on the Play Store ever again under the same listing — you'd have to publish as a new app and lose all reviews/installs/ranking.
- [ ] Configure `android/key.properties` and reference it in `android/app/build.gradle` signing config (never commit `key.properties` or the `.jks` file to git — add both to `.gitignore`)
- [ ] Enroll in **Play App Signing** during first upload (Google-recommended; Google re-signs your app with an additional key, protecting you if your upload key is ever compromised)

### 16.3 Build Configuration
- [ ] Set `applicationId "com.mykhata.ask"` in `android/app/build.gradle`
- [ ] Set `minSdkVersion 26`, `targetSdkVersion`/`compileSdkVersion` to current Play Store requirement (verify at submission time — was API 35 as of late 2025/2026 cycle)
- [ ] Set `versionCode 1` and `versionName "1.0.0"`
- [ ] Enable code shrinking: `minifyEnabled true`, `shrinkResources true` in release build type
- [ ] Run `flutter build appbundle --release` (not `--release` apk — Play Store requires `.aab`)
- [ ] Test the actual signed release bundle (not just debug build) on a physical device before upload — Google Sign-In bugs in particular only surface in release builds (see Section 7)

### 16.4 App Icon & Branding Assets
- [ ] Design a 1024×1024px PNG app icon (no transparency, no rounded corners — Play Store/Android applies the mask)
- [ ] Run `flutter_launcher_icons` to generate all density buckets
- [ ] Configure adaptive icon (foreground + background layers) for Android 8.0+ — required since your `minSdkVersion` is 26
- [ ] Create a feature graphic: 1024×500px PNG/JPG (required for Play Store listing page)
- [ ] Capture phone screenshots: minimum 2, recommended 4–8, from an actual device or emulator at standard resolutions (Play Console will tell you accepted dimensions)

### 16.5 Play Console Listing
- [ ] Create app in Play Console, select "App" + "Free" (or paid, if monetizing later)
- [ ] App name: "My Khata"
- [ ] Short description (≤80 chars): "Track money you give and receive with a simple digital ledger."
- [ ] Full description (≤4000 chars): expand on the original PRD's full description — see Section 17 for ready-to-paste copy
- [ ] Category: Finance
- [ ] Content rating questionnaire: complete honestly (this app has no UGC, ads, or violence — should land as "Everyone")
- [ ] Target audience: select "18 and over" given financial data handling, even though content itself is rated Everyone — **decide this deliberately, don't default it**
- [ ] Data Safety form: fill in using Section 12.2 above
- [ ] Privacy Policy URL: fill in using Section 12.3 above
- [ ] Ads declaration: "No, this app does not contain ads" (true for v1)

### 16.6 Testing Track
- [ ] Upload first build to **Internal Testing** track, not directly to Production
- [ ] Add yourself (and ideally 2–3 friends/family who'd actually use a khata app) as internal testers
- [ ] Run through every item in Section 15's Definition of Done on the actual signed build
- [ ] Only promote to Production after internal testing passes cleanly

### 16.7 Post-Launch
- [ ] Confirm Firebase Crashlytics is receiving data from the production build
- [ ] Set up a Play Console alert/email for crash rate spikes
- [ ] Monitor Firestore usage in Firebase Console against the free Spark plan quotas (50K reads/day, 20K writes/day) — a personal ledger app should comfortably stay within free tier unless you get real scale, but worth knowing where the ceiling is

---

## 17. Ready-to-Paste Play Store Listing Copy

**App Name:**
My Khata

**Short Description (80 char limit):**
Track money you give and receive with a simple digital ledger.

**Full Description:**
```
My Khata is a simple, secure ledger app that helps you track money given to
and received from customers, friends, and family — without complicated
accounting features.

Add a customer, log what you gave or got, and instantly see who owes you
and who you owe. No invoices. No GST. No clutter. Just your khata, digitized.

KEY FEATURES
• Sign in securely with your Google account
• Add unlimited customers and track each one's running balance
• Record "I Gave" and "I Got" transactions in seconds
• Automatic balance calculation — no manual math
• Full offline support — works without internet, syncs automatically when
  you're back online
• Clean, modern design with Light and Dark mode
• Your data is private and synced securely to your Google account

WHO IT'S FOR
• Small shop owners tracking customer credit
• Freelancers tracking client payments
• Anyone lending or borrowing money with friends and family
• Small business owners who want a simple alternative to a paper khata

Your data, your account, always in sync — across every device you use.
```

---

## 18. Build Prompt Summary (for the AI Agent)

> Build "My Khata," a Flutter (latest stable) Android app using Clean Architecture and Riverpod for state management, with Firebase Authentication (Google Sign-In only) and Cloud Firestore (offline persistence enabled) as the backend. Package name: `com.mykhata.ask`, minSdkVersion 26. Follow the screen specs in Section 8, the Firestore schema in Section 9 (amounts stored as integer paise, never floats), the atomic balance-update logic in Section 10 (use `runTransaction`, never read-then-write), and the offline behavior in Section 11. Apply the Firestore security rules in Section 12.1 exactly. Use Material 3 with a seeded color scheme (deep teal or indigo), 16px corner radius, full dark mode support. Implement account deletion (Section 12.4) alongside logout — this is a Play Store requirement, not optional. Do not build anything listed in Section 14 (out of scope for v1). Definition of done is Section 15.

---

*End of PRD.*
