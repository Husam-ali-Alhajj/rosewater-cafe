# Rosewater Café — Master Guide

The single document that explains the whole project: what it is, what it's built
with, how it's laid out, how the pieces fit together, and *why* each choice was
made. Written from the actual code and migrations as of the **Sprint 4** commit
(`488373d`, 2026-09-16), cross-checked against `docs/decisions.md`.

> **How this file relates to the others**
> - `MASTER.md` (this file) — the map. Read it first.
> - `docs/decisions.md` — the long-form log (53 numbered decisions, with the
>   bugs found, proofs, and trade-offs). This guide cites it as **#N**.
> - `README.md` — still the untouched Flutter template; ignore it.
>
> Note: the "Current status" block at the top of `docs/decisions.md` is stale
> (it still says Home is a stub). The status table in §2 below is current.

---

## Table of contents

1. [What the app is](#1-what-the-app-is)
2. [Current status](#2-current-status)
3. [Tech stack — and why each piece](#3-tech-stack--and-why-each-piece)
4. [Architecture at a glance](#4-architecture-at-a-glance)
5. [Repository layout](#5-repository-layout)
6. [App startup and navigation](#6-app-startup-and-navigation)
7. [Screen-by-screen walkthrough](#7-screen-by-screen-walkthrough)
8. [The service layer](#8-the-service-layer)
9. [The backend: Supabase](#9-the-backend-supabase)
10. [Security model](#10-security-model)
11. [Design system](#11-design-system)
12. [Code conventions and patterns](#12-code-conventions-and-patterns)
13. [Testing](#13-testing)
14. [Running, configuring, and handing off](#14-running-configuring-and-handing-off)
15. [Known limitations and open questions](#15-known-limitations-and-open-questions)
16. [Gotchas](#16-gotchas)
17. [Where to look for what](#17-where-to-look-for-what)

---

## 1. What the app is

**Rosewater VIP Café** is a members-only hookah lounge app. A person signs up,
picks a paid membership tier, uploads an ID, pays, and then gets:

- a **home dashboard** with their membership status, monthly usage
  (hookah sessions / drinks), service hours, and perks;
- a **QR code + "Open Door"** screen for entering the café, with a guest count
  limited by their plan;
- an **event reservation** flow to book the whole café for a private event.

**Origin and constraints.** This is a training project. The company supplied
only a **Figma design** (26 exported PDFs in `Rosewater Cafe 14012026/`) — no
written spec and no task list. Work was broken into sprints by the developer,
one screen at a time, and every place where the design was ambiguous was
resolved and written down in `docs/decisions.md`. The backend is a *personal dev*
Supabase project; at handoff the company runs the SQL migrations on their own
project and swaps one config file (§14).

**Membership tiers** (seeded in the database, not hardcoded in the app):

| Plan | Price | Hookah sessions | Drinks | Guests | Extra perks |
|---|---|---|---|---|---|
| Basic | $99/mo | 10 | 10 | 1 | Standard seating, member discounts |
| Premium *(Most Popular)* | $199/mo | 20 | 20 | 2 | Priority seating, weekend access, member discounts |
| VIP | $399/mo | Unlimited | Unlimited | 2 | Private booth, 24/7 access, event priority, exclusive menu |

"Unlimited" is stored as SQL `NULL` in `hookah_limit` / `drinks_limit` — not
`-1` or `0` (#28).

---

## 2. Current status

| Area | State |
|---|---|
| Onboarding carousel (4 slides) | ✅ Built |
| Auth: landing, create account, sign in, forgot password, confirm-email-pending | ✅ Built, verified live |
| Membership: choose plan → ID upload → mock payment → success | ✅ Built, verified end-to-end |
| Session-aware routing on app start | ✅ Built |
| Bottom-nav shell (Home / QR Code / Events / Profile) | ✅ Built |
| Home dashboard (status, quick actions, usage, hours, benefits) | ✅ Built |
| QR / Door Access + `log_door_access` RPC | ✅ Built |
| Event reservation form + confirmation + `create_event_reservation` RPC | ✅ Built (UI click-through was left to the developer, #37/#38) |
| Subscription expiry (daily `pg_cron` job + client-side check) | ✅ Built |
| Profile tab (read-only screen + **Sign Out**) | ✅ Built (Sprint 5 Task 1). Its only remaining stub row is **Upgrade Membership**, since decision #25 has no re-subscribe flow to send it to yet |
| Edit Profile (name, phone, photo; email read-only) | ✅ Built (Sprint 5 Task 2, #42), avatars bucket + storage isolation proven live |
| App Settings (Sprint 5 Task 7, #47) | ✅ Dark Mode/Language/Animations/Sound/Haptic are visual-only placeholders (decisions #5/#47); **Cache Size/Clear Cache/Clear All App Data are real** — a genuine, computed number, and real clearing (image cache + local preferences + sign-out) |
| Help & Support (Sprint 5 Task 6, #46) | ✅ Static contact cards (no backend); FAQ accordion with the **one real answer** the design exports, the other three questions shown with a plain placeholder, never invented copy; Resources open coming-soon pages |
| Privacy & Security (Sprint 5 Task 5, #45; Delete Account made real, #52; hardened, #54; Change Email added, #57) | ✅ **Change Password is real** (re-enter the current password; same strength rules as signup). **Delete Account is real, immediate, self-service deletion, and password-gated**: an inline form (same expand-in-place pattern as Change Password) re-verifies the current password, then removes every stored file in both `avatars`/`id-documents` — aborting the whole deletion if that cleanup fails — before calling `delete_own_account`, which cascades through every table of the user's data; no undo, no request queue. **Change Email is real and password-gated too**: requests a Supabase email change (current email keeps working until the new one's confirmation link is clicked; `profiles.email` follows automatically via a server-side sync trigger). Biometric / Two-Factor / Auto-Lock are **disabled "Coming soon" placeholders**; Privacy Policy / Terms open a coming-soon page |
| Notification settings (7 toggles, **local-only**) | ✅ Built (Sprint 5 Task 4, #44): saved on the device with `shared_preferences`, no table, no network. The toggles record preferences only — nothing sends push/email/SMS yet |
| Payment Methods (list / add / set default / delete, metadata only) | ✅ Built (Sprint 5 Task 3, #43); one-default-per-user enforced in the database and proven live. Card brand/last4 are derived client-side for display — still no real processor |
| **Notifications** (Home bell) | 🟡 Stub screen, no unread badge, table exists but unused (#32, #41) |
| Home dashboard header (Welcome / Member ID / Logout) | ✅ Built to the Figma frame (#41) |
| **Real payments** (Stripe) | ❌ Mocked on purpose — see §15 |
| **Usage counters incrementing** (`hookah_used`/`drinks_used`) | ❌ No mechanism exists (#25, #33) |
| **Usage period renewal / re-subscribe flow** | ❌ Deferred (#25) |
| Settings, dark mode, language, Help & Support | ❌ Not built (#5) |
| Admin/staff side (ID approval, door scanner) | ❌ Not in this app |

Git history mirrors the sprints: `first sprint` → `sprint 1` → `sprint 2` →
`sprint 3` → `sprint 4`.

---

## 3. Tech stack — and why each piece

### Core

| Technology | Version | Role | Why |
|---|---|---|---|
| **Flutter / Dart** | Dart SDK `^3.12.2` | UI framework | One codebase for Android, iOS and web (plus desktop folders); Material 3 widgets. Web was also used as the dev-testing target. |
| **Material 3** | `useMaterial3: true` | Widget/theming system | Default Flutter design language; heavily overridden to match the Figma file. |
| **Supabase** | hosted | Backend: Auth + Postgres + Storage + `pg_cron` | Gives auth, a real relational DB with Row Level Security, file storage and scheduled jobs without running a server. RLS lets the *client* talk to the DB directly and still be safe. |
| **PostgreSQL** | via Supabase | Data + business rules | Enums, partial unique indexes, triggers, and `SECURITY DEFINER` functions enforce rules *inside* the database, where a hacked client can't bypass them. |

### Packages actually used (from `pubspec.yaml`)

| Package | Used in | Why it's here |
|---|---|---|
| `supabase_flutter ^2.8.0` | `main.dart`, every service | Official client: auth, `.from()` queries, `.rpc()`, storage. Initialised once in `main()`. |
| `flutter_secure_storage ^9.2.2` | `services/secure_local_storage.dart` | Stores the login session in the OS's encrypted vault (Keystore / Keychain / Credential Locker). `supabase_flutter`'s default writes tokens to plain-text `SharedPreferences` (#6). |
| `shared_preferences ^2.2.3` | `services/onboarding_prefs.dart`, `services/remember_me_prefs.dart`, `services/settings_provider.dart` | Tiny local values: "has this device seen onboarding", "was the last sign-in remembered" (#56), and the seven app-wide settings (#58). Deliberately *not* secure storage and *not* backend — per-device UI flags, not secrets or account data. |
| `provider ^6.1.2` | `main.dart`, `services/settings_provider.dart` | This project's first state-management package (#58) — `SettingsProvider` (a `ChangeNotifier`) is registered once above `MaterialApp` so any screen reaches it via `context.watch`/`context.read` without prop-drilling. |
| `qr_flutter ^4.1.0` | `screens/qr_access/` | Renders the member's QR code. |
| `image_picker ^1.1.2` | `screens/membership/id_upload_screen.dart` | Camera / gallery capture for the ID photo. |
| `file_picker ^10.3.4` | same | Picking an existing PNG/JPG/**PDF** — `image_picker` can't do PDFs. |
| `intl ^0.19.0` | `events/*`, `event_reservation_service.dart` | Date formatting (`yyyy-MM-dd` for the RPC, display dates). |
| `google_fonts ^6.2.1` | `theme/app_theme.dart` | The Figma design uses **Inter** everywhere. |
| `flutter_lints ^6.0.0` *(dev)* | `analysis_options.yaml` | Recommended lint rules. |
| `flutter_secure_storage_platform_interface` *(dev)* | `test/secure_local_storage_test.dart` | Lets the test fake the OS storage layer so it runs with no device. |

### Removed as dead weight (Sprint 6, #49)

`provider`, `http`, `sqflite`, `path` and `cupertino_icons` were declared in
`pubspec.yaml` but never imported anywhere in `lib/` or `test/` — verified by
search before removal. State management is plain `StatefulWidget` + `setState`
(no `provider`); all networking goes through `supabase_flutter` (no `http`);
reservations live server-side in Postgres, not on-device (no `sqflite`/`path`);
no Cupertino-styled icon is used anywhere (no `cupertino_icons`). All five were
dropped from `pubspec.yaml` and `pubspec.lock` regenerated.

---

## 4. Architecture at a glance

The app is a thin, layered client over a database that enforces its own rules.

```
┌───────────────────────────── Flutter app (lib/) ─────────────────────────────┐
│                                                                              │
│  screens/      UI + local state (setState). Decides *what to show*.          │
│      │                                                                       │
│      ▼                                                                       │
│  services/     One class per backend concern. The ONLY place that talks      │
│      │         to Supabase. Turns raw DB errors into safe, typed failures.   │
│      ▼                                                                       │
│  models/       Plain Dart classes mirroring DB rows (fromJson).              │
│                                                                              │
│  widgets/  theme/  utils/   shared UI pieces, design tokens, pure helpers    │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │  supabase_flutter (HTTPS)
                                       ▼
┌───────────────────────────────── Supabase ───────────────────────────────────┐
│  Auth  ──►  auth.users ──trigger──►  public.profiles                         │
│  Postgres tables + Row Level Security  (client can mostly only READ)         │
│  SECURITY DEFINER functions (RPCs)     (the ONLY way to WRITE money-shaped   │
│                                         or access-shaped data)               │
│  Storage bucket `id-documents` (private, per-user folders)                   │
│  pg_cron  ──►  expire_subscriptions() daily at 03:00                         │
└──────────────────────────────────────────────────────────────────────────────┘
```

**The one idea to remember:** the phone can *display* memberships, usage,
door-access history and prices, but it can never *write* them directly. Every
write that has security or money implications goes through a narrow, named
database function that re-checks everything server-side (§10). The Flutter code
is UX; the database is the authority.

**Why no Provider / Riverpod / Bloc?** Each screen owns a small amount of local
state, and shared data is passed by constructor. The one genuinely shared object
(`ActiveMembership`) is fetched once in `MainShell` and handed down. That's
simple enough that a state-management library would be overhead.

---

## 5. Repository layout

```
rosewater cafe/
├── MASTER.md                    ← this file
├── README.md                    ← stock Flutter template (unedited)
├── pubspec.yaml                 ← dependencies (see §3)
├── analysis_options.yaml        ← flutter_lints
├── docs/decisions.md            ← 39-entry decisions & open-questions log
│
├── lib/                         ← ALL app code
│   ├── main.dart                ← Supabase.initialize + MaterialApp
│   ├── config/supabase_config.dart   ← the ONE file to edit at handoff
│   ├── theme/                   ← colors, text styles, ThemeData
│   ├── models/                  ← MembershipPlan, Profile, UsageAllowance, ReservationSummary
│   ├── services/                ← all backend access (§8)
│   ├── utils/                   ← pure functions: validators, payment validators, service hours
│   ├── widgets/                 ← shared UI: buttons, bottom nav, dots, badge, coming-soon stub
│   └── screens/
│       ├── app_entry_point.dart ← decides the first screen
│       ├── onboarding/          ← 4-slide carousel
│       ├── auth/                ← landing, create account, sign in, forgot password, confirm-email
│       ├── membership/          ← choose plan, ID upload, payment, payment success
│       ├── home/                ← main_shell.dart (tabs) + home_screen.dart (dashboard)
│       ├── qr_access/           ← QR code + Open Door
│       ├── events/              ← events_tab, reserve_event, reservation_confirmed
│       └── profile/             ← profile_screen.dart (Profile tab)
│
├── supabase/migrations/         ← 9 SQL files = the entire backend definition
├── test/                        ← 18 test files, 179 tests
│
├── assets/images/               ← declared in pubspec, currently only a README
├── android/ ios/ web/ windows/ linux/ macos/   ← Flutter platform runners
├── Rosewater Cafe 14012026/     ← 26 PDF exports of the Figma design (source of truth for UI)
└── example/                     ← 4 screenshots
```

### Why this folder structure

Folders are split **by role**, not by feature, so a change has an obvious home:

- **`screens/`** grouped by *user journey* (auth → membership → home…) because
  that's how the Figma file and the sprints were organised.
- **`services/`** is the *only* layer allowed to import `supabase_flutter`
  calls for data. If the backend changes (or is mocked), only this folder moves.
- **`models/`** exist so screens work with typed objects, not `Map<String, dynamic>`.
- **`utils/`** holds *pure* functions (no widgets, no I/O) precisely so they can
  be unit-tested with plain inputs — `ServiceHours.isFullServiceAt(DateTime)`
  takes the time as a parameter instead of reading the clock for exactly this
  reason (#30).
- **`widgets/`** are reused across ≥2 screens; one-off widgets stay private
  (`_MembershipCard`, `_UsageCard`…) inside the screen file that uses them.
- **`config/`** isolates environment-specific values in one file.

---

## 6. App startup and navigation

### 6.1 Boot sequence (`lib/main.dart`)

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `await Supabase.initialize(url, publishableKey, authOptions: … SecureLocalStorage())`
   — this also **recovers and refreshes any saved session** before the UI
   exists. (Why awaited before `runApp`: so the very first screen already knows
   the true signed-in state.)
3. `runApp(RosewaterCafeApp)` → `MaterialApp(theme: AppTheme.light, home: AppEntryPoint())`

### 6.2 First-screen decision (`AppEntryPoint`)

```
                       App start
                          │
              supabase.auth.currentSession?
                 │                    │
               none                 present
                 │                    │
     seen onboarding before?    hasActiveSubscription()?
        │            │             │              │
       no           yes           yes             no
        │            │             │              │
   Onboarding   Auth Landing    MainShell   ChooseMembership
```

Result: a signed-in user is never asked to log in again after a force-close
(#15), and onboarding shows only once per device. A brief spinner shows while the
two async checks resolve.

The same two-way check (`active` → `MainShell`, otherwise → `ChooseMembership`)
is repeated in `SignInScreen` after a successful login. **Pending** subscriptions
also land on Choose Membership (they see the cards again) — see #22/#24.

### 6.3 The full user journey

```
Onboarding ─► Auth Landing ─┬─► Create Account ─┬─(session)──► Choose Membership
  (once)                    │                   └─(no session, email confirm ON)─► Confirm Email Pending
                            └─► Sign In ────────────(no active sub)──► Choose Membership
                                   │  ▲                                     │ start_subscription RPC
                                   │  └── Forgot Password ─(email link)─► Set New Password ─► Sign In
                                   │                                     ▼
                                   │                                  ID Upload  ◄─ "Back to Plans"
                                   │                                     │            (cancel_subscription RPC,
                                   │                                     ▼             returns to plan cards)
                                   │                                  Payment (mock)
                                   │                                     │ confirm_subscription_payment RPC
                                   │                                     ▼
                                   │                              Payment Success
                                   ▼                                     │
                               (active sub) ────────────────────────────►▼
                                                                    MainShell
                                  ┌──────────────┬─────────────────┬──────────────┬──────────────┐
                                  │ Home         │ QR Code         │ Events       │ Profile      │
                                  │ dashboard    │ Door Access     │ Reserve form │ details +    │
                                  │              │                 │ → Confirmed  │  Sign Out    │
                                  └──────────────┴─────────────────┴──────────────┴──────────────┘
```

Signup order (account → plan → ID → pay → home) was **confirmed by the company**
as the real order (#1).

### 6.4 Navigation techniques used, and why

| Technique | Where | Why |
|---|---|---|
| `Navigator.push` | drill-down steps (landing → sign in, choose plan → ID upload → payment) | Back button should work. |
| `pushReplacement` | sign in / create account → next screen | The auth screen shouldn't stay on the back stack. |
| `pushAndRemoveUntil(… (route) => false)` | after payment, after sign out, after expiry bounce | Clears the whole stack so **Back can't return to a stale screen** (e.g. the payment form, or an authenticated screen after logout). |
| `IndexedStack` | `MainShell` | Keeps each tab's state alive when switching tabs, like a real tabbed app. |
| **Tab switching via callbacks, not routes** | Home quick-actions → `onGoToQrCode`/`onGoToEvents`; confirmation → `onGoToHome` | QR and Events are *sibling tabs*, not pushable pages. Same callback the bottom bar uses, so both do literally the same thing (#29). |
| **Widget swap inside a tab** | `EventsTab`: form ⇄ confirmation | A plain `if (reservation != null)` instead of a nested Navigator, so there's *nothing on the nav stack to leave dangling* (#38). |
| Constructor data passing | `PaymentScreen(plan)`, `PaymentSuccessScreen(plan)`, `ReservationConfirmedScreen(summary)` | The previous screen already has the data; no extra DB read, no chance of it drifting. |

---

## 7. Screen-by-screen walkthrough

### Onboarding — `screens/onboarding/`
Four swipeable slides (Welcome, QR Code Door Access, Monthly Allowances,
Exclusive Events), each with its own icon + gradient pulled from Figma. Pure UI,
no backend. "Skip" and "Get Started" both funnel through one method that calls
`OnboardingPrefs.markOnboardingSeen()` then goes to Auth Landing.
*Data in `onboarding_page_data.dart`; helpers `DotsIndicator`, `OnboardingIconBadge`.*

### Auth — `screens/auth/`
- **`auth_landing_screen`** — logo, feature rows, "Sign In" / "Create Account".
- **`create_account_screen`** — full name, email, phone (must start with `+` and
  country code), password (8+ chars with upper, lower, number), confirm, Terms
  checkbox. Calls `AuthService.signUp`, passing name/phone as **signup
  metadata** so a DB trigger builds the profile atomically (§9.3). Routes to
  Choose Membership, or to `ConfirmEmailPendingScreen` if the project requires
  email confirmation and no session came back. Has a synchronous double-submit
  guard and inline server errors under the right field (#8).
- **`sign_in_screen`** — email + password. **All** credential failures show one
  message ("Invalid email or password.") so the form can't be used to discover
  which emails are registered (#11). "Remember me" is real (#56): unchecked
  forces a sign-out on the next cold start (checked by `AppEntryPoint`, not
  here); checked (the default) behaves exactly as before. After success,
  routes by subscription state.
- **`forgot_password_screen`** — always shows the same "If an account exists…"
  success state; never reveals whether an email is registered (#12).
- **`confirm_email_pending_screen`** — no Figma frame existed; built to match
  the other auth cards.

### Membership — `screens/membership/`
- **`choose_membership_screen`** — loads plans via `fetchPlans()` (cheapest
  first — an explicit `ascending: true` fixed a real reversed-order bug, #17).
  Bullets come from `MembershipPlan.featureBullets` (numeric bullets derived
  from real columns + the `features` text array). Tapping "Select" calls
  `start_subscription` → ID Upload. If a pending row already exists, shows an
  inline "membership request in progress" error instead of silently resuming.
- **`id_upload_screen`** ("Verify Your Membership") — name/email/phone/plan shown
  **read-only** from the user's own data (not re-asked, #18). Upload via camera,
  gallery, or file picker (PNG/JPG/PDF, ≤10 MB, validated *before* upload).
  Uploads to the private bucket and inserts an `id_documents` row (always
  `pending`). "Back to Plans" calls `cancel_subscription` then pops `true`, which
  is how the parent screen distinguishes a deliberate cancel from a system Back
  (#19).
- **`payment_screen`** — **mock** card form (16-digit number, `MM/YY` not expired,
  3-digit CVV). Card values are validated for *shape only*, never sent
  anywhere, never logged, no autofill hints, controllers cleared/disposed. "Pay"
  calls `confirm_subscription_payment(subscription_id)` — the payload contains
  only the subscription id (#22).
- **`payment_success_screen`** — no Figma frame existed; built in the app's
  visual language. "Continue" → `MainShell` via `pushAndRemoveUntil` (#23).

### Home shell — `screens/home/`
- **`main_shell`** — the authenticated app's root. Fetches `ActiveMembership`
  and the user's `Profile` **once** (in parallel), shows a spinner, and if the
  membership is null (subscription lapsed) bounces to Choose Membership.
  Otherwise builds the four tabs in an `IndexedStack` above `AppBottomNav`,
  handing both objects to Home, QR and Profile (#35, #41). A failed profile
  fetch becomes `null` and each tab degrades on its own.
- **`home_screen`** — built to the exact Figma frame `1217:3554` (#41). Top to
  bottom: **header** ("Welcome, {first name}!", "Member ID: …", the notification
  bell — stub, no badge yet — and **Logout**) → **membership
  status card** (plan, "Active" badge, valid-until) → **quick actions**
  (Access Café → QR tab, Reserve Event → Events tab) → **usage cards** (hookah /
  drinks, with progress bars; "Unlimited" and no bar when the limit is `NULL`)
  → **service hours** card (full service 9 AM–11 PM, self-service otherwise,
  computed from `DateTime.now()`) → **benefits** card (same `featureBullets`
  getter Choose Membership uses, so they can't drift). It only fetches usage
  itself; membership and profile arrive via constructor. `HomeContent` is split
  from the loading widget so the mapping is widget-tested.

### QR / Door Access — `screens/qr_access/qr_access_screen.dart`
Shows a QR code of the member's `member_id` (e.g. `RC-000031`), a guest stepper
clamped to `0…plan.maxGuests`, and "Open Door" → `log_door_access` RPC. Success
shows "Door unlocked!" and resets the counter; failures map to friendly
sentences. The UI clamp is UX — the RPC re-validates the limit server-side (#34,
#35). **Simplification:** the QR payload is a static `member_id`; production
needs a short-lived signed token (documented in the class comment).

### Events — `screens/events/`
- **`events_tab`** — holds the "just confirmed" reservation (or `null`) and
  swaps between the two screens below.
- **`reserve_event_screen`** — Event Type (Birthday / Corporate / Private Party /
  Other — a placeholder list), date, start time, duration (≤2 decimals to match
  `numeric(4,2)`), guest count (5–100), static package list, live price
  breakdown, "Confirm Reservation" → `create_event_reservation` RPC. Client
  validation blocks bad input before any request; the server re-checks.
- **`reservation_confirmed_screen`** — confirmation card driven by a
  `ReservationSummary` passed through the constructor; "Back to Dashboard"
  clears state and switches to the Home tab.

> **Two different "guest counts" — do not merge them.** Door Access = people you
> bring in with you (0–2, capped by your plan, table `door_access_logs`). Event
> Reservation = headcount for a private event (5–100, table
> `event_reservations`). Same label, different meaning; kept as separate fields,
> validators and tables on purpose (#33).

### Profile tab — `screens/profile/profile_screen.dart`
Built to the exact values in Figma frame `1216:2169` (#40). Top to bottom: title →
profile card (avatar, real name, plan badge like **"PREMIUM Member"** built from the
real plan name, email, phone, member ID) → Edit Profile → **Membership Details**
(Plan, Valid Until in M/D/YYYY like Home, Max Guests, Upgrade Membership) →
**Settings** list (Payment Methods, Notifications, Privacy & Security, Help & Support,
App Settings) → **Sign Out** → version line.

Data: `ActiveMembership` and the user's profile are both passed in from
`MainShell` (no re-fetch); the screen only calls
`ProfileService.fetchCurrentProfile()` itself to retry. **Edit Profile** opens the
real screen below; a saved profile goes up through `onProfileChanged` to
`MainShell`, which owns the profile, so Home's greeting, the QR tab and this tab
all update at once. The avatar shows the member's photo when there is one. A missing phone / member
ID hides its row instead of showing a placeholder; a failed profile load shows
"Try again" while the rest (incl. Sign Out) keeps working. Every row/button except
**Sign Out** and **Edit Profile** opens a `ComingSoonScreen` for now. Sign Out is the
permanent one: it calls `supabase.auth.signOut()` and clears the stack to Auth Landing.
`ProfileContent` is split from the loading widget so the data mapping is widget-tested.

### Privacy & Security — `screens/profile/privacy_security_screen.dart`
Three cards (Figma frames `1217:2644` / `1217:2946`, #45):
- **Security Options** — Biometric Authentication, Two-Factor Authentication, Auto-Lock:
  **disabled placeholders**, drawn as designed but off, dimmed, inert and marked "(Coming Soon)"
  (the design draws Auto-Lock *on*; shown off so nothing looks like it protects the account when it
  doesn't). "Lock after inactivity" and "require biometric to unlock" are two different features
  behind that one toggle; neither is built.
- **Password → Change Password (real).** Opens the design's inline form (Current / New / Confirm,
  each with a show/hide eye). `AuthService.changePassword` **re-authenticates with the current
  password first** (`signInWithPassword`) and only then calls `updateUser(password:)` — Supabase's
  API doesn't ask for the current password, but a phone left unlocked must not let anyone silently
  change it. If verification fails for any reason, the password is never touched. The new password
  uses decision #10's rule (`Validators.password`, shared with signup) and must differ from the
  current one. After a successful change it also signs out every *other* session (best effort).
- **Privacy → Delete Account (real, immediate, self-service — decision #52).** Confirming (a dialog
  spelling out that this is permanent and cannot be undone) calls the `delete_own_account` RPC,
  which deletes exactly the caller's own `auth.users` row — cascading through every table of their
  data (profile, subscriptions, payment methods, reservations, everything) — then the screen ends
  the local session and returns to Auth Landing. Replaces the request-queue of decision #45; there
  is no `deletion_requests` table anymore. View Privacy Policy / Terms of Service open a coming-soon
  page (no text exists yet).

### App Settings — `screens/profile/app_settings_screen.dart`
Appearance → Language → Interactions → Data & Storage → app info footer (#47).
- **Dark Mode, Language, Animations, Sound Effects, Haptic Feedback are all visual-only.**
  Dark Mode/Language were already out of scope (decision #5); Animations/Sound/Haptic weren't
  asked for either, so they're drawn at the design's own state (on) and are inert, for the same
  "no functionality beyond what's decided in scope" reason. (The Notifications screen's "Sound &
  Vibration" toggle is a *different* setting — notification sound, not general UI sound — kept
  deliberately separate, like decision #33's two different "guests" fields.)
- **Data & Storage is real**, the task's explicit "your call": **Cache Size shows the real,
  computed number of bytes in Flutter's image cache** — never the design's fabricated "12.5 MB" —
  and **Clear Cache** really clears it (meaningful: the profile photo's signed URL is the one real
  user of that cache). **Clear All App Data** really wipes every local preference and then signs
  the device out for real, after a confirm dialog.
- The footer shows the real app version from `pubspec.yaml` ("Version 1.0.0", "Build 1") instead
  of the design's mock "Build 2024.01.14".

### Help & Support — `screens/profile/help_support_screen.dart`
Built to Figma frame `1217:3158` (#46): three static contact cards (Live Chat / Email Us /
Call Us — a label and a description only, no real address/number in the design, so **not
tappable, no backend**) → an FAQ accordion → Resources.
- **FAQ:** the design exports a real answer for only the first question ("How do I use my QR
  code…"); the other three questions are real design copy but their answers were never
  exported (the "1 of 4 FAQ answers exported" gap flagged since Sprint 2). Those three show a
  plain **"Answer not available yet."** placeholder — never an invented answer standing in for
  real content. The accordion is exclusive (opening one closes any other) and the first item
  starts open, matching the one state the design shows.
- **Resources** (User Guide / Membership Benefits / Community Guidelines) have no content yet,
  so each opens a coming-soon page, the same pattern as Privacy & Security's Privacy Policy /
  Terms of Service.

### Notification settings — `screens/profile/notification_settings_screen.dart`
Built to Figma frame `1217:2539` (#44). Header → **Communication Preferences** card (gradient
title band + Push, Email, SMS, Sound & Vibration) → **Notification Types** card (Event
Reminders, Allowance Alerts, Promotions & Offers) → **Done**. Design defaults: SMS off, the
other six on.
- **Local-only, on purpose** (the standing Sprint 2 decision): each flip is saved to the device
  by `NotificationPrefs` (`services/notification_prefs.dart`, `shared_preferences`) the moment
  it happens — the design has no Save button — and there is **no table and no network call**.
  The open notifications-feed question (#32) is what would decide whether these ever move to
  the backend, so none is built meanwhile.
- Keys are namespaced by user id (`notification_settings.<user>.<toggle>`), so two people on one
  phone don't share choices. The id is read from the local session, not fetched.
- The toggles only *record* preferences: nothing in the app sends push, email or SMS yet.

### Payment Methods — `screens/profile/payment_methods_screen.dart`, `add_payment_method_screen.dart`
Built to Figma frame `1217:2477` (#43). Header → gradient **Add New Payment Method**
button → the user's real cards: each a white card with a card-emoji tile, brand, a green
**Default** badge, `•••• •••• •••• 4242`, `Expires 12/25`; a red delete button, and a green
set-as-default button on non-default cards. Not in the design and added: an empty state,
a failed-load retry, a confirm dialog before deleting, and error SnackBars.
- **The "one default" rule lives in the database, not the screen.** The screen just asks
  "make this default" / "delete this" (one request each) and reloads, so it always shows
  what the server ended up with — never a client-side reorder. See §9.3.
- **Add Payment Method has no Figma frame** (the design only has the button), so it's
  built to match the Complete Payment form. It reuses `PaymentValidators` (16 digits, MM/YY
  not in the past, 3-digit CVV — decision #22) and the same field widgets (moved to
  `widgets/payment_fields.dart`). **Only brand, last 4 and expiry are stored**; the number
  and CVV are validated and discarded — the service has no parameter for them.
- **Accepted simplification:** with no payment processor, brand and last 4 are derived from
  the typed number (`utils/card_brand.dart`) purely for display — the same category as
  `confirm_subscription_payment`, not a new one.

### Edit Profile — `screens/profile/edit_profile_screen.dart`
Built to Figma frame `1217:2403` (#42). Header with back arrow → photo card (128px
avatar, camera button, hint) → **Personal Information** (Full Name, Email Address,
Phone Number) → **Membership Information** (Member ID, Subscription Type, note) →
Cancel / Save Changes.
- **Editable:** full name, phone, photo. **Email is read-only** — plain text, not a
  text field at all (can't be focused), with a short note. Changing an auth email
  needs its own re-verification flow, which doesn't exist yet.
- **Validation before any network call:** name required; phone uses
  `Validators.phone` — decision #10's exact rule, moved out of Create Account so both
  screens share it.
- **Photo:** picked with `image_picker` (camera/gallery), validated by `AvatarService`
  (PNG/JPG/WebP, ≤5 MB), previewed locally, and uploaded only on Save into the private
  `avatars` bucket at `<user_id>/<timestamp>.<ext>`. The old photo is deleted after a
  successful save; an upload whose save failed is cleaned up.
- **Save:** upload (if a new photo) → plain `profiles` UPDATE (no RPC; self-owned write,
  scoped by `auth.uid() = id`) → pop with the saved profile. Nothing changed → no request.

---

## 8. The service layer

Every file in `lib/services/` is a small `const` class (or, for the client, a
top-level variable). Screens instantiate them as `const XService()`. Nothing
else in the app calls the database.

| File | Responsibility | Backend calls |
|---|---|---|
| `supabase_client.dart` | Exports the global `supabase` client. | — |
| `auth_service.dart` | `signIn`, `signUp`, `resetPassword` (sends `redirectTo: SupabaseConfig.authRedirectUrl`, #55), `changePassword` (verifies the current password first), `verifyCurrentPassword` (the same re-auth step, reused by account deletion and email change), `completePasswordRecovery` (sets a new password inside an active recovery session, #55), `changeEmail` (verifies the current password, then requests a Supabase email change, #57), `currentUserEmail`/`pendingEmailChange` getters (for the Email card's display, #57). Maps Supabase errors → `SignInFailure`/`SignUpFailure`/`ResetPasswordFailure`/`ChangePasswordFailure`/`ReauthenticationFailure`/`SetNewPasswordFailure`/`ChangeEmailFailure`. | `auth.signInWithPassword`, `auth.signUp`, `auth.resetPasswordForEmail`, `auth.updateUser`, `auth.signOut(others)` |
| `subscription_service.dart` | Plans, active membership, the whole subscription lifecycle. | `from('membership_plans')`, `from('subscriptions')`, RPCs `start_subscription`, `confirm_subscription_payment`, `cancel_subscription` |
| `profile_service.dart` | Current user's `profiles` row; `updateProfile` (name, phone, optional photo path — never email). | `from('profiles')` select / update |
| `account_deletion_service.dart` | `deleteAccount(currentPassword:)` — re-verifies the password, removes every stored file in both storage buckets (aborts on any cleanup failure), then permanently deletes the signed-in user's account and everything tied to it. No undo. (#54) | `auth.signInWithPassword` (via `verifyCurrentPassword`), `storage.from('avatars'/'id-documents').list/remove`, RPC `delete_own_account` |
| `app_settings_service.dart` | Real image-cache size/clear; real `shared_preferences` wipe. | `PaintingBinding` image cache, `SharedPreferences` (no network) |
| `notification_prefs.dart` | Seven notification toggles, saved on the device (per user id). **No backend.** | `SharedPreferences` (no network) |
| `payment_method_service.dart` | List / add (brand, last4, expiry, default request — no parameter for a number or CVV) / set default / delete. Plain table access, no RPC. | `from('payment_methods')` |
| `avatar_service.dart` | Photo type/size validation, upload to `avatars/<user_id>/…`, signed display URLs, best-effort delete of a replaced photo. | `storage.from('avatars')` |
| `usage_service.dart` | Latest `usage_allowances` row (the "used" half). | `from('usage_allowances')` |
| `id_document_service.dart` | Validate (type/size) → upload → record. | `storage.from('id-documents')`, `from('id_documents').insert` |
| `door_access_service.dart` | Log an entry. | RPC `log_door_access` |
| `event_reservation_service.dart` | Create a reservation; owns the client copy of the hourly price. | RPC `create_event_reservation` |
| `onboarding_prefs.dart` | Local "seen onboarding" flag. | `SharedPreferences` (no network) |
| `remember_me_prefs.dart` | Local "was the last sign-in remembered" flag, checked by `AppEntryPoint` (#56). | `SharedPreferences` (no network) |
| `settings_provider.dart` | `ChangeNotifier` for all seven app-wide settings (theme, animations, sound, haptics, auto-lock ×2, biometric) — registered once above `MaterialApp` (#58). Not wired to any screen's toggle yet; that's each setting's own later Sprint 8 task. | `SharedPreferences` (no network) |
| `secure_local_storage.dart` | Encrypted persistence of the auth session. | `flutter_secure_storage` (no network) |

### Why services look the way they do

- **`const` classes with no state** — they're just namespaced functions; the
  real state lives in Supabase.
- **Typed failure classes with `code` + a UI-safe `message`** — the SQL
  functions raise machine-readable strings (`'no_active_subscription'`); the
  service maps them to `enum` codes and sentences a user can read. A raw
  `PostgrestException` never reaches the UI.
- **Redundant `.eq('user_id', userId)` filters** next to RLS — kept as defense
  in depth so correctness never silently depends on one layer.
- **`valid_until > now()` on every "is this active" query** — see §9.5.
- **`ActiveMembership` wraps a whole `MembershipPlan`** instead of copying its
  fields, so Home's benefits list and Choose Membership's bullets call the *same*
  getter and cannot diverge (#31).
- **Auth-message design is a security feature**, not just wording: sign-in
  collapses every credential failure into one message; forgot-password never
  reports "not found"; sign-up *does* reveal a duplicate email (deliberate UX
  choice, #7) and detects Supabase's decoy response (`identities: []`, #9).

---

## 9. The backend: Supabase

Everything lives in `supabase/migrations/`, applied in filename order. **They are
not auto-applied** — run them with the Supabase CLI (`supabase db push`) or paste
them into the dashboard's SQL Editor.

### 9.1 Migration index

| File | What it does |
|---|---|
| `20260912120000_initial_schema` | Extensions, enums, all 9 tables, triggers, storage bucket + policies, RLS, plan seed data |
| `20260912130000_handle_new_user_phone` | Trigger also copies `phone` from signup metadata |
| `20260914090000_add_pending_subscription_status` | Adds `pending` to the status enum (own file: Postgres won't let a new enum value be used in the same transaction) |
| `20260914090100_subscription_two_rpc_pattern` | `start_subscription`, `confirm_subscription_payment`, one-pending-per-user index, default status → `pending` |
| `20260915100000_cancel_subscription` | `cancel_subscription` (pending only) |
| `20260915120000_membership_plan_features` | `features text[]` column + seed copy per plan |
| `20260916090000_expire_subscriptions_cron` | `expire_subscriptions()` + daily `pg_cron` schedule |
| `20260916100000_log_door_access` | `log_door_access` RPC |
| `20260916110000_create_event_reservation` | `create_event_reservation` RPC; **drops** the direct-insert policy |
| `20260924100000_deletion_requests` | `deletion_requests` table (one open request per user; own-row insert-as-pending + select only; no update/delete for clients). **Superseded and dropped by the migration below (#52)** |
| `20260923100000_payment_methods_default_enforcement` | Partial unique index (one default per user), BEFORE trigger that swaps the default atomically and makes a first card the default, AFTER DELETE trigger that promotes another card, and replaces the `now()`-based `exp_year` CHECK |
| `20260922100000_avatars_bucket_and_profile_email_lock` | Private `avatars` bucket (5 MB, PNG/JPEG/WebP) + 4 per-user storage policies; trigger that stops a client changing `profiles.email` |
| `20260925100000_delete_own_account` | `delete_own_account` RPC (self-delete only, cascades through the user's own data); **drops** `deletion_requests`, its policies, and the `deletion_request_status` type (#52) |
| `20260926100000_close_event_reservations_update_gap` | **Drops** the `event_reservations` UPDATE policy — closes a live-confirmed price-tampering gap found in the consolidated security audit (#53) |
| `20260927100000_sync_profile_email_on_change` | `sync_profile_email()` trigger on `auth.users` (`AFTER UPDATE ... WHEN (new.email IS DISTINCT FROM old.email)`) — keeps `profiles.email` following a real, confirmed email change (#57) |

### 9.2 Tables

| Table | Purpose | Client can… |
|---|---|---|
| `profiles` | 1:1 extension of `auth.users`: name, email, phone, avatar, `member_id` | read/update own row (no INSERT — the trigger creates it; `member_id` immutable; `email` can't be changed by a client request) |
| `membership_plans` | Reference/seed data: price, limits, guests, `is_popular`, `features[]` | read only |
| `subscriptions` | A user's plan + `status` + `started_at`/`valid_until` | **read only** |
| `usage_allowances` | Per-period `hookah_used` / `drinks_used` | **read only** |
| `door_access_logs` | Audit trail of door entries + guest count | **read only** (no delete) |
| `event_reservations` | Private-event bookings incl. server-computed `total_price` | **read only** — write only via `create_event_reservation` RPC; the UPDATE policy that let a user edit their own `total_price` was closed live (#53) |
| `id_documents` | Path to an uploaded ID + `verification_status` | read + insert own (forced `pending`); **no UPDATE** |
| `payment_methods` | Card metadata only (brand, last4, expiry, `is_default`) — **never** PAN/CVV (no column for them) | full CRUD on own; at most one default per user is enforced by the database (§9.3) |
| `notifications` | Per-user notification rows | read/insert/update own — *exists but unused by the app* |

Enums: `subscription_status` (`pending`, `active`, `expired`, `cancelled`),
`reservation_status` (`pending`, `confirmed`, `cancelled`), `verification_status`
(`pending`, `verified`, `rejected`).

Every table has `created_at`/`updated_at` maintained by a shared
`set_updated_at()` trigger.

### 9.3 Triggers

- **`on_auth_user_created` → `handle_new_user()`** — when Supabase Auth creates a
  user, a `profiles` row is inserted immediately from the signup metadata
  (`full_name`, `phone`). *Why a trigger and not a follow-up client `UPDATE`?* If
  email confirmation is on, `signUp()` returns **no session**, so a client-side
  update would run anonymously, fail RLS, and silently leave an empty profile
  (#7).
- **`trg_profiles_member_id` → `generate_member_id()`** — assigns `RC-000001`,
  `RC-000002`… from a sequence, and forces `member_id` to stay unchanged on any
  later UPDATE.
- **`payment_methods` default rules (#43):** a **partial unique index**
  (`unique (user_id) where is_default`) is the hard guarantee that a user never has two
  defaults, whatever the client does or however requests interleave. A **BEFORE
  insert/update trigger** (`enforce_single_default_payment_method`) makes "set default" one
  atomic step (it clears the old default first), makes a user's **first card the default**
  automatically, and rejects an already-expired card on insert. An **AFTER DELETE trigger**
  (`promote_default_payment_method`) promotes the newest remaining card when the default is
  deleted, so a user who has cards always has a default. The old `exp_year >= now()` CHECK
  was replaced: it was re-evaluated on every update, so once a saved card's year passed,
  *any* update of it — including the trigger clearing an old default — failed.
- **`trg_sync_profile_email` → `sync_profile_email()`** (#57) — `AFTER UPDATE on
  auth.users`, guarded by `WHEN (new.email IS DISTINCT FROM old.email)` so it
  never fires on the constant unrelated churn of that table (every sign-in alone
  touches `last_sign_in_at`). Keeps `profiles.email` following a real, CONFIRMED
  email change — there's no "pending" value to reflect, since Supabase's own
  `/verify` endpoint updates `auth.users.email` server-side before ever
  redirecting back to the app. Doesn't conflict with `trg_profiles_lock_email`
  (decision #9/avatars migration): that trigger only blocks a client-initiated
  update (`auth.uid() is not null`), and this one runs with no JWT context at all
  (confirmed live: `auth.uid()` is `NULL` here, the same way it is inside
  Supabase's own internal update).

### 9.4 Subscription state machine

```
            start_subscription          confirm_subscription_payment
 (nothing) ─────────────────►  pending ──────────────────────────────►  active
                                 │                                        │
                 cancel_subscription                          expire_subscriptions() (daily)
                                 ▼                                        ▼
                             cancelled                                 expired
```

Guard rails: a **partial unique index** allows at most one `active` and at most one
`pending` row per user (the latter also closes a race between two simultaneous
`start_subscription` calls). Payment sets `valid_until = now() + 30 days` and
creates the first `usage_allowances` row.

### 9.5 RPC catalogue

All are `SECURITY DEFINER`, `search_path = public`, read `auth.uid()` internally,
and are executable by `authenticated` only.

| RPC | Args | Does | Raises |
|---|---|---|---|
| `start_subscription` | `p_plan_id` | Inserts a `pending` subscription | `not_authenticated`, `active_subscription_exists`, `pending_subscription_exists` |
| `confirm_subscription_payment` | `p_subscription_id` | pending → active, sets dates, creates first usage row | `not_authenticated`, `subscription_not_found_or_not_pending` |
| `cancel_subscription` | `p_subscription_id` | pending → cancelled (**never** an active one) | same as above |
| `log_door_access` | `p_guest_count` | Re-checks active membership *and* guests ≤ plan `max_guests`, inserts a log row | `not_authenticated`, `no_active_subscription`, `guest_count_exceeds_plan_limit` |
| `create_event_reservation` | type, date, start time, duration, guests | Guests 5–100, date ≥ today, computes `total_price = duration × 150`, inserts as `confirmed` | `not_authenticated`, `guest_count_out_of_range`, `event_date_in_past` |
| `delete_own_account` | — | Deletes the caller's own `auth.users` row; cascades through every table of their data. **No undo** (#52) | `not_authenticated` |
| `expire_subscriptions` | — | Flips lapsed `active` rows to `expired`. **Not callable by any client role** — only `pg_cron` runs it | — |

**Why "active" always means `status = 'active' AND valid_until > now()`:** the
expiry job only runs once a day, so a row can stay `active` for up to ~24 h after
it really lapsed. Checking `valid_until` in the client *and* in `log_door_access`
makes every live read correct immediately; the cron job just keeps the stored
column honest for anything that reads it raw (#25).

### 9.6 Storage

Private bucket **`id-documents`**. Object path must be `<user_id>/<filename>`; the
four storage policies check `(storage.foldername(name))[1] = auth.uid()::text`, so
each user can only touch their own folder (verified with role impersonation, #18).

Private bucket **`avatars`** (profile photos) works the same way — `<user_id>/<file>`
paths, the same four policies, plus a 5 MB cap and PNG/JPEG/WebP only enforced by the
bucket itself. The photo's path is stored in `profiles.avatar_url`; because the bucket
is private, the app shows it through short-lived signed URLs. Isolation verified live
(#42).

### 9.7 Scheduled job

`pg_cron` job `expire-subscriptions-daily`, schedule `0 3 * * *` (03:00 daily).
The migration unschedules any existing job with that name first, so re-running
doesn't create duplicates.

---

## 10. Security model

The design principle (#3, #4): **the client is untrusted.** A user's phone can be
modified, so anything that could grant free access, reset limits, fake an
entry, or change a price must be impossible to do directly.

1. **Row Level Security on every table.** A user only ever sees their own rows —
   confirmed live: an unfiltered `SELECT` on `profiles` returned only the
   caller's row.
2. **Read-only-from-client for the important tables.** `subscriptions`,
   `usage_allowances`, `door_access_logs` have *no* INSERT/UPDATE policy, so
   direct writes are denied by default.
3. **Writes go through RPCs** (§9.5) that: run as `SECURITY DEFINER`; pin
   `search_path` (blocks a classic privilege-escalation trick); take **no
   `user_id` parameter** (so you can't act as someone else); and validate every
   business rule themselves.
4. **`REVOKE EXECUTE … FROM anon` explicitly.** On Supabase, `revoke … from public`
   is *not* enough — the platform grants EXECUTE to `anon`/`authenticated`
   per-function. This was found by testing with real role impersonation, and is
   applied to every function (#16).
5. **No price parameter.** `create_event_reservation` has no argument a caller
   could use to smuggle a price; the old direct-insert RLS policy was dropped so
   there's no bypass (#36).
6. **ID verification can't be self-approved.** `id_documents` has no UPDATE policy
   and the INSERT policy forces `verification_status = 'pending'`.
7. **No card data stored or sent.** The payment screen validates shape locally
   and discards the values. The `payment_methods` table only has brand/last4/expiry.
8. **Encrypted session storage** (`SecureLocalStorage`), with log lines that only
   ever print `true/false` presence — never the token.
9. **Account-enumeration resistance** on sign-in and forgot-password (§8).
    **Changing the password requires the current one** (re-authentication before `updateUser`,
    #45) so a hijacked-but-unlocked session can't silently change it. **Account deletion is a
    request queue**, not a client-callable delete (#45): the client SDK can't delete an auth
    user by design, and a client-reachable function with power over the auth schema is more risk
    than this project should take.
    **Payment methods are self-owned rows** (RLS `auth.uid() = user_id`, no RPC, #43): a
    user can't list, change or delete another user's card (proven live).
10. **`profiles.email` is locked against client edits.** A `BEFORE UPDATE` trigger keeps
    the old email whenever the request comes from a signed-in user, so it can't drift from
    the login email in `auth.users` (same idea as the `member_id` lock). Server-side
    processes with no user session aren't affected (#42).
11. **The Supabase key in source is a *publishable* (anon) key** — safe by design,
    because RLS + the RPC rules above are the real protection. It's
    `SupabaseConfig.publishableKey`. Never put a `service_role` key in the app.

**Client-side validation is UX, not security.** Password strength, guest limits,
date checks etc. are duplicated server-side (or must be, e.g. via the Supabase
password policy in the dashboard) because anyone can call the API without the
Flutter form.

**Testing method that matters:** the Supabase SQL Editor runs as the `postgres`
superuser and bypasses RLS, so "it worked in the editor" proves nothing. Real
verification used `begin; set local role authenticated/anon; set local
request.jwt.claims = '…'; … rollback;` (#16).

---

## 11. Design system

Everything is derived from the Figma file (Design-panel values and, later, the
Figma REST API), not eyeballed (#20).

- **`theme/app_colors.dart`** — named constants: brand colours; the **primary CTA
  gradient** (`#FF2056 → #9810FA`); per-tier gradients (Basic grey, Premium
  purple, VIP rose); the soft 3-stop **page background gradient**
  (`#FFF1F2 → #FDF2F8 → #FAF5FF`); bottom-nav active accent `#EC003F`; text and
  status colours.
- **`theme/app_text_styles.dart`** — `logoTitle` (italic serif "Times New Roman"),
  headings, body, button. Some screens deliberately use **literal inline styles**
  because Figma gives certain elements unique sizes; the shared styles were left
  untouched so already-approved screens didn't change (#20).
- **`theme/app_theme.dart`** — `AppTheme.light` (Material 3, Inter via
  `google_fonts`, pink seed colour, filled inputs, rounded cards/buttons).
  `AppTheme.dark` is a bare stub and **isn't wired** — dark mode is out of scope (#5).
- **Shared widgets** (`lib/widgets/`):
  - `GradientButton` — the primary CTA; configurable gradient/height/font;
    renders at 50 % opacity with no shadow when `onPressed` is null.
  - `OutlinedSecondaryButton`, `DotsIndicator`, `OnboardingIconBadge`
  - `AppBottomNav` — 4 equal-width tabs; active tab = bold + accent + 4 px dot.
    (Deliberately `Expanded` rather than Figma's content-hugging tabs so it
    works at any screen width.)
  - `ComingSoonScreen` — the reusable placeholder for a destination not built yet.

---

## 12. Code conventions and patterns

- **Comments explain *why*, not what** — the codebase is heavily commented with
  the reasoning and a `docs/decisions.md` number. Match that when adding code.
- **Every screen with async work guards `mounted`** before `setState` / navigating.
- **Double-submit guard:** `if (_isSubmitting) return;` synchronously at the top
  of submit handlers (the button-disabled state alone isn't fast enough, #8).
- **Failure-class pattern** for every RPC service (`code` enum + `message`).
- **No hardcoded plan data in the app.** Plans, limits, and perk copy come from
  the DB so they can't drift; the only in-code lists are explicit placeholders
  (event types).
- **One source of truth for shared logic** — e.g. `featureBullets`,
  `pricePerHour`, the "active" predicate.
- **Pure functions take their inputs** (time, `now`) so tests can hit boundaries.
- **`const` constructors everywhere possible**; `MainShell`'s tab list is built
  once in `_load()` (not `static const`, because tab callbacks are closures).
- **Relative imports** inside `lib/`.
- **Lints:** `flutter_lints` defaults; `flutter analyze` reports only 3
  pre-existing informational lints (per #26–#31).

---

## 13. Testing

`flutter test` → **179 tests, all passing** (verified after App Settings, #47 — Sprint 5 complete).

| File | Covers |
|---|---|
| `test/id_document_service_test.dart` | Allowed extensions, 10 MB boundary (exact and +1 byte), disallowed/no extension, case-insensitivity |
| `test/payment_validators_test.dart` | Card number / expiry (incl. past dates) / CVV boundaries |
| `test/service_hours_test.dart` | Both service-hours branches and every boundary hour (9:00, 22:59, 23:00, midnight, 8:59) |
| `test/secure_local_storage_test.dart` | write → read → delete goes through the storage platform (fakes the OS layer) |
| `test/home_content_test.dart` | Home screen data mapping: greeting by first name + member ID (and their no-placeholder fallbacks), status card, usage `used / limit` and Unlimited-with-no-bar, progress fractions, service-hours status by time, benefits from the plan, every callback, and the layout's spacing/card heights against Figma |
| `test/app_settings_service_test.dart` | Real Flutter image-cache size/clear (a real image is put in the cache via a trivial in-memory `ImageProvider`, no network) and real `shared_preferences` wiping |
| `test/app_settings_screen_test.dart` | Every row/copy shown; Dark Mode/Language/Animations/Sound/Haptic are all off-or-on-as-designed and inert (tapping does nothing); Cache Size shows the real computed number, never the design's fake "12.5 MB"; Clear Cache really clears and updates the shown size; Clear All App Data confirms first, then clears the image cache and local preferences and runs the (injectable) post-clear step, in that order |
| `test/help_support_screen_test.dart` | Contact cards show their real copy and aren't tappable; all 4 real questions shown; the one real answer starts expanded; the other 3 show the SAME placeholder (never 3 different invented answers — checked by scanning the whole page for phrases a plausible fabricated answer would use); expand/collapse and exclusive-accordion behaviour; Resources open a coming-soon page |
| `test/change_password_test.dart` | `AuthService.changePassword` against a fake auth client that logs every call: the CURRENT password is verified (`signIn`) BEFORE `updateUser`; a wrong current password, a rate limit, a network failure or no session all mean `updateUser` is never called; server rejections land on the right field; ending other sessions is best-effort |
| `test/privacy_security_screen_test.dart` | The screen: the three disabled placeholders (off, no handler, Coming Soon, tapping does nothing); the password form (empty current rejected, each #10 rule's own message, same-as-current, mismatch — none reach the service; a valid form sends current + new; wrong current shown under its field); Delete Account (confirm → the RPC is called once and the local session ends; Cancel calls nothing; a failure shows a message, leaves the button available, and never ends the session) |
| `test/notification_prefs_test.dart` | Local preferences: design defaults (SMS off, rest on), values survive a simulated app restart, only changed keys are written, per-user isolation on a shared device — and a **transitive import check** proving the settings screen and its preferences import nothing that can reach the network (only `flutter/material` and `shared_preferences`) |
| `test/notification_settings_screen_test.dart` | The screen: every label/description, the design's initial state, a flip is shown at once and saved, toggles are as left after "closing and reopening", another user's choices don't show, a failed write reverts the switch, Done/back leave |
| `test/card_brand_test.dart` | Brand guess from the leading digits (Visa / Mastercard incl. the 2-series and its boundaries / Discover / generic), last four, and the `PaymentMethod` model's masked number and MM/YY label |
| `test/payment_methods_screens_test.dart` | Payment Methods list (real rows, Default badge, actions per card, empty / failed-load states, set default and delete each make ONE server request and the list then shows what the server returned — including a server that promotes a different card than a client would) and Add Payment Method (invalid card/expiry/CVV never reach the service; a valid card sends only brand + last4 + expiry, never the number or CVV; first-card / checkbox default handling) |
| `test/validators_test.dart` | Decision #10's phone rule (leading +, 8-15 digits, formatting stripped), password rule (8+ chars, upper + lower + number, each with its own message) and the name rule — all shared by Create Account and Edit Profile / Change Password |
| `test/avatar_service_test.dart` | Photo type/size validation (PNG/JPG/WebP, 5 MB boundary) and content types |
| `test/edit_profile_screen_test.dart` | Edit Profile with a fake service: values shown, email is not an input, invalid phone / blank name never reach the service, valid save sends trimmed name+phone only and returns the saved profile, no-change save skips the network, failures show a message, Cancel/back discard |
| `test/profile_content_test.dart` | Profile screen data mapping: real name/email/phone/member ID, badge follows the plan name, Valid Until format, hidden rows when a field is empty, retry state, every row/button callback, Sign Out disabled while signing out |

**What isn't unit-tested:** most screens (only the Profile content has widget tests), services that hit Supabase,
and all SQL. Those were verified **live** — through the real UI in Chrome and via
role-impersonated SQL in a rolled-back transaction — with each result written up
in `docs/decisions.md`. The working split: database/SQL verification is driven by
the assistant; app-level click-through is the developer's (#36).

---

## 14. Running, configuring, and handing off

**Run locally**
```bash
flutter pub get
flutter run -d chrome        # or an emulator/device; VS Code launch configs exist
flutter test
flutter analyze
```
`.vscode/launch.json` has "Rosewater Café (Chrome)" and "(Debug)" configs.

**Point at a backend** — edit **only** `lib/config/supabase_config.dart` (`url`,
`publishableKey`).

**Set up a fresh Supabase project**
1. Create the project; enable the `pg_cron` extension if the migration can't.
2. Apply `supabase/migrations/*.sql` in order (`supabase link` + `supabase db push`,
   or paste each into the SQL Editor). The initial schema is **fresh-project only,
   not idempotent**.
3. Authentication → decide "Confirm email" on/off; set the **password policy** to
   match the app's 8-char rule; configure **custom SMTP** for real email volume.
4. Verify function grants (`has_function_privilege('anon', …)` should be false).

**Before handing to the company** (collected from #13, #14, #4):
- Replace the personal-Gmail SMTP with a transactional provider (Resend,
  SendGrid, Postmark…).
- Replace the mocked payment with a real processor + **server-side** confirmation
  (webhook), not a client-triggered RPC.
- Run the migrations on *their* project and swap `supabase_config.dart`.
- Change the Android `applicationId` (currently the template
  `com.example.rosewater_cafe`) and bundle IDs before publishing.
- Clean up leftover test rows (`RLS_TEST_…` in `storage.objects`, stray
  `id_documents` rows, test users).

---

## 15. Known limitations and open questions

### Deliberate simplifications (training-project scope)
1. **Payment is mocked.** `confirm_subscription_payment` is triggered by the
   client tapping "Pay", so any authenticated user can activate their own pending
   subscription for free. Production needs a payment provider + server webhook
   (#4, #16). Staying mocked until the company supplies Stripe credentials.
2. **Static QR payload** (`member_id`). A photographed QR works forever; needs a
   short-lived signed token + a scanner-side verifier (#35).
3. **Event pricing** is a flat placeholder **$150/hour** (`c_price_per_hour` in SQL,
   `EventReservationService.pricePerHour` in Dart — both must change together).
   **Event types** are a fixed placeholder list (#33, #37).
4. **Reservations insert as `confirmed`** — there's no approval workflow (#36).
5. **Door access doesn't touch usage.** Nothing anywhere increments
   `hookah_used`/`drinks_used`; the app can't know what's consumed inside (#33).
6. **No usage-period renewal and no re-subscribe flow.** After 30 days a member
   simply lapses; there's no screen to renew and no job to create period 2 (#25).
7. **Mid-session expiry isn't live-reactive** — caught on next navigation/app
   open, by design (no Realtime) (#27).
8. **`status` can lag reality up to ~24 h**; always check `valid_until` too (§9.5).

### Known gaps
- **Biometric login, Two-Factor Authentication and Auto-Lock** are disabled placeholders (#45); **Privacy Policy / Terms of Service text** doesn't exist. **3 of 4 FAQ answers** are still unwritten (#46). **Dark Mode, Language, Animations, general UI Sound/Haptic** are visual-only (#5/#47). **Upgrade Membership and the Home bell's notifications feed** aren't built — Profile is otherwise fully built out (Profile's rows open stubs). **Forgot Password is now real, end to end, on Flutter Web** (#55) — request, email, deep-link, Set New Password screen, sign-in with the new password. **Changing the login email is now real too** (#57) — Privacy & Security's Email card, password-gated, with `profiles.email` kept in sync by a new server-side trigger. **Mobile (Android/iOS) deep-linking is not built** for either flow — the redirect URL and platform config (`AndroidManifest.xml`/`Info.plist`) are web-only right now; `SupabaseConfig.authRedirectUrl` is the one place to change when that's built.
- **PKCE code verifier** uses default plain-text storage — low risk until a
  magic-link/OAuth flow exists (#6).
- **Accounts created while email confirmation was ON stay unconfirmed** if it's
  later turned OFF; confirm them manually or recreate (decisions "Current status").
- **"Confirm email" is currently OFF** for the dev project; the app handles either
  state.
- **`member_id` in the QR + `RC-` format** is our own improvement over the Figma
  placeholder (#3).
- **Fidelity:** Onboarding/Auth screens weren't re-audited against the Figma API;
  the user reports mismatches as found (checkpoint after Sprint 2).
- **Task 6 conflict:** a requested "pending → Payment" resume on sign-in was
  skipped because it contradicts #22; the user chose to keep #22 (#24).

### Open questions for the company
Real event pricing and type list · full FAQ copy (only 1 of 4 answers exported) ·
what a "notification" is and whether it needs its own table/push delivery ·
whether notification preferences are server- or device-side · whether staff will
have a separate admin app for ID verification and door scanning.

---

## 16. Gotchas

- **Tests in the SQL Editor lie about RLS** — it runs as superuser (§10).
- **Migrations are manual.** Nothing applies them for you.
- **New enum values need their own migration file/transaction** (why `pending`
  has its own file).
- **`revoke … from public` doesn't lock out `anon` on Supabase** — always revoke
  from `anon` by name.
- **Duplicate sign-up doesn't error** once the email is confirmed — check
  `user.identities.isEmpty`.
- **`signUp()` may return no session** (email confirmation on) — always check
  before routing as "logged in".
- **Supabase's shared email limit** (`over_email_send_rate_limit`) is project-wide
  and hit even with confirmation off; use custom SMTP.
- **`DropdownButtonFormField` reads `initialValue` once** in newer Flutter — reset
  the `Form` or recreate the widget.
- **Sort direction:** pass `ascending: true` explicitly to `.order()`.
- **Flutter web scroll via browser automation:** CDP wheel/drag doesn't reach
  Flutter — dispatch a `WheelEvent` to `flutter-view` instead (#31).
- **Stale `dartvm.exe` holding a port on Windows** can wedge `flutter run`; kill
  the process on the port, not the `flutter.bat` wrapper (#15).
- **`google_fonts` fetches Inter at runtime** by default; bundle the font under
  `assets/` for offline/first-launch reliability if that matters.
- **`flutter_secure_storage` on web** is browser storage, not an OS vault — weaker
  than mobile. Fine for dev testing, worth remembering for a web release.
- **Two guest counts** (§7) — don't merge them.

---

## 17. Where to look for what

| I want to… | Go to |
|---|---|
| Change the first screen logic | `lib/screens/app_entry_point.dart` |
| Point at a different Supabase | `lib/config/supabase_config.dart` |
| Change plan prices / limits / perks | `membership_plans` rows (DB), not code |
| Change the event hourly price | `create_event_reservation` (`c_price_per_hour`) **and** `EventReservationService.pricePerHour` |
| Add a bottom-nav tab | `widgets/app_bottom_nav.dart` + `screens/home/main_shell.dart` |
| Build Upgrade Membership (Profile's last stub row) | new screen + a plan-change RPC (none exists yet) | replace the matching `_openComingSoon('…')` call in `screens/profile/profile_screen.dart` |
| Add a new secured write | New migration with an RPC following §9.5/§10 + a service with a Failure class |
| Change colors / gradients | `lib/theme/app_colors.dart` |
| Understand *why* something is the way it is | `docs/decisions.md` (search `#N`) |
| See the intended UI | `Rosewater Cafe 14012026/*.pdf` |
| Read the exact DB rules | `supabase/migrations/` (each file's header comment explains its reasoning) |

**Decision index (highlights of `docs/decisions.md`)**

| # | Topic | # | Topic |
|---|---|---|---|
| 1 | Signup order & password auth | 22 | Payment screen, nav bug, #17 reversed |
| 3 | Who can write what (security) | 23 | Payment success + full-loop verification |
| 4 | RPC pattern, mock-payment caveat | 24 | Resume-flow conflict; #22 kept |
| 6 | Encrypted session storage | 25 | Expiry cron + usage renewal deferred |
| 7–8 | Signup via metadata; double-submit | 26 | Bottom-nav shell |
| 9 | Live RLS proof; duplicate-signup decoy | 27–31 | Home cards (status, usage, actions, hours, benefits) |
| 10 | Stronger validation than Figma | 32 | Notification bell stub |
| 11–12 | Sign-in / forgot-password enumeration | 33 | Door-access vs usage; two guest counts |
| 13–14 | Email rate limit; custom SMTP | 34–35 | `log_door_access` + QR screen |
| 16 | `anon` execute bug | 36 | `create_event_reservation` + insert bypass |
| 17–19 | Choose Membership; Back to Plans | 37–38 | Reserve Event; Reservation Confirmed |
| 20–21 | Figma-API fidelity pass; features column | 39 | Sprint 4 decision checkpoint |
| 40 | Sprint 5 Task 1: Profile screen built to exact Figma values |
| 41 | Home rebuilt to the Figma frame; shared profile fetch |
| 42 | Sprint 5 Task 2: Edit Profile, avatars bucket, email lock |
| 43 | Sprint 5 Task 3: Payment Methods, DB-enforced default |
| 44 | Sprint 5 Task 4: Notification settings, local-only |
| 45 | Sprint 5 Task 5: Privacy & Security, real Change Password, Delete Account as a request |
| 46 | Sprint 5 Task 6: Help & Support, real FAQ answer + honest placeholders |
| 47 | Sprint 5 Task 7: App Settings, real cache management, rest visual-only |
| 48 | Sprint 6 Task 1: Change Password + Clear All App Data confirmed live |
| 49 | Sprint 6 Task 2: dead code audit (stub-era scaffolding + unused deps removed) |
| 50 | Sprint 6 Task 3: Figma fidelity re-check (hairline card borders fixed on 4 screens) |
| 51 | Sprint 6 Task 4: migration audit + proven empty-project replay (schema-identical) |
| 52 | Delete Account made real self-service (replaces decision #45's request queue) |
| 53 | Consolidated RLS/RPC security audit (sign-off); fixed event_reservations price-tamper gap |
| 54 | Hardened Delete Account: current-password re-check + storage cleanup before the RPC |
| 55 | Forgot Password completed (Set New Password screen, deep-link handling); two real live bugs found and fixed |
| 56 | "Remember me" made real: unchecked forces sign-out on next cold start (`AppEntryPoint`) |
| 57 | Change Login Email built: password-gated, Privacy & Security, `profiles.email` sync trigger |
| 58 | Sprint 8 Task 1: shared `SettingsProvider` foundation (not wired to any screen yet) |
