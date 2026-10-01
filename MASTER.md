# Rosewater Café — Project Guide

This document explains the whole project: what the app does, how it is built, how the pieces fit
together, and what is left to do. Start here.

---

## Contents

1. [What the app is](#1-what-the-app-is)
2. [What works](#2-what-works)
3. [What is not done yet](#3-what-is-not-done-yet)
4. [Tech stack](#4-tech-stack)
5. [Project structure](#5-project-structure)
6. [How the app starts and moves between screens](#6-how-the-app-starts-and-moves-between-screens)
7. [The screens](#7-the-screens)
8. [Services: how the app talks to the backend](#8-services-how-the-app-talks-to-the-backend)
9. [The backend (Supabase)](#9-the-backend-supabase)
10. [Security](#10-security)
11. [Notifications](#11-notifications)
12. [Languages, themes and fonts](#12-languages-themes-and-fonts)
13. [Testing](#13-testing)
14. [Running the app and handing it over](#14-running-the-app-and-handing-it-over)
15. [Where to find things](#15-where-to-find-things)

---

## 1. What the app is

**Rosewater Café** is a membership app for a VIP hookah lounge and café. Members pay a monthly plan
and use the app to get in, track what they've used, and book private events.

A member can:

- **Sign up**, pick a plan (**Basic**, **Premium** or **VIP**), upload an ID and pay.
- **Open the door** with a QR code and say how many guests are with them.
- **See their monthly allowance** (hookah sessions and drinks) on the Home screen.
- **Book a private event** (birthday, corporate, private party).
- **Get notifications** in the app, by email, and as reminders.
- **Manage their profile**, saved cards, notification choices, security and app settings.

The app is in **English and Arabic** (with full right-to-left layout), and has a **light and a dark
theme**.



## 2. What works

Everything below is built, connected to the real backend, and tested.

| Area | What it does |
|---|---|
| **Onboarding** | 4 intro slides, shown only on the first launch. |
| **Sign up / Sign in** | Email and password. Strong password and phone rules. "Remember me". |
| **Forgot password** | Reset email → link opens the app → set a new password (web). |
| **Choose membership** | Plans and prices come from the database, not the code. |
| **ID upload** | Photo or PDF of a government ID, stored privately. |
| **Payment** | Card form, or pay with a saved card. Optionally save the new card. *(Payment is simulated — see section 3.)* |
| **Upgrade membership** | Move to a more expensive plan from Profile. Hidden for VIP members (nothing higher). |
| **Home** | Membership status, hookah/drinks usage, quick actions, service hours, plan benefits, notification bell with unread count. |
| **Door access (QR)** | Shows the member's QR code. A guest counter limited by the plan. Logs each entry. |
| **Events** | Book an event (type, date, time, duration, guests, estimated price). Confirmation screen. |
| **Notifications** | List of notifications, mark as read, delete, view details. Live updates and an arrival sound. |
| **Email notifications** | Every notification can also be emailed (needs a Resend API key — see section 14). |
| **Event reminders** | Sent automatically 24 hours before a booked event. |
| **Low allowance alerts** | Sent when 3 or fewer hookah sessions or drinks are left. |
| **Profile** | Personal details, membership details, settings menu. |
| **Edit profile** | Change name, phone and photo. |
| **Payment methods** | Add, delete, set a default card (only brand, last 4 digits and expiry are stored). |
| **Privacy & security** | Change password, change email, delete account, biometric login, auto-lock. |
| **App settings** | Dark mode, animations, sound, vibration, language, cache, clear all data. |
| **Help & support** | Contact cards, FAQ, resources. |
| **Privacy Policy / Terms** | Draft text in English and Arabic (see section 3). |

---

## 3. What is not done yet

These are known and deliberate. They are listed so nothing comes as a surprise.

### Not built

| Item | Why / what's needed |
|---|---|
| **Real payments** | There is no payment processor yet. Pressing "Pay" activates the membership without charging anything. A real provider (for example Stripe) with server-side confirmation is needed before going live. |
| **Recording usage** | Nothing increases the hookah/drinks counters, because there is no staff or point-of-sale tool. Home always shows the full allowance, and allowance alerts can't trigger in practice. |
| **Staff / admin side** | Nobody can approve uploaded IDs, and there is no door scanner. The app only logs the member's "Open Door" tap. |
| **Membership renewal** | A membership simply ends after 30 days. The member has to subscribe again. |
| **Push notifications, SMS, promotions** | Their switches exist in Notification Settings but nothing uses them yet. |
| **Two-factor authentication** | Shown as "Coming Soon". |
| **French and Spanish** | Shown in the language list but disabled ("Coming Soon"). |
| **Downgrading a plan** | Only upgrades are supported. |

### Needs setup or has limits

| Item | Detail |
|---|---|
| **Emails** | Built, but need a Resend API key added in Supabase. Until a domain is verified, Resend only delivers to the account owner's own email. Emails are English only. |
| **Sign-up / reset emails** | Currently sent through a personal Gmail account. This should be replaced with a proper email service (Resend can do this too). |
| **Biometric login & auto-lock** | Built and unit-tested, but not yet tested on a real phone. |
| **Mobile email links** | Password-reset and email-change links are set up for the web version. A mobile build needs a custom URL scheme. |
| **QR code** | Contains the plain member ID. A real version should use a short-lived signed code. |
| **Café timezone** | Set to New York for event reminders. Change it if the café is elsewhere (one place, see section 14). |

### Placeholder content (needs the company's real text)

| Item | Detail |
|---|---|
| **Privacy Policy & Terms** | Draft text, **not written or reviewed by a lawyer**. Marked as a draft inside the app. Contains `support@example.com` and an empty "Governing Law" section. |
| **FAQ** | 3 of the 4 answers are drafts (the design only had one). Marked as drafts inside the app. |
| **Event pricing** | A flat $150 per hour. |
| **Event types** | Birthday / Corporate / Private Party / Other — not confirmed by the company. |

---

## 4. Tech stack

| Technology | What it's used for |
|---|---|
| **Flutter / Dart** | The app itself. One codebase for Android, iOS and web. |
| **Supabase** | The backend: user accounts, the PostgreSQL database, file storage, scheduled jobs, live updates. No separate server is needed. |
| **PostgreSQL** | Stores the data and also enforces the business rules (prices, limits, permissions), so the app can't be tricked. |

### Packages

| Package | What it's for |
|---|---|
| `supabase_flutter` | Talking to Supabase (sign-in, database, storage, live updates). |
| `flutter_secure_storage` | Keeps the login session in the phone's encrypted storage. |
| `shared_preferences` | Small settings saved on the device (theme, language, onboarding seen...). |
| `provider` | Shares the app settings with every screen. |
| `local_auth` | Fingerprint / Face ID for the lock screen. |
| `qr_flutter` | Draws the QR code. |
| `image_picker`, `file_picker` | Taking or choosing the ID photo/PDF and the profile photo. |
| `audioplayers` | Plays the notification sound. |
| `intl`, `flutter_localizations` | Translations, dates and numbers in English and Arabic. |

Fonts (**Inter** for English, **Noto Naskh Arabic** for Arabic) and the notification sound are bundled
inside the app in `assets/`, so they work offline.

---

## 5. Project structure

```
lib/
├── main.dart          Starts the app (Supabase, settings, theme, language)
├── config/            Supabase project URL and key (the only file to change for another project)
├── screens/           One folder per area of the app (auth, home, events, profile...)
├── services/          All communication with Supabase, one class per topic
├── models/            Plain data classes (Profile, MembershipPlan, AppNotification...)
├── widgets/           Reusable pieces (buttons, headers, logo, bottom navigation...)
├── theme/             Colours, text styles, light and dark themes
├── utils/             Small helpers (validators, translations of server data, time formatting...)
└── l10n/              English and Arabic text (app_en.arb, app_ar.arb)

assets/                Logo, fonts, notification sound
supabase/migrations/   The database, as SQL files applied in order
test/                  Automated tests
```

**Why it's organised this way:** each layer has one job. Screens only show things and react to taps.
Services are the only place that talks to Supabase. Models are plain data. This makes each part easy
to find, change and test on its own.

---

## 6. How the app starts and moves between screens

### Start-up (`main.dart`)

1. Start Supabase (with the session stored in encrypted storage).
2. Start listening for password-reset links **before** Supabase finishes starting. On web, the reset
   link is handled during start-up, so listening later would miss it.
3. Load the saved settings (theme, language, sound...) before showing anything, so the screen doesn't
   flash the wrong theme.
4. Show the app.

### First screen (`AppEntryPoint`)

```
Opened from a password-reset link? → Set New Password
Last sign-in didn't tick "Remember me"? → sign out first

Signed in?
├── No  → seen onboarding? → No: Onboarding / Yes: Welcome screen
└── Yes → active membership? → Yes: Home / No: Choose Membership
```

### The user journey

```
Onboarding → Welcome → Create Account → Choose Membership → ID Upload → Payment → Home
```

### The main app (`MainShell`)

After sign-in, the app has **4 tabs**: Home, QR Code, Events, Profile. The tabs are kept alive when
switching, so nothing reloads. The membership and profile are loaded once here and shared with all
tabs.

---

## 7. The screens

| Folder | Screens |
|---|---|
| `onboarding/` | The 4 intro slides. |
| `auth/` | Welcome, Sign In, Create Account, Forgot Password, Set New Password, "Check your email". |
| `membership/` | Choose Membership, ID Upload, Payment, Payment Success, Upgrade Membership. |
| `home/` | `MainShell` (the 4 tabs) and the Home tab. |
| `qr_access/` | Door access with the QR code and guest counter. |
| `events/` | Book an event, booking confirmed, reservation details. |
| `notifications/` | The notifications list. |
| `profile/` | Profile, Edit Profile, Payment Methods, Add Card, Notification Settings, Privacy & Security, App Settings, Help & Support, Privacy Policy, Terms of Service. |

Some screens were not in the design and were added in the same visual style: Payment Success,
Add Card, Reservation Details, "Check your email", and the empty/error states of lists.

---

## 8. Services: how the app talks to the backend

Every Supabase call goes through a service class in `lib/services/`. Screens never call Supabase
directly.

| Service | Responsible for |
|---|---|
| `AuthService` | Sign up, sign in, reset password, change password, change email. |
| `SubscriptionService` | Plans, starting / paying for / upgrading a membership. |
| `UsageService` | This period's hookah and drinks usage. |
| `ProfileService`, `AvatarService` | The profile and profile photo. |
| `IdDocumentService` | Uploading the ID document. |
| `PaymentMethodService` | Saved cards. |
| `DoorAccessService` | Logging a door entry. |
| `EventReservationService` | Booking and reading reservations. |
| `NotificationService` | Reading, marking read and deleting notifications. |
| `NotificationPrefs` | The user's notification switches. |
| `AccountDeletionService` | Deleting the account and all its files. |
| `SettingsProvider` | App settings on the device (theme, language, sound...). |
| `BiometricService` | Fingerprint / Face ID. |

**Common patterns:**
- Errors from the server are turned into a clear message the screen can show directly (for example
  "Your session expired. Please sign in again.").
- Services can be replaced by fakes in tests, so screens are tested without a real backend.

---

## 9. The backend (Supabase)

The whole database is defined in `supabase/migrations/`, applied in date order.

### Tables

| Table | Holds |
|---|---|
| `profiles` | Name, email, phone, member ID, photo. One per user. |
| `membership_plans` | Basic, Premium, VIP: price, limits, perks. |
| `subscriptions` | Each user's memberships (pending → active → expired / cancelled). |
| `usage_allowances` | Hookah and drinks used in each period, linked to its subscription. |
| `payment_methods` | Saved cards (brand, last 4, expiry, default). |
| `id_documents` | Uploaded IDs and their review status. |
| `door_access_logs` | Every door entry and guest count. |
| `event_reservations` | Booked events, with the price calculated by the server. |
| `notifications` | Notifications, with read/unread. |
| `notification_preferences` | Each user's notification switches. |

### Server functions

Anything involving money, limits or other users' data is done by a **database function**, not by the
app writing to the table directly.

| Function | What it does |
|---|---|
| `start_subscription` | Creates a pending (unpaid) membership. |
| `confirm_subscription_payment` | Activates it, starts the usage period, sends a notification. |
| `upgrade_subscription` | Moves to a more expensive plan (rejects cheaper or equal ones). |
| `cancel_subscription` | Cancels a pending (unpaid) membership. |
| `log_door_access` | Records an entry; checks the membership is active and the guest limit. |
| `create_event_reservation` | Books an event; checks guests (5–100) and date; calculates the price. |
| `delete_own_account` | Deletes the user and all their data. |

### Automatic jobs and triggers

| Name | When | What |
|---|---|---|
| `expire_subscriptions` | Daily | Marks ended memberships as expired. |
| `send_event_reminders` | Every 15 minutes | Sends reminders for events in the next 24 hours. |
| `check_low_allowance` | When usage changes | Sends a low-allowance alert. |
| `email_notification` | When a notification is created | Emails it through Resend. |
| `handle_new_user` | On sign-up | Creates the profile. |
| `generate_member_id` | On new profile | Creates the member ID (RC-000001...). |
| Payment card triggers | On card changes | Keep exactly one default card. |
| `sync_profile_email` | After an email change is confirmed | Updates the profile's email. |

### File storage

Two **private** buckets: `id-documents` and `avatars`. Each user can only reach their own folder.
Photos are shown through short-lived links.

---

## 10. Security

The main idea: **the database protects itself**. Even if someone bypasses the app and calls the API
directly, they can't do anything the app couldn't.

- **Row Level Security (RLS)** on every table: users can only see and change their own rows.
- **No direct writes to sensitive tables.** Memberships, usage, door logs, reservations and
  notifications can only be created through the server functions above, which do their own checks.
- **Prices and limits are checked on the server.** The app's own checks are only for convenience.
- **Exact permissions.** Each table only allows the actions the app actually needs. Signed-out users
  can't access any table.
- **Server functions** run with fixed settings, read the user's identity themselves (they never accept
  a user ID from the app), and can't be called by signed-out users.
- **Sensitive actions need the current password**: changing the password, changing the email,
  deleting the account.
- **No full card numbers or CVV are ever stored** — there's no column for them.
- **The login session** is stored in the phone's encrypted storage.
- **Sign-in and password reset never reveal** whether an email has an account.

---

## 11. Notifications

```
Something happens (payment, booking, upgrade, reminder, low allowance)
        │
        ▼
A row is added to `notifications` (by a server function)
        │
        ├──► Email (if "Email Notifications" is on and a Resend key is set)
        ├──► Live update to the app: bell badge + sound/vibration
        └──► Shown in the Notifications list, in the user's language
```

- Each notification stores its **facts** (plan, date, guests...) so the app can show it in English or
  Arabic, even after the user changes language.
- The user's switches in **Notification Settings** are stored in the database, so the server can
  respect them (for example, not sending emails).
- The arrival sound plays only if both the notification "Sound & Vibration" switch and the app's
  "Sound" setting are on.

---

## 12. Languages, themes and fonts

- **Languages:** English and Arabic. All text is in `lib/l10n/app_en.arb` and `app_ar.arb`. Arabic
  switches the whole app to right-to-left. Plan names (Basic, Premium, VIP) are not translated.
- **Themes:** light (pink/purple accent) and dark (navy background, blue accent). Colours come from
  `context.colors`, so every screen follows the active theme.
- **Fonts:** Inter for English and Noto Naskh Arabic for Arabic, both bundled in the app.
- **Logo:** `assets/images/logo.png`, with a dark-mode version where the hookah is light.

---

## 13. Testing

```bash
flutter test      # 342 automated tests, all passing
flutter analyze   # no issues
```

The tests cover validators, services (with fake backends), and most screens: what they show, what
happens when you tap, error states, English/Arabic, and right-to-left layout.

The database rules (security, functions, triggers) were tested directly on the Supabase project by
running each action as a real user and checking what was allowed and what was blocked.

---

## 14. Running the app and handing it over

### Run

```bash
flutter pub get
flutter run -d chrome --web-port=5000
```

### Set up a new Supabase project

1. Create the project.
2. Run every file in `supabase/migrations/` **in order** (Supabase CLI `supabase db push`, or paste
   each file into the SQL Editor).
3. Put the project URL and key in `lib/config/supabase_config.dart`.
4. In **Authentication → URL Configuration**, add the app's address to the Redirect URLs.
5. In **Authentication**, set the password policy to match the app (8+ characters, upper, lower,
   number), and choose whether email confirmation is on.

### Before going live

- [ ] Connect a real payment provider, confirmed on the server.
- [ ] Email: create a Resend account, add the API key in **Supabase → Integrations → Vault** as
      `resend_api_key`, verify a domain, and change the sender in `notification_email_from()`.
- [ ] Replace the Gmail used for sign-up/reset emails with Resend (Supabase → Authentication → SMTP).
- [ ] Check the café's timezone in `cafe_timezone()` (currently New York).
- [ ] Replace the draft Privacy Policy, Terms and FAQ answers with the company's real text.
- [ ] Set real event prices (`create_event_reservation` in SQL **and** `EventReservationService.pricePerHour`
      in Dart — they must match) and the real list of event types.
- [ ] Change the Android `applicationId` and iOS bundle ID (currently template values).
- [ ] Set up mobile deep links for password reset and email change.
- [ ] Test biometric login and auto-lock on real phones.
- [ ] New tables: Supabase gives every new table full permissions by default — limit them the same way
      as the existing tables.

---

## 15. Where to find things

| I want to... | Go to |
|---|---|
| Change the first-screen logic | `lib/screens/app_entry_point.dart` |
| Point the app at another Supabase project | `lib/config/supabase_config.dart` |
| Change plan prices, limits or perks | The `membership_plans` table (not the code) |
| Change the event price | `create_event_reservation` (SQL) and `EventReservationService.pricePerHour` |
| Change colours | `lib/theme/app_colors.dart` (palette) and `app_semantic_colors.dart` (light/dark roles) |
| Change or add text / translations | `lib/l10n/app_en.arb` and `app_ar.arb` |
| Change the logo | `assets/images/logo.png` (and `logo_dark.png`) |
| See the database rules | `supabase/migrations/` (each file explains itself at the top) |
| See the original design | `Rosewater Cafe 14012026/` |
