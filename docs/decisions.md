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
- Screens built so far: Onboarding (4 slides), Auth Landing, Create Account,
  Sign In, Forgot Password (all real, wired to Supabase, live-tested — see
  decisions #9, #11, #12). Home and Choose Membership are still placeholder
  stubs (`ComingSoonScreen`), now reachable directly from a cold app start
  when a session exists (decision #15), with a working Sign Out.
- **"Confirm email" is OFF again for this dev project** (reverted back from
  decision #14's "on" state — see decision #14's final update). A custom
  Gmail SMTP is still connected and does work when confirmation is on, but
  it was switched off again for now to remove the friction of confirming
  every test account; Create Account still correctly detects whether a
  session came back from signup either way (decision #9's fix), so nothing
  breaks if confirmation is turned back on later.
- **Known limitation, not yet fixed:** an account created *while*
  confirmation was required stays permanently unconfirmed even after
  confirmation is turned back off — turning the setting off only changes
  behavior for *new* signups going forward, it doesn't retroactively confirm
  existing rows. Any test account stuck in that state needs to be manually
  confirmed via the dashboard or recreated.
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

### 7. Signup: profile data travels as auth metadata, not a follow-up write

The original plan for Create Account was: call `supabase.auth.signUp(...)`,
then `.update()` the auto-created `profiles` row with the full name and
phone number. That has a real timing bug: **if the Supabase project has
email confirmation enabled (the default), `signUp()` does not return an
active session** — `auth.uid()` stays null until the user clicks the
confirmation link. Our `profiles` RLS policy requires `auth.uid() = id` to
update a row, so that follow-up `.update()` would run as an anonymous
request and fail RLS silently, leaving the profile with an empty name and
phone — while the signup itself still looks like it succeeded.

**Decision:** pass `full_name` and `phone` as signup metadata instead —
`supabase.auth.signUp(data: {'full_name': ..., 'phone': ...})` — and extend
the `handle_new_user` trigger (migration
`20260912130000_handle_new_user_phone.sql`) to read `phone` the same way it
already read `full_name`. Profile creation is then atomic with signup
itself (the trigger runs on `auth.users` insert, before any confirmation
step), so there's no second network call and no session-timing race to get
wrong.

**Also acted on, not just documented:**
- Client-side validation (email format, 8+ char password, password match,
  ToS checkbox) blocks bad submissions before any network call — verified
  directly: empty/weak/mismatched submissions never reached Supabase.
- Duplicate email is deliberately revealed as a clear inline error under the
  email field (the user's explicit call — normal UX, not an oversight).
- Password strength is enforced client-side for UX, but that alone isn't
  security — anyone can call the Supabase API directly and skip the Flutter
  form entirely. The project's own minimum-password-length policy
  (Dashboard → Authentication → Policies) is the real enforcement and should
  be kept in sync with the 8-character minimum shown in the form.

**Verified live against the real dev Supabase project:** confirmed
client-side blocking for empty/weak/mismatched submissions (no network
call), and confirmed the error-mapping path works for *any* real Supabase
error, not just the ones explicitly coded — an `@example.com` address was
rejected by Supabase itself (invalid domain) and Supabase's own signup rate
limit kicked in on a later attempt, and both surfaced as the actual
human-readable Supabase message rather than a generic failure. **Not yet
verified live:** a full successful signup reaching Choose Membership, and
the duplicate-email case specifically — both attempts were blocked by the
domain rejection and then the rate limit before getting that far. Worth
retrying once the rate limit cools down.

### 8. Follow-up security pass on Create Account — two real bugs found and fixed

A dedicated edge-case/security pass over the signup form (malformed input,
XSS-style input, password boundaries, rapid double-submit) surfaced two real
bugs, both fixed:

- **Double-submit race condition.** `_submit()` only disabled the button via
  `onPressed: _isSubmitting ? null : _submit` — but that closure is captured
  at the last *build*, and `setState` doesn't force an immediate rebuild
  before the next event is processed. A fast double-tap could invoke
  `_submit()` a second time, with the old (still-enabled) closure, before the
  button visually disabled — firing two concurrent `signUp()` calls with
  identical data. Fixed with a synchronous `if (_isSubmitting) return;` guard
  at the very top of `_submit()`, which works because Dart is single-threaded
  and the guard runs before any `await`.
- **Password errors from the server weren't shown anywhere.** The
  field-tagging design (`SignUpFailure.field`) already distinguished
  `'email'` from `'password'` errors, but `_submit()`'s catch block only
  wired up the `'email'` case — a server-side `weak_password` rejection
  (e.g. if the project's server-side password policy is ever stricter than
  our 8-character client check) would silently fall through to a generic
  SnackBar instead of appearing under the Password field where a user would
  actually look. Fixed by adding `_serverPasswordError`, mirroring the
  existing `_serverEmailError` pattern.
- Also added a catch-all for non-`AuthException` failures (dropped
  connection, timeout, DNS failure) — previously these would propagate
  uncaught, leaving the button stuck on "Creating account…" forever with no
  feedback, which reads as a hang.

**Verified clean, no code change needed:** XSS-style input
(`<script>alert(1)</script>` as the full name) renders as inert plain text —
Flutter's `Text`/`TextFormField` never interpret content as markup, so
there's no injection surface here the way there would be in a web app
directly writing HTML. Password matching is correctly case-sensitive
(`Password1` ≠ `password1`, both accepted as valid length but flagged as a
mismatch). The 8-character boundary is exact (7 fails, 8 passes).

**Real-world operational finding, not a code bug:** live signup testing hit
Supabase's own `over_email_send_rate_limit` — and importantly, this limit is
**project-wide, not per-IP or per-address**: it fired identically whether
tested from the Chrome browser or via `curl` directly against the GoTrue API
from a completely different network path. It's Supabase's shared free-tier
SMTP protecting itself from abuse, and it will keep getting hit during
ordinary development/testing (every teammate's signup attempts share the
same budget) until a custom SMTP provider is configured for the project, or
"Confirm email" is turned off for this dev project specifically (Dashboard →
Authentication → Providers → Email). Confirmed via a sign-in attempt against
a rate-limited address that no orphaned/partial user row gets created when
the limit blocks a signup — the rejection happens before anything is
persisted, so no cleanup is needed from the blocked attempts made during
testing.

### 9. Full live verification against the real dev project — one more real bug found and fixed

With "Confirm email" turned off for the dev project (later needed anyway —
see below) and using the user's real email/phone as live test data, the
whole signup path was finally exercised end to end against the actual
Supabase project, not just reasoned about:

- **Real signup succeeded correctly**: account created, `profiles` row
  populated with the exact `full_name`/`phone`/`email` passed in, routed to
  Choose Membership as required.
- **RLS enforcement confirmed live**, using the real user's own access
  token — not just designed on paper:
  - Tried to overwrite own `member_id` via a direct `PATCH` to `profiles` —
    the update touched the row (`updated_at` changed) but `member_id` came
    back unchanged, confirming the trigger's immutability guard works
    against a real authenticated request, not just in theory.
  - Tried to self-insert a `subscriptions` row (grant own membership),
    `usage_allowances` row (reset own usage), and `door_access_logs` row
    (fake a door entry) — all three rejected outright with
    `42501 row-level security policy violation`.
  - Uploaded an `id_documents` row (allowed, defaults to `pending`), then
    tried to `PATCH` its own `verification_status` to `verified` — the
    request "succeeded" (200) but matched and changed zero rows; re-fetching
    confirmed it was still `pending`. Self-verification is genuinely blocked.
  - A broad, unfiltered `SELECT` on `profiles` (no `WHERE` clause at all)
    returned only the user's own row, even though other test rows exist in
    the table — confirming RLS filters at the database level regardless of
    how the client queries, not just for the specific queries we expected
    people to write.

- **A second real bug, found only by testing duplicate signup against an
  actually-confirmed account:** Supabase does not throw an error for a
  duplicate signup once the email is confirmed — to prevent the signup
  endpoint being used to enumerate registered emails, it deliberately
  returns a **fake HTTP 200 with a decoy user** instead (different random
  id, `identities: []`). Our code only checked for a thrown `AuthException`,
  so a duplicate signup was silently treated as a success and routed straight
  to Choose Membership — directly violating the "duplicate email → clear
  inline error" requirement, and only surfaced by testing against a real,
  already-confirmed account rather than a fresh one.

  **Fixed** in `AuthService.signUp()`: after every signup call, if
  `response.user` is non-null but `user.identities` comes back as an empty
  list, treat it as the duplicate-email case (a genuinely new signup always
  has exactly one identity — the one just created). Re-verified live after
  the fix: the inline "An account with this email already exists" error now
  correctly appears under the Email field.

**Decision, acted on at the time:** "Confirm email" was turned off for this
dev project as a convenience, with a known gap flagged for later: Create
Account always navigated to Choose Membership on any non-throwing `signUp()`
result, without checking whether a session actually came back — fine while
confirmation was off (a session always comes back), but wrong the moment
confirmation is required.

**Update: confirmation ended up back on, and the gap got fixed for real.**
While setting up custom SMTP (decision #14), "Confirm email" was switched
back on — probably while on the same dashboard settings page — making this
gap live instead of theoretical. Fixed in
`AuthService.signUp()` (now returns `Future<bool>` reporting whether
`response.session != null`) and `CreateAccountScreen._submit()` (routes to
the new `ConfirmEmailPendingScreen` — no Figma design existed for this
state, built to match the other auth cards — when no session came back,
Choose Membership only when one did). Verified live: a fresh signup after
the SMTP fix returned `confirmation_sent_at` populated and no session,
correctly landing on the new pending-confirmation screen instead of Choose
Membership.

### 10. Stronger client-side validation than the Figma design specified

The Figma design's only stated password rule was "must be at least 8
characters" (the helper text under the field), and showed no explicit phone
format requirement. The user explicitly asked for more: real password
complexity and a required country code on the phone number, beyond what the
design called for.

**Decision:**
- **Password** now requires 8+ characters AND at least one uppercase letter,
  one lowercase letter, and one number (each missing requirement gets its
  own specific message, e.g. "Add at least one number", rather than a vague
  "too weak"). Worth knowing: current OWASP guidance actually leans the
  other way — favoring length over forced composition rules, since
  composition requirements tend to push people toward predictable patterns
  like `Password1!`. Implemented as asked anyway, since it's explicitly
  requested here, but flagging the tradeoff.
- **Phone** now requires a leading `+` and country code (e.g. `+1`, `+966`),
  rejecting bare local numbers like `5551234567`. Formatting characters
  (spaces, dashes, parentheses) are still allowed and stripped before
  validation, and the total digit count is checked against E.164's 8–15
  digit range.
- **Email** already required an `@` and a domain with a dot — verified via
  live testing in decision #8, this wasn't actually a gap — but the regex
  was upgraded to the standard HTML5 pattern for extra rigor (rejects
  malformed domains a looser check would miss).

As before, this is client-side UX only — the real enforcement for password
strength still needs to live in Supabase's own Auth password policy
(Dashboard → Authentication → Policies) so it can't be bypassed by calling
the API directly.

### 11. Sign In: generic credential errors, subscription-based routing, and "Remember me"

- **One generic message for every credential failure.** `AuthService.signIn()`
  maps wrong email, wrong password, *and* `email_not_confirmed` all to the
  same "Invalid email or password." — including the unconfirmed case, which
  Supabase actually reports distinctly from the API. Collapsing it too was a
  deliberate choice: showing it separately would let a login attempt reveal
  "this email is registered, just unconfirmed" versus "not registered at
  all," which is exactly the enumeration channel this requirement exists to
  close. The real cost: a legitimate user who forgot to confirm their email
  gets no hint why login fails, same accepted tradeoff as decision #9.
- **Routing after sign-in** checks for an active subscription
  (`SubscriptionService.hasActiveSubscription()`, RLS-scoped to the caller's
  own rows) — Home if one exists, Choose Membership if not. Verified live:
  a confirmed account with no subscription correctly lands on Choose
  Membership. **Not verified live:** the Home branch — there's currently no
  way to create an active subscription except direct DB access (the
  decision #4 RPC functions that would do this properly don't exist yet,
  and users can't self-insert one, by design). Worth testing once either
  exists.
- **"Remember me" is decorative for now.** Supabase persists the session
  on-device (via our encrypted `SecureLocalStorage`) regardless of this
  checkbox — which matches normal mobile-app behavior; staying signed in by
  default is what users expect from a mobile app, unlike a browser tab. If a
  real distinction is wanted later (e.g. force sign-out on next app launch
  when unchecked), that needs its own design: mobile OSes can kill an app
  process without ever firing an "on close" callback to act on, so it can't
  just be "call signOut() when the app closes."

### 12. Forgot Password: verified Supabase's own reset endpoint already hides account existence

**The problem to check:** the requirement was an identical "if that email
exists, we've sent a link" message regardless of whether the email is
registered — the one screen in the app that must actively hide account
existence, unlike decision #9 (signup deliberately reveals duplicates) and
decision #11 (sign-in hides it for credential errors).

**Verified directly against the live API before writing any code:** called
`/auth/v1/recover` with a real confirmed email, a clearly nonexistent email,
and an `@example.com` address — all three returned an identical `{}` HTTP 200.
Unlike `signUp()` (decision #9), Supabase's password-recovery endpoint needed
no decoy-detection logic of our own; it already never distinguishes "sent"
from "not registered." The only response that *does* differ is a genuinely
malformed email (`validation_failed`, HTTP 400) — safe to surface distinctly,
since malformed-email rejection doesn't correlate with whether any particular
*valid-looking* address has an account.

**Built:** `AuthService.resetPassword()` calls
`supabase.auth.resetPasswordForEmail()` and only ever throws
`ResetPasswordFailure` for a malformed email or rate limiting — never for "not
registered," since that path doesn't exist to check. `ForgotPasswordScreen`
shows one success state unconditionally whenever the call doesn't throw,
worded as "If an account exists for `<email>`, we've sent a link..." —
deliberately never "we sent a link to your account," which would confirm
the account exists.

**Verified live against the real dev project:**
- Submitting a nonexistent email (`definitely-not-a-real-account-xyz123@rosewatertest.com`)
  and a real registered email (the confirmed test account) produced
  byte-identical success screens — same icon, heading, and message structure,
  differing only in the email address echoed back.
- Network tab confirmed a real `POST /auth/v1/recover` call was made (not
  mocked), and a second immediate submission for the same address correctly
  hit Supabase's own rate limit (`429`, `over_email_send_rate_limit`) —
  surfaced as "Too many attempts," not a fake success. This is safe to show
  distinctly because the rate limit applies identically regardless of whether
  the address has an account.
- The first (non-rate-limited) request against the confirmed test account
  returned HTTP 200, meaning Supabase's mail pipeline actually attempted a
  send — final confirmation that the email physically arrived is pending the
  user checking that inbox, since checking a third party's email inbox isn't
  something available directly.

`flutter analyze` and `flutter test` both pass with no issues.

### 13. The shared dev-project email limit turned out to still block signup even with "Confirm email" off — custom SMTP is the real fix

Decision #8 assumed turning off "Confirm email" would stop signup from
hitting Supabase's shared `over_email_send_rate_limit`, since no
confirmation email should need to be sent. **That assumption was wrong.**
Live testing today showed:

- A brand-new, never-used email address still got `over_email_send_rate_limit`
  (429) on `/auth/v1/signup`, even with "Confirm email" off — Supabase
  appears to count/attempt an email-related action on signup regardless of
  whether confirmation is actually required.
- The password-recovery endpoint (`/auth/v1/recover`) behaves independently:
  after heavy testing in decision #12 exhausted it, a brand-new address
  worked again shortly after, while the *specific* address already tested
  minutes earlier still returned 429 — so recovery appears to combine a
  short global cooldown with a longer per-address cooldown (exact windows
  aren't published by Supabase, so treat both as "some number of minutes,
  not configurable by us on the free built-in mailer").
- Signup's limit, by contrast, stayed exhausted **project-wide** for every
  address tested, matching decision #8's original finding.

**Root cause:** this dev project still uses Supabase's own built-in,
shared testing SMTP — explicitly meant only for light local development,
not for the volume of live testing this project has been doing. Its caps
aren't documented with exact numbers or reset timers, and aren't
configurable from our side.

**The real, permanent fix:** connect a custom SMTP provider to this
Supabase project (Dashboard → Authentication → Settings → SMTP Settings /
"Enable Custom SMTP"). Once connected, Supabase sends through that
provider instead of its own limited shared service, and the strict
default cap no longer applies — subject only to whatever normal sending
limits the chosen provider has (typically far higher, e.g. 100+/day on
most free tiers). This requires dashboard access and a mail-sending
account (e.g. Gmail with an app password, or a free tier of
Resend/SendGrid/Mailgun) — an account-configuration step for whoever holds
the dashboard to do themselves, not something changeable from the app
code.

### 14. Custom SMTP got connected via personal Gmail — worth revisiting before handoff

Following on from decision #13, custom SMTP was configured using a personal
Gmail account (host `smtp.gmail.com`, port `587`, Gmail App Password).

**First attempt failed** with an HTTP 500 `unexpected_failure` /
"Error sending confirmation email" on every signup, reproduced directly
against the live API (not a client-side bug). The real cause was only
visible in **Supabase Dashboard → Logs → Auth Logs** (the API response
deliberately hides it) — the logged entry showed the actual SMTP rejection:

```
535 "5.7.8 Username and Password not accepted...
https://support.google.com/mail/?p=BadCredentials"
```

A Gmail-side authentication rejection — the credential Supabase sent
wasn't accepted, most likely from an incorrectly copied App Password (a
dropped character or stray space) or 2-Step Verification not being fully
enabled when it was generated. Regenerating a fresh App Password and
re-entering it carefully fixed it — a subsequent live signup returned
HTTP 200 with `confirmation_sent_at` populated, confirming Gmail actually
accepted and queued the email this time.

**Worth flagging honestly: using a personal Gmail account for this is a
fragile choice, not a recommended one**, even though it now works. The
app's ability to send signup/reset emails is currently tied to one
person's Google account — its 2-Step Verification staying enabled, its App
Password never being revoked, Google's own anti-abuse heuristics not
flagging it, and that person keeping access to the account at all. None of
that has anything to do with the app itself, so a real product should use
a dedicated transactional email provider (e.g. Resend, SendGrid, Postmark)
authenticated with a project-owned API key instead — this is a fix worth
revisiting before this project is handed off, not something to carry into
the company's real production project as-is. Documented here as a
deliberate, acknowledged shortcut for continued dev-project testing, not a
final recommendation.

**Also discovered along the way:** the reason signup broke at all despite
decision #9 turning "Confirm email" off — that toggle got switched back on
at some point while configuring the SMTP settings above (confirmed via
`GET /auth/v1/settings` showing `mailer_autoconfirm: false`). The user
initially chose to keep confirmation on and fix the SMTP credential properly
rather than just disabling confirmation again, since real email confirmation
matters for the app going forward — which is what made fixing the actual
Gmail credential (rather than the quicker workaround) the right call at the
time. It was later switched off again anyway to remove the friction of
confirming every test account during active development; the working SMTP
setup stays in place for whenever confirmation is turned back on. See the
Create Account fix logged at the end of decision #9 for the resulting
`ConfirmEmailPendingScreen` addition this required — it correctly handles
either setting, so toggling this back and forth doesn't break anything.

### 15. Task 8 — Session-aware routing on app start

**The requirement:** on app start, check for an existing Supabase session —
if valid, skip onboarding/landing entirely and route straight to Home or
Choose Membership based on subscription state; if not, show onboarding only
the first time, landing on every return visit after that. Force-closing and
reopening while signed in must not ask for sign-in again, and signing out
must return to Landing.

**Built:**
- `AppEntryPoint` (`lib/screens/app_entry_point.dart`) replaces
  `OnboardingScreen` as `main.dart`'s `home:`. On start, it checks
  `supabase.auth.currentSession` (already recovered/refreshed by
  `Supabase.initialize()`, which `main()` awaits before `runApp()`):
  session present → check `SubscriptionService.hasActiveSubscription()` and
  route to Home or Choose Membership; session absent → check a new local
  "has seen onboarding" flag and route to Onboarding or Auth Landing.
  Shows a brief loading spinner while these two async checks resolve.
- `OnboardingPrefs` (`lib/services/onboarding_prefs.dart`) — a thin
  `shared_preferences` wrapper for that flag. Deliberately local-only, not
  backend state: it's a per-device UI preference ("has this device's user
  seen the carousel"), not account data, and should still remember "seen"
  even while signed out. `OnboardingScreen._goToNextDestination()` (the one
  choke point both "Skip" and "Get Started" already went through) now marks
  it seen before navigating.
- `ComingSoonScreen` gained an optional `showSignOut` flag — Home and Choose
  Membership are the only destinations that pass it `true`, since a
  placeholder reached while already signed out (e.g. an old Forgot Password
  stub) has no session to sign out of. Signing out calls
  `supabase.auth.signOut()` then `pushAndRemoveUntil` to `AuthLandingScreen`,
  clearing the nav stack so the back button can't return to an authenticated
  screen afterward.

**Verified live**, in order, against the real dev project (a fresh
auto-confirmed test account, no active subscription):
1. Brand-new browser session (no session, onboarding never seen) →
   Onboarding, as required.
2. Skipping onboarding → Auth Landing → signed in → correctly routed to
   Choose Membership (no active subscription).
3. **Reloaded the page while signed in** (the direct equivalent of
   force-closing and reopening a mobile app) → landed straight back on
   Choose Membership, no sign-in prompt — the core acceptance criterion.
4. Tapped **Sign Out** → returned to Auth Landing.
5. Reloaded again after signing out → Auth Landing (not Onboarding again,
   confirming the "seen" flag persisted; not Choose Membership, confirming
   the session was genuinely cleared, not just navigated away from).

**Operational note, not a code issue:** mid-task, the local Chrome/Flutter
dev-server testing setup got into a broken state — a stale `dartvm.exe`
process from an earlier test session kept holding port 8765 after being
"stopped" (killing the `flutter.bat` wrapper PID doesn't kill the actual
native process it spawns on Windows), causing a new `flutter run` to either
fail to bind or, worse, leave the browser talking to a wedged old server
that rendered a blank page. Fixed by finding and killing the process
actually holding the port (`Get-NetTCPConnection -LocalPort ... | Stop-Process`)
rather than the shell-visible wrapper PID. Worth remembering for any future
"the app just won't load, no errors anywhere" situation in this dev setup.

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
