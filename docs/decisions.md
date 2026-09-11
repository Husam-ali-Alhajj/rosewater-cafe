# Rosewater Café — Decisions & Open Questions Log

This file exists because the company only handed over a Figma design (no written
spec, no task list). Some things in the design were ambiguous or missing
information. Where that happened, a decision was made so work could continue,
and it's recorded here — clearly marked as "we decided this because we didn't
have enough information," not as something the design actually specified.

Keep this file updated as new decisions get made or open questions get answered.

---

## Current status

- Database schema is fully designed and **the migration has been run** — all
  tables exist in the (personal, dev-only) Supabase project.
- The Flutter app is wired up to that Supabase project (`supabase_flutter`
  installed, client initialized in `main.dart`).
- Four shared UI widgets exist (`GradientButton`, `OutlinedSecondaryButton`,
  `OnboardingIconBadge`, `DotsIndicator`) matching the app's real theme colors.
- No screens have been built yet. We're working **one screen/feature at a
  time**, not building everything at once.
- Decision #4 below identifies a schema gap (subscription flow needs a
  `pending` status + two `SECURITY DEFINER` RPC functions) that hasn't been
  applied to the migration yet — planned as part of Sprint 1.
- The Supabase session is now stored encrypted on-device (`flutter_secure_storage`)
  instead of plain text — see decision #6.
- The dev Supabase project is temporary — at handoff, the company will get the
  SQL migration files to run on their own Supabase project, and only one
  config file (`lib/config/supabase_config.dart`) needs its URL/key swapped.

---

## Decisions made where the design was unclear or incomplete

### 1. Signup flow: which "Create Account" screen is real, and password vs. no password

**The problem:** the Figma export contains two different "Create Account" screens
that can't both be the real flow:
- A short form (name, email, phone, **password**, confirm password) — no plan
  selection, no ID upload.
- A longer flow: pick a membership plan → fill in details + **upload an ID
  document** → payment. This longer form has **no password field at all**.

There was no written spec to say which one is correct, or how an account
password gets set if the no-password flow is the real one (it could have meant
email/OTP login instead of a password).

**Decision:** use **password-based sign-up** (standard email + password via
Supabase Auth), matching the short form and the "Welcome Back / Sign In"
screen (which also expects a password).

**Working assumption, not yet confirmed by the company** — how the screens
combine: account creation (name/email/phone/password) happens first, and
*then* the user picks a membership plan, uploads their ID, and pays, before
landing on the home dashboard. This uses every screen from the design, in
sequence, rather than treating them as competing alternatives. **This is our
best guess, not a confirmed design decision — please double check with
whoever gave you the Figma file whether this is really the intended order,
and whether a user should be allowed to create an account without picking a
plan/paying right away, or if that must happen immediately.**

### 2. Membership plan pricing/limits

**No ambiguity here — confirmed correct**, just noting it: the design's plan
picker screen shows exact numbers, which is what got put into the database:

| Plan | Price | Hookah sessions | Drinks | Guests | Notes |
|---|---|---|---|---|---|
| Basic | $99/mo | 10 | 10 | 1 | |
| Premium | $199/mo | 20 | 20 | 2 | Marked "Most Popular" in the design |
| VIP | $399/mo | Unlimited | Unlimited | 2 | |

### 3. Who's allowed to write what in the database (security)

The design doesn't specify backend rules (it's just screens), so these were
decided based on what would make the app secure rather than what any specific
screen showed:

- **Membership status, usage counts (hookah/drinks used), and door-access
  history are read-only from the app.** A user's phone can *display* this
  data but cannot directly edit it. Otherwise, a user could grant themselves
  an active membership for free, reset their own usage limits, or fake a
  door-entry record. Actually writing this data will need a trusted
  server-side process later (e.g. a payment confirmation step, or whatever
  scans the QR code at the door) — not built yet, just reserved for later.
- **ID document verification status can't be self-approved.** A user can
  upload their ID, but only an admin/staff action can mark it "verified" —
  otherwise anyone could tick their own ID as verified without a real check.
  This matters if ID verification is tied to any legal/age requirement for
  the lounge.
- **Payment methods never store a full card number or CVV** — only the card
  brand, last 4 digits, expiry, and which one is the default. The design's
  payment screen shows raw "Card Number"/"CVV" fields; those will need to go
  through a real payment processor (e.g. Stripe) that turns the card into a
  safe token *before* it reaches our backend. **Not built yet — a separate
  task when we get to payments.**
- **Membership ID format:** the design's mock data shows a raw
  timestamp-looking number (e.g. `1768389549045`) as the "Member ID." We
  intentionally generate a human-readable one instead (e.g. `RC-000001`),
  assigned automatically and never changeable afterward. This is a
  deliberate improvement on the mock's placeholder-looking value, not a bug.

### 4. How the server-only writes from decision #3 actually happen (RPC functions)

Decision #3 said subscriptions/usage counts/door-access history are read-only
from the app. That raised a real question it didn't answer: if the app can't
write to `subscriptions`, what creates that row when a new member picks a
plan and pays? Leaving this unanswered would have meant hitting a dead end
mid-build, so it's worth settling now, before Sprint 1 starts.

**The pattern:** a `SECURITY DEFINER` Postgres function — a function that runs
with the permissions of whoever *created* it, not whoever *calls* it. A
regular signed-in user can call it (via `supabase.rpc('function_name', ...)`
from the app) and have it perform a write that their own account isn't
directly allowed to make, but only exactly the narrow, pre-approved action
written inside that function — never open table access. This is the standard
Supabase way to let a specific user action through a lock we deliberately put
up in decision #3, without removing the lock itself. The same pattern will be
needed later for `usage_allowances` (recording usage), `door_access_logs`
(logging a door scan), and `id_documents` (approving verification) — same
shape every time.

**Schema follow-up needed:** our `subscription_status` only allows
`active`/`expired`/`cancelled`. That's not enough — a subscription can't jump
straight to `active` before payment is confirmed. **A `pending` status needs
to be added to that enum** when this gets built.

**Two functions, not one, for subscriptions specifically:**
- `start_subscription(plan_id)` — called when the user picks a plan. Inserts
  the `subscriptions` row with `status = 'pending'`.
- `confirm_subscription_payment(subscription_id)` — called when the (mocked)
  payment screen's "Pay" button is tapped. Flips `status` to `active`, sets
  `started_at`/`valid_until`, and creates the user's first `usage_allowances`
  row for the current period.

**Important caveat to be upfront about — this is a training-project
simplification, not something to ship in production as-is:** because this
project has no real payment processor wired in, `confirm_subscription_payment`
is triggered directly by the client tapping "Pay." In a real production app,
that transition must instead be triggered by a trusted server that actually
verified the payment (e.g. a Stripe webhook calling our backend) — never by
the client itself asserting "the payment succeeded," since nothing here stops
a user from tapping the button without paying. That's an acceptable
simplification for a training project's scope, but it should be called out
as a known limitation whenever this gets explained, not left implicit.

**Two hardening details for when these functions actually get written:**
- Every `SECURITY DEFINER` function must pin `set search_path = public` in
  its definition — without it, there's a known Postgres attack where the
  caller manipulates the search path to trick the function into operating on
  attacker-controlled objects instead of the real tables.
- Postgres grants `EXECUTE` on a new function to `PUBLIC` by default, which
  (via Supabase's API) includes unauthenticated `anon` callers. Each function
  needs that default revoked and `EXECUTE` granted only to the `authenticated`
  role.

**Status: not yet implemented.** This is documented now so the design is
settled, but the enum change and the actual functions are Sprint 1 build work,
not applied to the schema yet.

### 5. Dark mode / language settings

The design's "App Settings" screen shows Dark Mode labeled "(Coming Soon)"
and a language picker (English/Arabic/French/Spanish) with only English
functional. **Decision: treat both as out of scope for now** — the toggle/list
can be shown for visual accuracy, but only light theme and English need to
actually work.

### 6. Secure client-side session storage — and a residual gap left open on purpose

By default, `supabase_flutter` saves the logged-in user's session (access +
refresh tokens) to `SharedPreferences`, which is **plain, unencrypted text on
disk** (an XML file on Android, a plist on iOS). Anyone with file access to
the device — a malicious app with the right permissions, a rooted phone, a
backup-extraction tool — could read it directly and act as that user.

**Decision:** replaced it with a custom `LocalStorage` implementation
(`lib/services/secure_local_storage.dart`) backed by `flutter_secure_storage`,
which writes into the OS's real encrypted vault instead (Android
Keystore-backed EncryptedSharedPreferences, iOS/macOS Keychain, Windows
Credential Locker). Wired in via
`Supabase.initialize(authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()))`.

Verified with an automated test (`test/secure_local_storage_test.dart`) that
fakes the OS storage layer and proves write → read → delete actually happens
through this class, since there's no login screen yet to click through
manually. Debug prints inside the class only ever log `true`/`false`
presence checks — **never the session content itself**, since printing the
real token would leak the exact secret this change exists to protect.

**Known gap, left open on purpose (smaller risk, out of scope for this task):**
Supabase Auth also stores a separate, short-lived value — the PKCE "code
verifier," used for OAuth/magic-link/email-confirmation-link flows — via its
own default (`SharedPreferencesGotrueAsyncStorage`), still plain-text. This
wasn't fixed here because the task was specifically about session storage,
and this value is lower-stakes than the session token (single-use, short-lived,
not an ongoing credential). If we later add magic-link, OAuth, or
email-confirmation-deep-link flows, the same fix (a custom `GotrueAsyncStorage`
passed as `pkceAsyncStorage`) should be applied then.

---

## Open questions still waiting on an answer from the company

These don't block current work, but will need real answers before the
related screens can be finished correctly:

1. **Signup flow order** (see decision #1 above) — please confirm this is
   right, and whether a plan/payment/ID upload is mandatory immediately after
   creating an account.
2. On the extended signup screen, the "Subscription Plan" field appears as an
   empty dropdown — is it pre-filled from the plan chosen on the previous
   screen, or does the user pick again there?
3. **Event reservation pricing** — the design shows a placeholder "$150/hour"
   base rate. What's the real pricing, and does it vary by event type (the
   "Event Type" field's actual options weren't visible in the export)?
4. **Full FAQ copy** — only 1 of 4 FAQ answers was visible/expanded in the
   design export; need the other 3 answers for the Help & Support screen.
5. **Notification preferences** (push/email/SMS toggles on the Notifications
   settings screen) — should these be saved per-user in the database, or is
   it fine for them to just be a local setting on the device with no backend?

---

## Working process

- The company gave us the Figma design only — no written spec or task list.
  We're creating our own task breakdown as we go.
- We work through one screen/feature at a time and confirm it's right before
  moving to the next, rather than building everything at once.
