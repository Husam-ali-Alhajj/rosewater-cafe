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
  Sign In, Forgot Password, Choose Membership, ID Upload, Payment, Payment
  Success (all real, wired to Supabase, live-tested — see decisions #9,
  #11, #12, #17, #18, #22, #23). **The entire signup → active-member loop
  (Sprint 2's whole point) is now verified live end to end with a
  brand-new account and zero mock data** — see decision #23. Home itself
  (the real dashboard) is Sprint 3 — still a placeholder stub
  (`ComingSoonScreen`), reachable both from a cold app start when a session
  exists (decision #15) and from the new Payment Success screen. Sign out
  currently only exists on that stub screen — Choose Membership/ID
  Upload/Payment/Payment Success deliberately have none, matching the
  design; it'll live on a future Settings screen instead (decision #21).
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
- Decision #4's schema gap (subscription flow needs a `pending` status + two
  `SECURITY DEFINER` RPC functions) is now implemented and live-verified —
  see decision #16.
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

**Confirmed correct by the company:** account creation (name/email/phone/
password) happens first, then the user picks a membership plan, uploads
their ID, and pays, before landing on the home dashboard — this is the
order the company actually specified, not just our best guess anymore.

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

**Status: implemented in Sprint 2, Task 1** — see decision #16 below for what
actually got built, a real bug found while verifying it, and how it was
fixed.

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

### 16. Sprint 2, Task 1 — Subscription `pending` status + the two-RPC pattern, and a real anon-execute bug found while verifying it

Built exactly what decision #4 planned, plus one more piece decision #4 didn't
call out: `confirm_subscription_payment` also has to insert the user's first
`usage_allowances` row — without it, a newly-active member has no usage row
for Home to read. Two migrations (kept separate deliberately — see below):

- `20260914090000_add_pending_subscription_status.sql` — adds `pending` to
  `subscription_status`, ordered before `active`. On its own in a migration
  file/transaction by itself: Postgres forbids using a brand-new enum value
  (e.g. in an index predicate) within the same transaction that added it, and
  the next migration's partial unique index needs `pending` already committed.
- `20260914090100_subscription_two_rpc_pattern.sql` — `start_subscription(plan_id)`
  and `confirm_subscription_payment(subscription_id)`, both `SECURITY DEFINER`,
  both pinning `set search_path = public`, both reading `auth.uid()` internally
  rather than accepting a `user_id`/caller-supplied identity (so a caller can
  never act on someone else's row). Also added: a partial unique index
  (one pending row per user) as a race-condition guard, and `confirm_...`
  inserting the first `usage_allowances` row.

**Two user-facing decisions made explicitly with the user, not assumed:**
- If `start_subscription` is called while the user already has a `pending` or
  `active` row, it does **not** silently cancel/replace anything — it
  `RAISE EXCEPTION`s a fixed, machine-readable message
  (`pending_subscription_exists` / `active_subscription_exists`) with the
  existing row's id/plan/valid_until in `DETAIL`, so the app can catch it and
  ask the user what to do (resume vs. cancel). No UI for that decision exists
  yet — this just makes it possible later.
- `confirm_subscription_payment` has no real payment gateway behind it yet
  (documented, accepted as a known Sprint 2 gap, same caveat as decision #4).

**A real vulnerability found only by testing with actual role impersonation,
not by reasoning about the SQL:** the SQL Editor's "Run" button executes as
the `postgres` superuser, which bypasses RLS entirely. Testing "does a raw
insert fail" *in that editor* would have been a false pass. Correctly
impersonating the real `authenticated`/`anon` roles (via
`set local role ...; set local request.jwt.claims = '...'`) inside an
explicit `begin; ... rollback;` block was necessary to prove anything real:

- Raw `insert into subscriptions ...` as `authenticated` → correctly
  `42501 row violates row-level security policy` (no INSERT policy exists).
- `start_subscription` / `confirm_subscription_payment` as `authenticated` →
  worked end-to-end, including the `usage_allowances` row appearing.
- `start_subscription` as `anon` → **executed the function body** (only
  failing on its own internal `auth.uid() is null` check), instead of being
  refused at the permission level. Root cause: `revoke execute ... from public`
  is not enough on Supabase — its platform grants `EXECUTE` on every new
  function directly to `anon`/`authenticated`/`service_role` as separate ACL
  entries the moment it's created, and `REVOKE ... FROM PUBLIC` only removes
  the generic "everyone" grant, not those already-existing per-role ones.
  **Fixed** by adding an explicit `revoke execute ... from anon` on both
  functions (both live, via the SQL Editor, and in the migration file for any
  future fresh deploy) — re-verified afterward: `anon` now gets a real
  `42501 permission denied for function`, and `pg_proc.proacl` shows only
  `postgres`/`authenticated`/`service_role`, no `anon`.

**Worth remembering for any future `SECURITY DEFINER` function in this
project:** always explicitly revoke from `anon` by name — never assume
`revoke ... from public` alone locks out unauthenticated callers on Supabase.

### 17. Sprint 2, Task 2 — Choose Membership screen, real data

Built the real "Choose Your Membership" screen (`lib/screens/membership/
choose_membership_screen.dart`), replacing the `ComingSoonScreen` stub
everywhere it was reached from (`AppEntryPoint`, `SignInScreen`,
`CreateAccountScreen`).

**Decided with the user, not assumed:**
- The Figma design's bullet lists include perks with no backing database
  column at all (seating tier, 24/7 access, private booth, event priority,
  exclusive menu). Rather than hardcode them per plan name — which would
  silently drift from the real plan data and partially defeat the point of
  this task — bullets are generated only from real `membership_plans`
  columns: hookah/drinks limits, guest count, plus a static "Member
  discounts" line true for every plan. Less rich than the mockup, zero
  hardcoded plan-specific copy.
- If the user backs out of ID Upload (or force-closes/reopens) while a
  pending subscription already exists, the screen skips the cards entirely
  and resumes straight into ID Upload with that same `subscription_id` —
  never re-showing the plan picker mid-checkout. Implemented via
  `SubscriptionService.findPendingSubscription()` checked on screen load,
  and (for the in-session back-button case specifically) navigating to ID
  Upload with `Navigator.push(...).then((_) => ...)` that immediately
  re-enters the same destination with the same id rather than letting the
  cards become tappable again. This is what actually satisfies "back
  navigation doesn't create a duplicate" — not any extra check inside
  `start_subscription` itself (Task 1's RPC already refuses a duplicate
  regardless, but relying on that alone would surface as a raw error the
  user has no way to resolve yet).

**Per-tier icon/gradient colors (gray/Basic, purple/Premium, pink-red/VIP)
are estimated from the PDF export, not confirmed via Figma's Design panel**
— flagged the same way decision #6's colors were pulled with real inspection
and these weren't; worth a real hex check later.

**A real bug caught only by looking at the rendered screen, not by reading
the code:** `fetchPlans()` called `.order('price_cents')` expecting ascending
(cheapest first, matching the design), but cards actually rendered VIP →
Premium → Basic — descending. Worse, the per-tier icon/gradient was assigned
by row rank, so the wrong visual treatment landed on the wrong plan (VIP got
Basic's gray star). **Fixed** by passing `ascending: true` explicitly rather
than relying on the client library's default. Re-verified live in the
browser after the fix: Basic (gray star) → Premium (purple sparkle, "Most
Popular" badge) → VIP, in that order.

**Verified live end-to-end**, using a fresh signup
(`husamalhaj46+task2test@gmail.com`, no prior subscription):
1. Cards rendered from the live `membership_plans` table (not hardcoded),
   correct order, correct "Most Popular" badge on Premium (from `is_popular`,
   not a hardcoded index).
2. Tapping "Select Basic" called `start_subscription`, landed on the ID
   Upload stub showing a real `subscription_id`, confirmed directly in the
   database: exactly one row, `status = 'pending'`, correct `plan_id`.
3. Pressing back from ID Upload re-entered ID Upload with the *same*
   `subscription_id` — the cards never reappeared. Re-checked the database
   afterward: still exactly one row, no duplicate.
4. Fully reloaded the app (simulating force-close/reopen) with that pending
   row still in the database — landed straight back on ID Upload with the
   same id, cards never shown, confirming the resume path also works on a
   cold start, not just an in-session back button.

**Known limitation, not yet built:** ID Upload itself is still the shared
`ComingSoonScreen` stub (now carrying `subscription_id` forward via an
optional `subtitle` parameter added to that widget) — real ID Upload is a
later task.

### 18. Sprint 2, Task 3 — ID Document upload, and not re-asking for name/email/phone

The design's "Create Your Account" screen (Figma page 9) re-asks for Full
Name/Email/Phone/Subscription Plan alongside the ID upload control. Per
decision #1, those were already collected at real account creation in
Sprint 1 — re-asking risks a mismatch between what's in `profiles` and
whatever gets typed here for no reason. **Decision:** this screen (renamed
"Verify Your Membership" — "Create Your Account" no longer describes what
it does) shows name/email/phone as read-only, pulled from the user's own
`profiles` row, and the plan as read-only too, pulled from the subscription
the user just started. Only the ID upload control is interactive.

Built `IdUploadScreen` (`lib/screens/membership/id_upload_screen.dart`),
`ProfileService.fetchCurrentProfile()`, and
`SubscriptionService.fetchPlanForSubscription(subscriptionId)`. The screen
takes only `subscriptionId` as input (not a passed-through profile/plan
object) and fetches both itself — so it behaves identically whether reached
by a fresh plan selection or by Choose Membership resuming a pending
subscription on a cold start (decision #17's resume path).

**Upload control:** a bottom sheet offers Take Photo / Choose from Gallery
(`image_picker`) or Choose File — PNG/JPG/PDF (`file_picker`, added as a new
dependency since `image_picker` can't handle PDFs). `IdDocumentService.validate()`
checks extension and size (10MB, per the design's stated limit) against just
the file's name/size — never its bytes — immediately after picking, before
`uploadAndRecord()` is ever called. Confirmed with a dedicated unit test
suite (`test/id_document_service_test.dart`, 8 cases: each allowed extension,
exactly-at-limit, one-byte-over, disallowed extension, no extension,
case-insensitivity) rather than fighting a real file dialog for this part —
see the testing note below for why.

**verification_status forced to pending — this was already built in Sprint 1
and needed confirming, not implementing.** `id_documents`' insert policy
(`with check (auth.uid() = user_id and verification_status = 'pending')`,
from `initial_schema.sql`) already rejects any other value outright — the
client-side upload code simply never sends the field at all (relying on the
column's own `default 'pending'`), so there's no path from this client to a
non-pending row. Verified live with real role impersonation (same method as
decision #16): as the real `authenticated` role, inserting with
`verification_status = 'verified'` → `42501 row violates row-level security
policy`; inserting with the field omitted → succeeds, lands as `pending`.

**Storage isolation verified live, not just read off the policy text:**
inserted a stand-in `storage.objects` row for one test user's folder
(`f261f109.../RLS_TEST_other_user_file.png`), then, impersonating a
*different* signed-in user, tried to read it — `0 rows`. Impersonating the
actual owner — `1 row`. Proves the storage RLS policies
(`(storage.foldername(name))[1] = auth.uid()::text`) actually isolate reads
per user, not just per-bucket. **That test row is still sitting in
`storage.objects`** (named `RLS_TEST_...` so it's obviously not a real
document) — needs a human-run `delete from storage.objects where name like
'%RLS_TEST_other_user_file.png'` to clean up, same as the decision #16
cleanup pattern (deletion is a harness-blocked action for the assistant).
Also left over from testing: one real `pending` row in `id_documents` for
`husamalhaj46+task2test@gmail.com` (`storage_path` doesn't point to a real
uploaded file, since the live upload click-through — see below — never
completed) — harmless, but worth knowing it's there.

**Testing note — the live "pick a file and click Continue" path could not
be verified end-to-end via browser automation:** Flutter web renders the
whole UI to a `<canvas>`; the accessibility tree the browser-automation
tooling relies on to target a file input showed nothing but a generic
"enable accessibility" node, both before and immediately after triggering
`file_picker`'s hidden `<input type="file">`. Two attempts to locate and
drive that input came back empty. Validation logic was proven with unit
tests instead, and the two security-critical requirements (forced-pending,
storage isolation) were proven directly against the database with real
role impersonation.

**Update: manually verified by the user afterward — a real file upload
went through correctly.** The gap above was specifically about automated
testing in this dev environment, not the feature itself; it's confirmed
working end to end now.

**Also fixed while testing:** `GradientButton` gave no visual indication
when `onPressed` was null — "Continue to Payment" looked fully active even
with no file picked yet. Not a new bug (every screen using this button had
the same gap), just newly visible because this is the first button that's
disabled by default rather than only briefly during a submit. Fixed with a
0.5 opacity + dropped shadow when disabled, in the shared widget so every
screen using it benefits.

### 19. Real bug found by the user: "Back to Plans" didn't go back to plans

**Reported by the user:** signing in to an existing account went straight to
Verify Your Membership instead of Choose Membership.

**Diagnosis:** not actually a routing bug — that account genuinely had a
`pending` subscription already sitting in the database, and decision #17's
resume behavior (approved earlier) is working exactly as designed: if a
pending subscription exists, Choose Membership skips the cards and goes
straight to ID Upload. The real bug was underneath that: **"Back to Plans"
on Verify Your Membership didn't do anything.** `ChooseMembershipScreen`'s
`_goToIdUpload` re-pushed ID Upload on *any* pop, with no way to tell "user
hit hardware back" (should re-enter, preserving the anti-duplicate
protection) apart from "user deliberately tapped a button labeled 'Back to
Plans'" (should not). Since nothing could cancel a pending subscription,
every path bounced back to the same screen — "Back to Plans" was a label
with no working action behind it.

**Decision, made with the user:** tapping "Back to Plans" cancels the
pending subscription (a real, deliberate action, not silent) and shows the
cards fresh.

**Built:**
- `cancel_subscription(subscription_id)` — a new RPC
  (`20260915100000_cancel_subscription.sql`), same security pattern as the
  other two (`SECURITY DEFINER`, `search_path` pinned, `auth.uid()` read
  internally, `EXECUTE` revoked from `PUBLIC` *and* explicitly `anon` from
  the start this time, per decision #16's lesson). Restricted to
  `status = 'pending'` only — this must never be able to cancel an
  already-active paid subscription.
- `IdUploadScreen._backToPlans()` calls it, then pops with `Navigator.pop(true)`
  — the `true` is what lets the parent tell a deliberate cancel apart from
  an ordinary pop.
- `ChooseMembershipScreen._goToIdUpload`'s `.then()` now branches on that
  result: `true` → re-run `_init()` (finds no pending subscription now, and
  actually shows the cards); anything else (hardware back, system gesture)
  → re-enter ID Upload as before, keeping decision #17's protection intact.

**A second real bug found immediately while testing the first fix:** after
cancelling and returning to the cards, the just-selected plan's button was
stuck showing "Selecting…" and disabled. `_selectingPlanId` gets set right
before the original push and is never cleared on the way back, since
`push` (not `pushReplacement`) keeps the same `State` object alive the
whole time. Fixed by clearing `_selectingPlanId` (and `_errorMessage`)
alongside `_loading` in the same branch.

**Verified live end-to-end**, twice, using `task2test`: select a plan →
lands on Verify Your Membership → tap "Back to Plans" → cards reappear
fully interactive (not stuck on "Selecting…") → confirmed directly in the
database each time: the just-created `pending` row flips to `cancelled`,
no orphaned rows left over (final check: 3 rows for that user, all
`cancelled`, zero `pending`).

**Not touched:** the reporting user's own real pending subscription
(`husamalhaj47@gmail.com`) was left exactly as found — verification used a
separate test account instead, specifically to avoid changing state on an
account the user was actively using themselves. They can now use "Back to
Plans" themselves if they want a different plan than the one already
pending.

### 20. Real Figma API access — Choose Membership and Verify Your Membership rebuilt against exact design data, not estimates

The user provided a Figma personal access token, which unblocks something
decisions #17/#18 had explicitly flagged as a gap: every color used on the
membership screens was **estimated from the PDF export**, not read from the
actual Figma file. With API access, pulled the real node data directly
(`GET /v1/files/:key/nodes?ids=...` for node `1213:1030` — "Choose Your
Membership" — and `1213:1183` — "Create Your Account", i.e. Verify Your
Membership) and compared every color, font size/weight, spacing value, and
corner radius against what was actually built. Found real, concrete
mismatches, not just imprecision:

- **Every tier gradient was the wrong hex.** Basic was `#6B7280→#374151`,
  should be `#99A1AF→#4A5565`; Premium was `#A855F7→#7C3AED`, should be
  `#C27AFF→#9810FA`; VIP was `#F43F5E→#E11D48`, should be `#FF637E→#EC003F`.
- **The "Most Popular" badge was the wrong shape and fill entirely** — built
  as a fully-rounded pill with a two-color gradient; Figma specifies a
  rounded rectangle (`radius: 8`, not a stadium shape) with a **solid**
  fill (`#9810FA`, no gradient).
- **Cards had an invented 0.9 opacity** and no border at all on the two
  non-highlighted cards (Figma: solid white, `1px #E5E7EB` border); the
  highlighted card's border color was the wrong end of the gradient
  (`#9810FA` used, should be the lighter `#C27AFF`).
- **Text sizes/weights were systematically off** because generic shared
  styles (`AppTextStyles.heading1`/`heading2`/`body`) were reused across
  elements that Figma actually gives distinct treatments: the page title is
  36px/weight 500 (was rendered 24px/bold), the price is 36px/weight
  400/color `#101828` (was rendered as a bold 24px heading), card button
  labels are 14px (was the global 18px CTA size), bullet text color is
  `#364153` (was the app's general `textDark`), the checkmark green is a
  brighter `#00C950` (was the app's muted `success` green).
- **Major spacing was much tighter than the design** — Figma's card gives
  48px of breathing room between the icon/name/price block, the bullet
  list, and the button; this was built at 16px throughout.
- **Verify Your Membership had invented content and wrong alignment**: an
  extra subtitle line ("Confirm your details...") that doesn't exist in
  Figma at all, and a centered heading where Figma's is left-aligned. The
  read-only fields' input styling (fill `#F3F3F5`, thin border, 24px gap
  between fields — was 16px) and the upload box (fill `#F9FAFB` not
  `#F3F4F6`, border `#D1D5DC` not black12, icon color `#99A1AF` not
  `textMuted`) were also off.

**Fixed:** `AppColors` gained exact-hex membership constants
(`membershipBasicGradient`/`membershipPremiumGradient`/`membershipVipGradient`,
`membershipPopularBadge`, `membershipCheckmark`, `membershipPremiumBorder`,
`membershipCardBorder`, `membershipListText`, `membershipPriceText`,
`membershipPriceSuffix`) replacing the old PDF-estimated ones.
`GradientButton` gained optional `height`/`fontSize` params (default
48/18, unchanged for every other already-correct button) since Figma
genuinely uses two different button sizes — full-width CTAs vs. compact
in-card buttons — that a single fixed size couldn't represent.
`ChooseMembershipScreen` and `IdUploadScreen` were rewritten with literal
inline styles matching the exact Figma values above, rather than reusing
the shared `AppTextStyles` constants (which weren't touched, to avoid
changing the look of already-approved screens — Sign In, Create Account,
etc. — that weren't re-verified in this pass).

**Deliberately NOT changed:** the DB-only bullet list (decision #17) and
the "Verify Your Membership" heading text instead of "Create Your Account"
(decision #18) — both were explicit prior decisions with the user, and
this pass was about visual fidelity (color/type/spacing), not re-opening
content decisions already made.

**Not yet done:** the user asked about "some other pages" beyond these
two specifically-named ones. This pass only re-verified Choose Membership
and Verify Your Membership — the earlier screens (Onboarding, Auth
Landing, Sign In, Create Account, Forgot Password) were not re-checked
against the Figma API in this pass and may have similar drift, since they
were originally built the same estimated way before this API access
existed.

### 21. Two more real gaps found by the user after decision #20's pass: missing perk bullets, and an invented Sign Out button

Two concrete reports, both correct:

- **The design shows more bullets than the app did.** Decision #17
  deliberately limited bullets to what real `membership_plans` columns
  could derive (hookah/drinks/guests + "Member discounts"), leaving out
  the design's non-DB perks (seating tier, weekend/24-7 access, private
  booth, event priority, exclusive menu) rather than hardcode them.
  Correct call at the time given no column existed for them — but the
  user is now explicit that full design fidelity matters more than
  avoiding that column, superseding decision #17 on this specific point.

  **Fixed:** added a real `features text[]` column to `membership_plans`
  (`20260915120000_membership_plan_features.sql`) rather than hardcoding
  the copy in the Flutter widget — keeps Task 2's original goal (no
  hardcoded plan data in the app) while also matching the design exactly.
  Seeded verbatim from the Figma node data pulled in decision #20: Basic
  gets `['Standard seating', 'Member discounts']`, Premium gets
  `['Priority seating', 'Weekend access', 'Member discounts']`, VIP gets
  `['Private booth', '24/7 access', 'Event priority', 'Exclusive menu']`
  — note VIP's list deliberately does **not** include "Member discounts"
  the way Basic/Premium's do, because Figma's own VIP card bullet list
  doesn't either (the footer note covers it for every plan instead).
  `MembershipPlan.featureBullets` now appends `features` after the three
  numeric bullets. Verified live: all three cards show the full bullet
  set now, matching the design panel-by-panel.

- **Neither Choose Membership nor Verify Your Membership has a Sign Out
  button in the design** — that button was something added during
  Sprint 2 build-out (for a real, if undocumented, reason: without it,
  there was no way to sign out once past Auth Landing until Home/Payment
  existed as stub screens). Since the user explicitly flagged it as not
  matching the design, removed it from both screens entirely, along with
  the now-unused `_signOut` methods and their imports.

  **Known consequence, said plainly rather than left implicit:** there is
  currently no way to sign out from within Choose Membership or Verify
  Your Membership at all — the nearest sign-out path is now several
  screens away (the `ComingSoonScreen` stubs for Home/Payment still have
  one). This matches the design as given, but is worth a real answer
  eventually: presumably sign-out belongs on a Settings/Profile screen
  once one exists, the same way most real apps handle it, rather than
  being sprinkled on every authenticated screen the way the Sprint 2
  stopgap did.

### 22. Sprint 2, Task 4 — Mock Payment screen, a real navigation bug it exposed, and reversing the auto-resume behavior from decision #17

Built the real "Complete Payment" screen (Figma node 1213:1281,
`lib/screens/membership/payment_screen.dart`) using the same exact-Figma-data
approach as decision #20. Plan name/price come in via constructor from
`IdUploadScreen`'s already-fetched state — this screen makes zero database
reads of its own. Card Number/Expiry/CVV are validated client-side purely
for realistic shape (`lib/utils/payment_validators.dart`, unit-tested: 19
cases covering the 16-digit/MM-YY/3-digit boundaries and the expiry-in-the-
past check) and are never sent anywhere: not to Supabase, not logged, no
`autofillHints` (so the OS/browser never offers to save a fake card),
controllers explicitly cleared and disposed. "Pay" calls
`confirm_subscription_payment(subscription_id)` — the same RPC decision #16
already hardened and verified.

**Verified live, by the user, on their own real account:** tapped Pay,
confirmed directly in the database that the subscription flipped to
`active` with `started_at`/`valid_until` set correctly (30 days out) and a
`usage_allowances` row was created — the actual acceptance criteria, not
just "the screen appeared to work."

**A real bug this surfaced: paying successfully bounced back to a
membership screen instead of landing on Home.** Root cause:
`ChooseMembershipScreen` pushes `IdUploadScreen` and has a `.then()`
callback on that push to decide what to do when it's popped (re-enter it,
or refresh after "Back to Plans" cancelled the subscription). It didn't
account for a third case: `PaymentScreen`'s success path calls
`pushAndRemoveUntil` to clear the *entire* stack down to Home, which also
completes `IdUploadScreen`'s "pop" future — and because Flutter can
complete that future as a microtask before actually disposing the popped
route's State (which can wait for the next frame), `ChooseMembershipScreen`'s
stale callback fired with `mounted == true` and blindly re-pushed ID Upload
right after a successful payment. First fix attempt made the callback
re-verify against the database before resuming (defensive, but still
assumed resuming was ever the right default).

**Decision, made with the user, that removed the need for that whole
mechanism:** decision #17's "skip the cards, auto-resume straight into ID
Upload if a pending subscription already exists" behavior is **reversed**.
Signing in (or landing on Choose Membership at all) now always shows the
plan cards, full stop — no silent redirect past them. Actual duplicate
prevention still lives where it always did regardless: `start_subscription`'s
own `pending_subscription_exists` check (decision #16) — re-selecting a
plan while one is already pending now surfaces as a clear inline error
message on the cards screen itself, rather than the user never seeing the
cards at all. This let `_goToIdUpload` collapse back down to a plain
`push().then()` that just clears the "Selecting…" state on return,
regardless of *why* the pop happened — no more guessing, no more
re-querying the database defensively. `findPendingSubscription()` and the
now-unused `PendingSubscription` class were deleted from
`SubscriptionService` rather than left as dead code.

**Also found and cleaned up while investigating this:** a DevTools Network
tab full of `.dart.lib.js` file requests, which the user flagged as a
possible leak — confirmed these are just Flutter web's normal debug-mode
module loading (one JS file per Dart source file, unminified, because this
is `flutter run` not a release build), not a data leak. No card fields
ever appeared in any request body; the network tab evidence for that
specifically is filtering to Fetch/XHR and inspecting the
`confirm_subscription_payment` RPC call's payload, which contains only
`p_subscription_id`.

### 23. Sprint 2, Task 5 — Payment success screen, and the full loop verified end to end

No Figma frame exists for a dedicated "payment success" screen — searched
the entire file via the API for "member"/"congrat"/"welcome"/"success"/
"payment successful" text; the only hit is a notification list item on the
Notifications screen ("Payment Successful... Your monthly subscription has
been renewed"), not a standalone confirmation page. The task itself frames
this as a temporary placeholder ahead of the real Home Dashboard (Sprint
3), so `PaymentSuccessScreen` was built to match the app's existing visual
language (same card/gradient/button treatment as every other screen in
this flow) rather than inventing an unrelated look or forcing a nonexistent
design match.

Takes `plan` via constructor from `PaymentScreen`'s own already-known
state — the last hop in a chain that started with Choose Membership's real
`fetchPlans()` call — so this screen, like every screen before it in the
flow, makes zero database reads and has zero hardcoded plan data. "Continue"
routes to the Home `ComingSoonScreen` stub via the same
`pushAndRemoveUntil` pattern `PaymentScreen` already used.

**Verified live, end to end, by the user, with a brand-new account** (not
a resumed/pre-seeded one — this exercised every step from real signup
onward): Create Account → Choose Membership → ID Upload → Payment →
confirmation screen. Checked directly in the database afterward:

- `profiles`: real `full_name`, a freshly auto-generated `member_id`
  (`RC-000030`) — confirms signup and the member-ID trigger both ran for
  real, not against seeded data.
- `subscriptions`: `status = 'active'`, `started_at`/`valid_until` 30 days
  apart, matching `confirm_subscription_payment`'s contract exactly.
- `usage_allowances`: a row exists for the same period.
- `id_documents`: `verification_status = 'pending'` (correctly forced, per
  decision #18 — never self-approved) with a real `storage_path` from an
  actual uploaded file.

No hardcoded or mock data anywhere in this path — the only intentionally
"fake" data in the whole flow remains the Payment screen's card fields
(decision #22), which are discarded client-side by design and never touch
the database at all.

### 24. Sprint 2, Task 6 — Resume-flow correctness conflicts with decision #22; keeping #22

Task 6 as given asked for three sign-in states: no subscription → Choose
Membership, **pending → Payment** (so someone who picked a plan but closed
the app before paying resumes straight at the payment step instead of
"restarting at Choose Membership, which would risk creating a second
pending subscription"), active → Home.

The middle case directly contradicts decision #22, made one task earlier:
Choose Membership always shows the plan cards on sign-in, with no silent
redirect past them for any state (none or pending) — the auto-resume
behavior Task 6 is literally asking for was removed on purpose after it
caused a real navigation bug (see #22). Rather than silently pick one,
this was flagged to the user directly as a conflict between the new task
and the immediately preceding decision.

**User's explicit choice: keep decision #22, skip this requirement.**
Sign-in still always shows Choose Membership's cards regardless of pending
state. Recorded here rather than implemented so that whoever gave us Task
6 can be told plainly: this specific requirement conflicts with an
explicit decision made two tasks ago, rather than us quietly overriding
either one.

**Verified current behavior for all three states, in both routing entry
points** (`SignInScreen._submit` and `AppEntryPoint._resolve`, which share
the same two-way `hasActiveSubscription()` check):

- **No subscription** → Choose Membership (shows cards).
- **Pending** → Choose Membership (shows cards) — *not* Payment. This is
  the one place Task 6's literal text and current behavior diverge.
- **Active** → Home (`ComingSoonScreen`).

Task 6's other concern — "check Task 2's duplicate-prevention logic" — is
confirmed still intact and unaffected by this decision either way:
`start_subscription`'s own `pending_subscription_exists` check (decision
#16) still runs server-side on every call, RPC-level, regardless of what
the client does before calling it. Re-selecting a plan while one is
already pending surfaces the existing inline error message on the cards
screen (`StartSubscriptionErrorCode.pendingSubscriptionExists`, "You
already have a membership request in progress.") rather than creating a
second row. Nothing about this decision touches or weakens that check.

No dangling references to the deleted `findPendingSubscription()` /
`PendingSubscription` (removed in decision #22) were found in either
routing entry point — both were already re-read in full to confirm this.

### 25. Pre-Sprint-3 — subscription expiry job (built) and usage_allowances renewal (deferred)

Raised before starting Sprint 3 because Home is the first screen that
actually *reads* `subscriptions`/`usage_allowances` instead of just
writing them once — two existing gaps become visible the moment it's
built, rather than staying invisible the way they have been so far.

**Gap 1 — nothing ever flipped `status = 'active'` to `'expired'` once
`valid_until` passed.** `hasActiveSubscription()` only checked `status =
'active'`, so a subscription from months ago with no renewal would show
as active forever. Decided to actually fix this now rather than log it as
a gap, since it's cheap and Home depends on it being right: two pieces,
covering two different failure modes.

- **A scheduled job that flips the stored status for real**
  (`supabase/migrations/20260916090000_expire_subscriptions_cron.sql`):
  `expire_subscriptions()`, `SECURITY DEFINER` with `search_path` pinned
  (same pattern as every other function in this project), scheduled via
  `pg_cron` to run daily at 03:00 (`cron.schedule('expire-subscriptions-
  daily', '0 3 * * *', ...)`, wrapped in an unschedule-then-schedule `do`
  block so rerunning the migration doesn't create duplicate jobs). Unlike
  `start_subscription`/`confirm_subscription_payment`/`cancel_subscription`,
  this function is **not** a per-user RPC — it updates every user's rows
  in one pass, not just the caller's — so `EXECUTE` is revoked from
  `authenticated` as well as `anon`/PUBLIC. No client role should ever be
  able to invoke it directly; only pg_cron's own scheduled run (as the
  database owner, outside PostgREST) does.
- **Defense in depth in `hasActiveSubscription()` itself**
  (`lib/services/subscription_service.dart`): now checks `status =
  'active' AND valid_until > now()`, not status alone. A once-a-day cron
  job means a row can sit with a stale `'active'` status for up to ~24h
  after its real expiry — the client-side `valid_until` check makes every
  live read correct immediately regardless of whether the job has run
  yet. The cron job's own job is to keep the *stored* data honest for
  anything that reads status directly without this extra check (future
  admin views, reporting) — the two aren't redundant, they cover different
  readers.

**Known, accepted limitation:** raw `status` in the `subscriptions` table
can lag reality by up to ~24h between a subscription's real expiry and
the next 03:00 cron run. Fine for a training project; dropping to hourly
is a one-line schedule-string change if it ever needs to be tighter. Any
code that reads `status` without also checking `valid_until` (there
isn't any right now, but future admin/reporting screens might) should be
aware of this lag.

**Applied and verified live** in the Supabase SQL editor (this migration
doesn't run itself — same as every other migration in this project, it
had to be pasted into the dashboard and run by hand): `cron.job` now has
a real row (`jobid = 1`, `jobname = 'expire-subscriptions-daily'`,
`schedule = '0 3 * * *'`, `command = 'select public.expire_subscriptions()'`,
`active = true`), and `has_function_privilege()` confirms `expire_subscriptions`
is `SECURITY DEFINER` (`prosecdef = true`) with both `anon` and
`authenticated` unable to execute it directly (`anon_can_execute = false`,
`authenticated_can_execute = false`) — matching the migration file exactly,
not just written to disk and forgotten.

**The defensive `valid_until` check was additionally proven to work
independently of the cron job**, not just asserted: inside a single
`begin; ... rollback;` transaction against a real active subscription
(never committed, so no live data was actually touched) —

1. Backdated that row's `valid_until` to yesterday, simulating a lapsed
   subscription the (real, live, correctly-scheduled) daily cron job
   hasn't run against yet.
2. Impersonated the owning user (`set local role authenticated; set local
   request.jwt.claims = '{"sub":"<their-id>","role":"authenticated"}'`).
3. Ran the OLD status-only shape of the query — confirmed it would still
   have returned this row as active (the exact bug being fixed).
4. Ran `hasActiveSubscription()`'s actual NEW query (`status = 'active'
   and valid_until > now()`) as the same impersonated user — returned
   `new_defensive_check = 0`, i.e. correctly reports not-active
   immediately, with zero dependency on whether cron has run yet.
5. `rollback` — re-queried the same row afterward outside any
   transaction and confirmed `valid_until` is back to its real original
   value, so this test left no trace on live data.

This is the proof the acceptance criteria asked for: the defensive check
is what actually blocks a lapsed member from reaching Home the moment
`valid_until` passes, not the cron job (which only exists to keep the
*stored* `status` column honest for anything that reads it without the
same defensive check).

**Gap 2 — no renewal mechanism exists for `usage_allowances`.** The first
period's row is created once, inside `confirm_subscription_payment`, at
initial payment — there is no "start of next 30-day period" job that
creates period 2. **Deliberately deferred, same bucket as the Stripe gap
(decision #4/#16), not built:** a renewal job only has meaning once
something exists for it to serve, and nothing does yet — there's no
auto-recurring billing (payment here is a one-time manual "Pay" tap, not
a subscription-with-retries) and no "resubscribe after lapsing" screen or
flow for an expired member to trigger a new period at all. Building a job
to silently create period-2 rows now would be inventing data against a
repurchase flow that hasn't been designed. Logged plainly instead: no
mechanism exists yet for a lapsed member to resubscribe, and therefore no
`usage_allowances` renewal job exists either; building one is premature
until a resubscribe flow is designed. Revisit together when that flow is
built.

### 26. Sprint 3, Task 2 — Bottom nav shell (Home / QR Code / Events / Profile)

Built the persistent 4-tab bottom navigation bar every authenticated
screen from here on lives inside — `lib/widgets/app_bottom_nav.dart` for
the bar itself, `lib/screens/home/main_shell.dart` as the `IndexedStack`
shell that hosts the four tab bodies and owns the selected index.

**Styling pulled directly from the Figma `BottomNav` component (node
1216:2285)**, via the REST API, the same way decision #20 did for the
membership screens — not eyeballed: white background, 1px top border
(`#E5E7EB`, same hex already named `AppColors.membershipCardBorder`), 24px
outline-style icons, 12px labels, muted gray (`#6A7282`, already named
`AppColors.membershipPriceSuffix`) for inactive tabs vs. bold + a new
`AppColors.bottomNavActive` (`#EC003F`) for the active one, and a small
4px accent-colored dot beneath the active tab's icon — the icon itself
sits 4px higher on the active tab to make room for it, which is exactly
why the design's own layout numbers work out (confirmed by measuring the
active/inactive Button node coordinates directly, not guessed).

Icons are standard Material `_outlined` glyphs chosen to match each Figma
vector's shape, same approach as every other icon in this app so far (no
custom SVGs): `home_outlined`, `qr_code_outlined` (the Figma vectors are
literally a 4-corner-square QR finder pattern), `calendar_today_outlined`,
`person_outline`.

**One deliberate, documented deviation from the Figma frame:** its tabs
hug their own label width inside a fixed 375px mock (different width per
tab, with gaps). Built as `Expanded` equal-width tabs instead — a
content-hugging nav bar would look wrong the instant a real device isn't
exactly 375px wide, so this trades exact-pixel match for correctness at
arbitrary screen widths, the same kind of tradeoff decision #20 already
established a precedent for elsewhere in this app.

**Sign Out moved from the old flat Home placeholder onto the Profile
tab.** Every prior destination for "the authenticated app" (`SignInScreen`,
`AppEntryPoint`, `PaymentSuccessScreen`) pushed a bare
`ComingSoonScreen(label: 'Home', showSignOut: true)` — that's gone now,
replaced by `MainShell()` in all three places. Home's own tab is still a
`ComingSoonScreen` stub this task (Home's real content is next), but
without Sign Out; Profile's stub tab has it instead
(`showSignOut: true`), since Profile is the natural interim home for it
per decision #21 ("sign out belongs on Settings/Profile, not sprinkled
elsewhere") — closer to the real design intent than a bare Home screen
ever was, even while Profile itself is still just a stub.

**Verified live**, not just by static analysis: `flutter analyze` (clean,
same 3 pre-existing unrelated lint infos) and `flutter test` (29/29)
first, then actually ran the app (`flutter run -d web-server`) and drove
it through Chrome — created a fresh throwaway test account
(`task2.bottomnav.20260916@gmail.com`), selected Basic, then fast-forwarded
its subscription straight to `active` with a direct SQL update (this task
is only about the nav shell, not re-testing the payment RPCs already
verified in decisions #16/#22/#23, so skipping ID Upload/Payment's UI here
was deliberate scope, not a shortcut around something this task actually
needed to prove). Reloaded to go through the real
`AppEntryPoint` → `hasActiveSubscription()` → `MainShell` path, then
clicked all four tabs in sequence (Home → QR Code → Events → Profile →
back to Home): each switch rendered its stub instantly, no crash, no
stuck state, Home correctly active by default, Profile correctly showing
"Sign Out" top-right. Zoomed screenshot confirmed the active-tab dot
indicator and accent color match the Figma component exactly.

### 27. Sprint 3, Task 3 — Membership status card (real data), and the mid-session-expiry question

Built the real membership status card on Home (`lib/screens/home/home_screen.dart`),
replacing that tab's `ComingSoonScreen` stub from decision #26. Plan name
and valid-until date come from a new `SubscriptionService.fetchActiveMembership()`
— a single query joining `subscriptions` to `membership_plans(name)`,
using the exact same `status = 'active' AND valid_until > now()` defensive
check as `hasActiveSubscription()` (decision #25), not a looser one. No
hardcoded plan data or dates anywhere in this screen.

**Styling pulled directly from the Figma `MemberDashboard` → `Card`
component (node 1217:3576)**, via the API, same as every other screen
this sprint: purple gradient (`#C27AFF → #9810FA`, corner radius 14,
1px border black-at-10%-opacity, the same two-layer drop shadow the node
itself specifies), a translucent white "Active" badge (white-at-20%-opacity
fill, white-at-30%-opacity border, radius 8), "Membership Status" label,
"{Plan} Member" heading, "Valid until: M/D/YYYY" — that exact date format
(no leading zeros) is what the Figma text itself shows.

**One judgment call worth flagging:** this card's gradient is a fixed
purple regardless of which plan the member is actually on -- it happens
to be the exact same hex pair as `membershipPremiumGradient`, reused
rather than duplicated. The Figma file only has one instance of this
card to go on (using demo data labeled "premium Member"), so there's no
second data point to confirm whether a Basic or VIP member's card should
use a different tier gradient instead. Treated the single instance as the
intended universal Home-dashboard accent (consistent brand color for
"you're a member," independent of tier) rather than assuming per-tier
color-coding was intended but just unshown. Worth confirming if a second
Figma instance with a different plan ever surfaces.

**The mid-session-expiry question, decided as proposed:** since Task 1
made expiry a real possibility while a session is already open (not just
at sign-in), the open question was whether the status card needs to react
live if a subscription expires while the user is already sitting on
Home. **Accepted: no** -- "catch it on the next navigation or app reopen"
is good enough for this project; real-time reactivity would mean wiring
up Supabase Realtime for a rare edge case with no real cost to the
business if it lags by one session. Logged here as the decision, not
defaulted into silently.

That said, Home does not blindly trust it was only ever reached with a
genuinely active membership: **`HomeScreen` re-runs the same defensive
check itself** and, if `fetchActiveMembership()` finds nothing, immediately
`pushAndRemoveUntil`s to `ChooseMembershipScreen` instead of rendering a
broken or stale card. This is belt-and-suspenders on top of the identical
check already gating entry to `MainShell` at sign-in and app start
(decision #25) -- not a substitute for live reactivity, just insurance
against ever silently showing "Active" when the data underneath says
otherwise, for any reason.

**Verified live, both paths, through the real UI** (not just SQL):
using the same test account from decision #26 (`task2.bottomnav.20260916@gmail.com`,
Basic plan, active) --

- **Happy path:** signed in through the real Sign In screen. Home
  rendered the real card: "Basic Member", "Active" badge, "Valid until:
  10/15/2026" -- matching the database exactly, not a placeholder.
- **Bounce path:** backdated that same account's `valid_until` to
  yesterday via SQL (simulating expiry), then signed out via the Profile
  tab's Sign Out button and signed back in through the real form --
  landed directly on Choose Membership, never showing Home or any stale
  "Active" data at all. Confirms both the entry gate (decision #25) and
  this task's own acceptance criterion in one pass.

### 28. Sprint 3, Task 4 — Usage progress (hookah sessions, drinks), and how "Unlimited" is actually stored

Added the two usage stat cards below the membership status card on Home.
`used` comes from a new `UsageService.fetchCurrentUsage()` (real
`usage_allowances` row, most recent `period_start`); `limit` comes from
`ActiveMembership`, extended this task to also carry `hookahLimit`/
`drinksLimit` from the same `membership_plans` join `fetchActiveMembership()`
already does for the plan name -- one query, not two, since the plan row
was already being fetched.

**How "Unlimited" is actually stored, checked directly rather than
assumed:** `membership_plans.hookah_limit`/`drinks_limit` are nullable
`integer` columns, and VIP's seed row (`20260912120000_initial_schema.sql`)
sets both to SQL `NULL` -- not a sentinel like `-1` or `0`. This is the
same convention `MembershipPlan.featureBullets` already relies on
(`hookahLimit == null ? 'Unlimited Hookah' : ...`), so Task 4 follows the
established pattern instead of inventing a second one: `limit == null` is
checked explicitly before any arithmetic ever touches it, both in
`ActiveMembership` (typed `int?`, matching `MembershipPlan`) and in the
card widget itself, which branches on `null` before computing a fraction
-- there is no code path where `used / limit` can run with a null
denominator (Dart wouldn't compile that anyway, but the equivalent bug in
a looser language, or a lazy `limit ?? 0` that then divides by zero, is
exactly the "15/null" this task called out to guard against). When
`limit == null`, the card shows "Unlimited" in place of the "{used} /
{limit}" line and renders no progress bar at all -- not a fake full/empty
bar, since neither would be true. The "{used} used this month" caption
still renders either way; that number stays meaningful on its own even
without a cap to measure it against.

**Styling pulled directly from the Figma `MemberDashboard` usage `Card`
nodes** (1217:3615 hookah, 1217:3633 drinks), via the API: white-at-90%-
opacity card, black-at-10%-opacity border, radius 14, a 48px circular icon
badge per stat (peach `#FFEDD4` bg / orange `#F54900` flame icon for
hookah, light-blue `#DBEAFE` bg / blue `#155DFC` glass icon for drinks),
label in `textMuted`, the "{used} / {limit}" value in `textDark` at 24px,
caption in `membershipPriceSuffix` at 12px. **One thing NOT taken
literally from the raw Figma data:** the two progress-bar-fill node
geometries in the file both report a fill width equal to the full track
width regardless of the demo's own used/limit numbers (5/20 and 2/20) --
a strong signal this design was imported from a coded (shadcn/ui, given
the literal `Primitive.div` node names and the exact `#030213` "foreground"
token showing up as both the track-at-20%-opacity and the solid fill
color) React app via an HTML-to-Figma plugin, where the fill's true width
came from an inline CSS percentage the plugin's static bounding-box
capture didn't reproduce correctly. Trusting that geometry literally
would have made every bar render at 100% regardless of real usage, which
would fail this task's own acceptance criterion outright -- so the actual
fill fraction is computed the only way that could ever be correct,
`(used / limit).clamp(0.0, 1.0)`, while the colors that *did* extract
consistently (`#030213` for both track and fill) were kept exactly.

**Verified live, both the proportioned-bar case and the unlimited case,
through the real UI** (not just SQL), reusing the decision #26/#27 test
account:

- **Basic plan, real numbers:** inserted a real `usage_allowances` row
  (this account's subscription had been created via decision #26's SQL
  shortcut, which bypasses `confirm_subscription_payment` and therefore
  never created one -- a real payment always would) with
  `hookah_used = 6, drinks_used = 3` against Basic's `10`/`10` limits.
  Signed in through the real form: "Hookah Sessions 6 / 10" with its bar
  visibly ~60% filled, "Drinks 3 / 10" at ~30% filled, both captions
  correct -- proportion is visibly different between the two bars, not
  just present.
- **VIP, unlimited:** switched that same subscription's `plan_id` to VIP
  via SQL (VIP's `hookah_limit`/`drinks_limit` are the real `NULL`s from
  the schema, not test-only data) and reloaded. Both cards correctly
  showed "Unlimited" with no progress bar, and the "used this month"
  captions still rendered normally (6 / 3, unchanged from the underlying
  usage row) -- no crash, no "15/null", no fake bar.

### 29. Sprint 3, Task 5 — Quick actions ("Access Café" / "Reserve Event")

Added the two quick-action buttons below the membership status card
(Figma node 1217:3587, between it and the usage cards -- matching the
design's own vertical order, which also meant fixing the inter-section
gap between the status card and what's below it from 16px to the actual
24px the Figma frame uses throughout, measured directly off the section
coordinates rather than eyeballed; the two buttons themselves keep their
own 16px gap).

**Both are stubs this task, exactly as asked:** "Access Café" and
"Reserve Event" don't push a new screen -- they switch [MainShell] to its
QR Code / Events tab, which are themselves still `ComingSoonScreen`
placeholders until Sprint 4 (QR Code) and Events' own task build them for
real. Getting the user there is this task's entire job.

**How that navigation actually works, since Home is a tab, not a pushed
route:** `HomeScreen` doesn't reach for a `Navigator` here -- there's
nothing to push to, QR Code and Events are sibling tabs of the same
`MainShell` Home already lives inside. `MainShell` now passes `HomeScreen`
two callbacks (`onGoToQrCode`, `onGoToEvents`) that call the same
`_goToTab` method its `AppBottomNav.onTap` already used, so tapping a
quick-action button and tapping the corresponding bottom-nav icon do the
literal same thing. This is also why `MainShell`'s `_tabs` list stopped
being `static const`: a bound instance method closure can't be a
compile-time constant, so it's now built once in `initState` instead --
still built once, not per rebuild, just no longer eligible for `const`.

**Styling pulled directly from the Figma `Button` nodes**: "Access Café"
uses this app's real primary gradient (`AppColors.primaryGradient`, the
same one Sign In's button already uses -- confirmed by exact hex match,
not a new color), white QR icon and label. "Reserve Event" is white with
a black-at-10%-opacity border, its calendar icon in `bottomNavActive`
(`#EC003F`, matching the Events bottom-nav icon's own accent) while its
label stays `textDark` -- icon and text are deliberately different colors
here, unlike "Access Café" where both are white, so the widget takes
separate `iconColor`/`textColor` rather than one shared "content color."

**Verified live** through the real UI, same VIP test account from
decision #28: tapped "Access Café" from Home -- landed on the QR Code tab,
its bottom-nav icon highlighted correctly, no crash. Returned to Home,
tapped "Reserve Event" -- landed on the Events tab, same confirmation.
`flutter analyze` (clean) and `flutter test` (29/29) both passed before
this live check.

### 30. Sprint 3, Task 6 — Service Hours card, and how "Current Status" was actually verified

Added the last card on Home (Figma node 1217:3650): static hours (9:00
AM-11:00 PM full service, 11:00 PM-9:00 AM self-service) -- no database
involved, these never vary per user, exactly as the task said. The one
real logic on this card is "Current Status," computed by a new pure
function, `ServiceHours.isFullServiceAt(DateTime time)`
(`lib/utils/service_hours.dart`), called as
`ServiceHours.isFullServiceAt(DateTime.now())` at build time -- not
hardcoded, not a stored value, recomputed from whatever the device's
clock actually says whenever this card builds.

**Single-Figma-instance judgment call, same kind as decisions #27/#28:**
the design only shows the status banner in its full-service state (green
background/border/text) -- there is no second instance showing what
self-service looks like. Reused the same green treatment for both states
rather than invent an unevidenced second color scheme, differing only in
text. The self-service copy itself ("Self-service hours") isn't literal
design copy either -- the one FAQ item that would explain the distinction
has no answer text in the Figma export (the same "only 1 of 4 FAQ answers
exported" gap the Sprint 2 checkpoint already logged) -- so this is a
reasonable editorial completion, worth a real answer once real FAQ copy
exists, not extracted data.

**How both branches were actually verified** -- the task asked for this
specifically, not just "it happens to work right now":

- **Unit tests** (`test/service_hours_test.dart`, 8 cases, following the
  same `now`-as-a-parameter pattern `PaymentValidators.expiry` already
  established for this exact reason): both branches, plus every boundary
  hour by name -- exactly 9:00 AM (full service starts), 10:59 PM (still
  full service), exactly 11:00 PM (self-service starts), just after
  midnight, 8:59 AM (still self-service), and exactly 9:00 AM the next
  day again. `flutter test` -- 37/37 passing (29 previous + 8 new).
- **Attempted a live system-clock change**, as the task suggested, before
  falling back to reasoning: `Set-Date` to 2:00 PM appeared to succeed
  (`Get-Date` echoed it back immediately after), but a fresh check
  seconds later showed the real clock already back to the actual time --
  this VM's host time-sync corrects manual clock changes almost
  instantly, a normal safeguard in a cloud/VM environment. Forcing past
  that would mean disabling a system time-sync service to test a cosmetic
  status string, a disproportionate system change for what it's worth;
  didn't pursue it, and the momentary change reverted on its own before
  it could affect anything else (session tokens, etc.).
- **Live UI verification of the branch matching actual real time**:
  signed in through the real app at the actual system time (~1:48 AM,
  inside the self-service window) -- the card rendered "Current Status:
  Self-service hours" in the green banner, correctly, with the real
  static hours rows above it. The full-service branch is covered by the
  unit tests above (which call the exact same function the widget calls,
  so there's no gap between "logic the tests proved" and "logic the
  widget runs") plus the code-review reasoning the task explicitly
  offered as an alternative: `isFullServiceAt` is a two-comparison pure
  function with no other branching, and the "Full service available"
  string is copied verbatim from the Figma node, not retyped.

### 31. Sprint 3, Task 7 — Benefits list, reusing `membership_plans.features` for real, and a real browser-automation finding

Added the last card on Home (Figma node 1217:3673). Rather than render
`plan.features` (the raw column) or hand-copy a curated list like the
Figma mock's own demo bullets ("Bring up to 2 guests with you",
"Member-exclusive discounts on guest orders", etc. -- plausible-sounding
demo copy that doesn't match any real column value), this card calls
`MembershipPlan.featureBullets` -- the exact same getter Choose
Membership's cards already call for the exact same plan. That was the
point of the task ("same data source... can never silently drift out of
sync"): reusing the identical getter guarantees byte-identical output for
the same plan on both screens, not just "reads from the same table."

**This required reworking `ActiveMembership`** (decisions #27/#28), which
had been growing a second, parallel copy of `MembershipPlan`'s fields
(`hookahLimit`, `drinksLimit`, and now would've needed `features` and
`maxGuests` too) one task at a time. Re-deriving `featureBullets`'s
formatting logic a second time on `ActiveMembership` would have created
exactly the drift risk this task exists to prevent -- two independently
maintained copies of the same bullet-building logic that could quietly
diverge. Instead, `ActiveMembership` now wraps a real `MembershipPlan`
(`fetchActiveMembership()`'s query changed from selecting three named
columns to `membership_plans(*)`, feeding straight into
`MembershipPlan.fromJson`), with `planName`/`hookahLimit`/`drinksLimit`
kept as thin delegating getters so the Task 3/4 call sites in
`home_screen.dart` didn't need to change.

**A real browser-automation finding worth recording**: verifying this
card required scrolling Home for the first time this sprint (every
previous card fit on one screen), and neither mouse-wheel scroll nor a
click-drag gesture via this session's CDP-based browser tool actually
moved the page -- screenshots stayed pixel-identical across many
attempts. Confirmed via `flutter-view`'s own `getBoundingClientRect()`
that the true viewport (2048x1136) is well over twice the screenshot tool's
1464x812 frame, and the page's real content (status card + quick actions
+ usage cards + service hours + benefits, ~1450px tall) genuinely
extends past it -- so this wasn't a rendering bug, it was this specific
CDP scroll path not reaching Flutter's web pointer/wheel handling.
Worked around it by dispatching a real `WheelEvent` directly to the
`flutter-view` element via `javascript_tool` (`deltaY: 600-900`), which
Flutter's web engine did respond to correctly. Worth remembering for any
future task that needs to verify content below the first screenful.

**Verified live** with two different real plans on the same test account
(SQL-switched `plan_id`, same pattern as decisions #26-28), confirming
the benefits list changes shape correctly, not just cosmetically:

- **VIP** (`hookah_limit`/`drinks_limit` both `NULL`, `features =
  ['Private booth', '24/7 access', 'Event priority', 'Exclusive menu']`):
  card showed "Unlimited Hookah", "Unlimited Drinks", "Bring 2 guests",
  then exactly those four features, in order.
- **Premium** (`hookah_limit`/`drinks_limit` both `20`, `features =
  ['Priority seating', 'Weekend access', 'Member discounts']`): card
  showed "20 Hookah sessions/month", "20 Drinks included", "Bring 2
  guests", then exactly those three features, in order -- correctly
  switching from the unlimited phrasing to the numeric one for the same
  widget, driven entirely by the real `hookah_limit`/`drinks_limit`
  values, not a hardcoded list.

`flutter analyze` stayed clean (same 3 pre-existing unrelated infos)
throughout.

### 32. Sprint 3, Task 8 — Notification bell, deliberately a stub only

Added the bell icon (Figma node 1217:3570) top-right on Home. Tapping it
pushes `ComingSoonScreen(label: 'Notifications')` -- that's the entire
scope. Deliberately **not** built, per the task's own instruction:

- **No unread-count badge**, even though the Figma mock shows one with a
  hardcoded "2" on it. A real badge needs a real number, which needs a
  real notifications table and a definition of what counts as "unread" --
  none of which exists yet.
- **No notifications table or schema invented** to make a plausible
  number appear. Logged instead as a genuinely open question (see the
  "Genuinely open questions" section above): what a notification even is
  here, whether it needs its own table or gets synthesized from existing
  ones, how read/unread state is tracked, and whether delivery is
  in-app-only or also push/email are all undecided and out of scope for
  this task.
- **No Home header rebuild.** The Figma frame this bell sits in also has
  a "Welcome, {name}!" greeting, member ID, and a Logout button (already
  handled differently -- see decision #26, Sign Out lives on the Profile
  tab instead) -- none of that was this task's ask, so Home still doesn't
  have a header block beyond the bell itself.

**Verified live**: signed in, bell renders top-right with no badge;
tapped it, landed on the "Notifications — coming in a future task" stub
with a working back arrow. `flutter analyze` clean, `flutter test`
37/37 passing.

### 33. Pre-Sprint-4 — two decisions made ahead of the QR Code and Event Reservation tasks

Raised and decided before Sprint 4's screens exist, so both are settled
by the time the actual tasks land rather than being re-litigated then.

**Door access / QR check-in does not touch `usage_allowances`.** This
app has no way to know what a member actually consumes once inside (a
hookah session lit, a drink poured) -- that requires a real staff/POS
system, out of scope entirely. Logging a door access only ever writes to
`door_access_logs` (arrival timestamp + guest count); `usage_allowances`
stays exactly as-is through that flow. Same deferred bucket as the
renewal gap in decision #25 -- there is still no mechanism that
increments `hookah_used`/`drinks_used` at all, door access or otherwise,
and this doesn't change that.

**Guest-count naming collision, called out explicitly so it doesn't get
"helpfully" merged later:** the Door Access screen's guest count (how
many people a member brings in with them, capped by their own plan's
`max_guests` -- 0 to 2) and the Event Reservation screen's guest count
(how many people a private event is booked for -- 5 to 100, the whole
café) share a UI label ("Number of Guests"/similar) but mean completely
different things, against completely different tables, with completely
different valid ranges. Deliberately kept as fully separate fields with
no shared model, validator, or widget between them -- a future refactor
that spots the naming overlap and "simplifies" them into one shared
component would be introducing a bug, not removing duplication.

**Event pricing and event-type options stay placeholders** (already on
the open-questions list above) rather than blocking Sprint 4 on real
numbers from the company. When the Event Reservation screen gets built,
the placeholder price/types will be computed server-side from a single
named constant, so supplying the real values later is a one-line change
in one place, not a redesign touching every place price was displayed.

### 34. Sprint 4, Task 1 — `log_door_access` RPC, and proving all three of its server-side checks with role impersonation

Added `log_door_access(p_guest_count integer)`
(`supabase/migrations/20260916100000_log_door_access.sql`) -- the only
way a row gets written to `door_access_logs` from the client, since that
table has no INSERT policy for `authenticated` (same reason
`subscriptions`/`usage_allowances` are RPC-only -- see decision #4).
Same security pattern as every prior RPC: `SECURITY DEFINER`,
`search_path` pinned, `auth.uid()` read internally rather than accepted
as a parameter, `EXECUTE` revoked from `PUBLIC` *and* explicitly from
`anon` (decision #16's lesson -- Supabase grants EXECUTE to `anon`
per-function regardless of a bare `revoke ... from public`).

**Two things this function does not trust the client for**, both
explicitly called out in the task:

1. **Active membership**, re-checked server-side with the identical
   `status = 'active' and valid_until > now()` condition from decisions
   #25/#27 -- not just `status = 'active'` alone, for the same reason as
   Home's card: `expire_subscriptions()` only runs once a day, so a
   lapsed row can sit with a stale `'active'` status for up to ~24h. A
   member whose subscription expired 5 minutes ago is rejected
   immediately here regardless of whether the cron job has caught up yet.
   No match at all (including "never subscribed") raises
   `no_active_subscription`.
2. **Guest count**, validated against the caller's own plan's real
   `max_guests` (fetched server-side via the same `subscriptions` joined
   to `membership_plans` shape used elsewhere), not the value the UI's
   stepper widget happens to allow. Out-of-range raises
   `guest_count_exceeds_plan_limit` with `max_guests`/`requested` in the
   detail, whether the client would have ever produced that number or
   not.

Deliberately does **not** touch `usage_allowances` at all (decision #33)
-- a door access event only ever records arrival + guest count.

**Verified live with role impersonation**, the same method as decisions
#16/#19/#25, each check isolated in its own `begin; ... rollback;` so
nothing touched real data:

- **`anon`**: `set local role anon; select public.log_door_access(1);`
  → `ERROR: 42501: permission denied for function log_door_access` --
  rejected at the grant level, never reaches the function body at all.
- **Authenticated, no active subscription** (a real user with no
  matching row): → `ERROR: P0001: no_active_subscription`, raised inside
  the function after the membership check found nothing.
- **Guest count above the real limit**: impersonated a real Premium
  subscriber (`max_guests = 2`) and called `log_door_access(3)` --
  `3` chosen specifically because no UI stepper capped at 2 would ever
  send it. → `ERROR: P0001: guest_count_exceeds_plan_limit`, `DETAIL:
  {"max_guests": 2, "requested": 3}` -- the real plan limit, fetched
  server-side, not trusted from the caller.
- **Happy path, exactly at the limit** (`log_door_access(2)` for that
  same account): succeeded, inserted a real row (`guest_count = 2`,
  `accessed_at` populated) -- confirmed inside the same transaction, then
  `rollback`, then confirmed with a fresh `count(*)` query afterward that
  zero rows actually persisted.
- **Grants double-checked directly**: `has_function_privilege()` shows
  `prosecdef = true`, `anon` = false, `authenticated` = true -- matching
  the migration file exactly, not just assumed from the revoke/grant
  statements.

### 35. Sprint 4, Task 2 — QR / Door Access screen, sharing Home's membership fetch, and a documented training-project simplification

Built the real Door Access screen (Figma node 1215:1616), replacing that
tab's `ComingSoonScreen` stub: real QR code (`qr_flutter`), a guest
stepper clamped to the caller's real plan `max_guests`, and an "Open
Door" button that calls `log_door_access` (decision #34).

**Training-project simplification, logged rather than fixed, exactly as
asked:** the QR payload is the member's plain `member_id` string
(`lib/screens/qr_access/qr_access_screen.dart`'s class doc comment spells
this out in full). A real production version needs a short-lived,
signed/rotating token instead -- a static QR can be photographed once and
reused indefinitely, with no way to revoke it, to log a door-access event
against that member forever. Not building the token-issuing/verification
infrastructure this would need; the comment exists so this doesn't get
silently forgotten as "already handled."

**Reusing Home's `ActiveMembership` fetch instead of re-querying it,**
per the task's explicit instruction, meant moving that fetch (and the
"no active membership -- bounce to Choose Membership" defensive check
from decision #27) up from `HomeScreen` into `MainShell` itself --
the one place both the Home and QR Code tabs can share it. `MainShell`
now fetches `ActiveMembership` once, shows a loading spinner, bounces if
null, and only then builds both `HomeScreen(membership: ...)` and
`QrAccessScreen(membership: ...)` with the same object. `HomeScreen` no
longer fetches or gates on membership at all -- `MainShell` never
constructs it without one.

**New pieces added to support this:**

- `Profile.memberId` -- the `profiles.member_id` column was already being
  fetched (`ProfileService.fetchCurrentProfile()` selects `*`) but had no
  field on the Dart model until this task needed to display it.
- `DoorAccessService.logDoorAccess()` -- same
  `LogDoorAccessFailure`-with-a-safe-message pattern as
  `StartSubscriptionFailure`/`ConfirmPaymentFailure`, mapping
  `log_door_access`'s three exception strings to sentences safe to show
  directly, so a caught `PostgrestException` never reaches the UI as raw
  text.

**Guest stepper clamps in the UI** (`0 <= count <= plan.maxGuests`,
buttons disable visually at the bounds) as the primary UX, but that is
explicitly not where the real enforcement lives -- decision #34's
server-side check is what actually protects this, since the RPC never
trusts what the client sends regardless of what the stepper allowed.
"Open Door" resets the counter to `0` and shows a mock success banner
("Door unlocked! Enjoy your visit.") on success -- there's no real door
hardware to unlock, so this is explicitly a UI acknowledgment, not a
simulated device response.

**Verified live**, all four acceptance points, through the real UI (not
just SQL) on the decision #26 test account, switching its real plan via
SQL between checks the same way decisions #26-28/#31 did:

- **Basic** (`max_guests = 1`): copy read "You can bring up to 1 guest
  with your Basic membership" (correct singular grammar); tapped "+"
  twice, counter stopped at `1`, button visibly disabled past that --
  never reached `2`.
- **Premium** (`max_guests = 2`): copy read "...2 guests..."; tapped "+"
  three times, counter stopped at `2`.
- **Real door_access_logs row**: tapped "Open Door" at guest count `2` on
  the Premium account -- success banner shown, counter reset to `0`,
  and a fresh SQL query confirmed a real row (`guest_count = 2`, a real
  `accessed_at` timestamp) had actually been inserted.
- **Expired account, friendly error**: backdated that same account's
  `valid_until` to yesterday via SQL while the screen was already open
  (simulating decision #27's mid-session-expiry scenario), then tapped
  "Open Door" again without reloading -- the screen showed "Your
  membership isn't active right now, so door access isn't available."
  inline, in the app's normal error-text style, not a raw exception, a
  stack trace, or a crash. Guest count stayed unchanged (the call never
  succeeded), confirming the reset-to-0 only happens on a real success.
- **Member ID confirmed real**: queried the same account's
  `profiles.member_id` directly (`RC-000031`) to confirm the QR's data
  source is the genuine column value, not a placeholder.

`flutter analyze` (clean, same 3 pre-existing unrelated infos) and
`flutter test` (37/37) both passed before this live verification.

### 36. Sprint 4, Task 3 — `create_event_reservation` RPC, and a real direct-insert bypass it closes

Added `create_event_reservation(p_event_type, p_event_date, p_start_time,
p_duration_hours, p_guest_count)`
(`supabase/migrations/20260916110000_create_event_reservation.sql`).
Same security pattern as every prior RPC: `SECURITY DEFINER`,
`search_path` pinned, `auth.uid()` read internally, `EXECUTE` revoked
from `PUBLIC` and explicitly `anon`. `total_price` is computed
server-side (`duration_hours * 150`, a single named `c_price_per_hour`
constant flagged as placeholder pricing pending real numbers from the
company -- same pattern decision #33 already established) and is **not**
a function parameter at all -- there's no argument for a caller to smuggle
a price through, not just a check that rejects one.

**A real gap found while building this, not just a hypothetical:**
`event_reservations` already had its own `"Users can create own
reservations"` RLS policy from the initial schema, letting
`authenticated` insert directly with `auth.uid() = user_id` --
unlike `subscriptions`/`usage_allowances`/`door_access_logs`, which were
RPC-only from the start (decision #4). That policy would have let a
client bypass this entire RPC and insert a row with any `total_price` it
wanted, making the "no path to supply a price" guarantee false the moment
anything used a direct `.insert()` instead of this function. This
migration drops that policy (`drop policy ... "Users can create own
reservations"`), making `create_event_reservation` the only INSERT path,
consistent with every other money-shaped table in this project. The
`SELECT`/`UPDATE` policies are untouched for now -- worth flagging
though: the `UPDATE` policy has the same latent shape (a user could
directly update their own reservation's `total_price` after the fact) --
deferred rather than fixed here since no screen updates reservations yet
and this task's scope was specifically the create path; revisit when an
edit/cancel flow gets built.

**Resolved (#53):** confirmed live and closed during the consolidated security
audit -- the `UPDATE` policy is now dropped entirely, since no edit/cancel
flow was ever built and nothing needed it.

**Two checks this function does not trust the client for:**

1. **Guest count**, 5-100 -- the design's own stated range for a private
   event booking. This is a completely different field from the Door
   Access screen's 0-2 "guests you're bringing with you" despite sharing
   a UI label pattern -- decision #33 called this naming collision out
   explicitly precisely so the two never get conflated in code, and they
   haven't been: separate parameter, separate range, separate table.
2. **Event date**, rejecting anything before today. Deliberately not
   layered with any availability/double-booking logic -- that's a
   separate feature this project doesn't have and wasn't asked for here.

**Deliberately inserts with `status = 'confirmed'`, not `'pending'`**,
even though `reservation_status` has a `'pending'` value available: no
screen in this app has any approval/review workflow for event
reservations, so a `'pending'` row would just be a permanent dead end
with nothing that could ever move it to `'confirmed'`. Building an
approval-state machine nobody asked for and no screen would ever act on
would be the same mistake decision #25 already avoided for
`usage_allowances` renewal -- inventing a mechanism ahead of the flow
that would need it. Logged here as the deliberate simplification instead.

**Verification correction, mid-task:** the first attempt at this handed
a multi-step SQL script (with placeholders like `<paste-uuid-here>`) to
the user to run themselves. That failed -- a narrative sentence got
pasted as if it were SQL, and the placeholder UUID was left unsubstituted
-- because fetching and substituting an id by hand is exactly the kind
of mechanical, error-prone step that isn't a good fit to hand off. The
user's own call afterward: **all Supabase SQL Editor / database
verification stays mine to drive directly** (via role impersonation in
the SQL Editor), while app-level UI testing stays theirs. This split is
now recorded in memory for future tasks.

**Verified directly (by the assistant, via role impersonation in the
Supabase SQL Editor), all passing:**
- Migration applied: `create_event_reservation` exists,
  `prosecdef = true`.
- Grants correct: `has_function_privilege('anon', ..., 'execute') = false`,
  `has_function_privilege('authenticated', ..., 'execute') = true`.
- The dropped `"Users can create own reservations"` policy is confirmed
  gone from `pg_policies` (only `SELECT`/`UPDATE` remain on
  `event_reservations`).
- `anon` rejected: `42501 permission denied for function
  create_event_reservation`.
- No `total_price` parameter exists at all: calling with a 6th argument
  fails with `42883 function ... does not exist` -- not just a runtime
  check, there's no such overload.
- Guest count out of range, both directions: `4` and `101` both raise
  `guest_count_out_of_range` with the requested value echoed in
  `DETAIL`.
- Past `event_date` (`2020-01-01`) raises `event_date_in_past`.
- Happy path: a real authenticated user with an active subscription
  calling with `duration_hours = 3` produced a row with
  `total_price = 450.00` and `status = 'confirmed'` -- then rolled back,
  confirming no row persisted from any of these tests.
- Direct-insert bypass concretely blocked, not just absent from
  `pg_policies`: attempting a raw `insert into event_reservations ...`
  as `authenticated` fails with `42501 new row violates row-level
  security policy for table "event_reservations"`.

### 37. Sprint 4, Task 4 — Reserve an Event screen, and the shared-constant pricing pattern that ties its display to the RPC

Built `ReserveEventScreen` (`lib/screens/events/reserve_event_screen.dart`)
and `EventReservationService` (`lib/services/event_reservation_service.dart`),
replacing the Events tab's `ComingSoonScreen` stub in `MainShell`. Matches
Figma App-12: Event Type dropdown, Event Date/Start Time pickers, Duration
(hours), Number of Guests (with the design's own "Minimum 5 guests,
maximum 100 guests" helper text), a static "Event Package Includes" list,
a live price breakdown, and "Confirm Reservation" calling
`create_event_reservation` (decision #36).

**Event Type's four options (Birthday / Corporate / Private Party /
Other) are a placeholder**, same open-question bucket as the Help &
Support FAQ gap — the design never confirmed a real list and no table
backs it. Decided as a fixed in-code list rather than inventing a
lookup table for four placeholder strings.

**The live "Estimated Total" and the RPC's own `total_price` share one
constant, not two independently-typed `150`s:**
`EventReservationService.pricePerHour` is the exact same value read by
both this screen's display calculation and documented as matching
`create_event_reservation`'s `c_price_per_hour`. Since the RPC has no
parameter for a client to supply a price at all (decision #36), a
mismatch here could only ever be cosmetic — the display saying one
number while the server silently stores its own — never a way for a
client to make the server charge something else. Duration input is
restricted client-side to at most 2 decimal places (`^\d{1,2}(\.\d{1,2})?$`),
matching `duration_hours`'s own `numeric(4,2)` column precision — without
this, a value like `2.126` would multiply cleanly for the live display
but get silently rounded to `2.13` by Postgres on insert, a confusing
(though still harmless) drift between the two.

**Client-side validation blocks bad submissions before any network
call**, same pattern as Create Account (decision #8): guest count
outside 5–100, a non-positive or malformed duration, a past event date,
and a missing event type/date/time all fail `Form.validate()` (or an
equivalent manual check for the date/time pickers, which aren't
`TextFormField`s) before `EventReservationService.createEventReservation`
is ever called. The server's own checks (decision #36) remain the real
enforcement — this is a courtesy that saves a round trip, not something
either screen or RPC trusts alone.

**A real bug caught before it shipped, not by testing but by reasoning
through `DropdownButtonFormField`'s API:** newer Flutter versions renamed
its `value` parameter to `initialValue`, making it behave like
`TextFormField`'s own `initialValue` — read once on first build, not kept
in sync with the backing variable afterward. Clearing `_eventType` after
a successful submission alone would have left the dropdown visually
stuck on the just-submitted selection. Fixed by calling
`_formKey.currentState?.reset()` alongside the manual field clears.

**Update, decision #38:** this whole reset-in-place approach (and the
`FormState.reset()` workaround above) was superseded one task later —
a successful submission now swaps the entire screen out via
`EventsTab` rather than clearing this screen's own fields, which makes
the dropdown problem moot: the next `ReserveEventScreen` is a brand-new
instance, never the same one being reset.

**Deliberately not built: a dedicated "Reservation Confirmed" screen.**
Figma has one (App-13: date/time/duration/guest summary + "Back to
Dashboard"), but this task's own acceptance criteria only covered the
form screen itself. Matching Door Access's precedent (decision #35: a
mock success `SnackBar`, not a full screen) rather than Payment's
(decision #4: a dedicated `PaymentSuccessScreen`), this screen shows a
success `SnackBar` and resets its own fields, staying in place. Flagging
App-13 as a known, unbuilt screen rather than silently skipping it
forever or building it without being asked — a natural candidate for its
own future task.

**Update: built one task later, see decision #38** — Task 5 asked for
exactly this screen.

**Not yet verified live** — this needs the user's own app-level
click-through per the corrected verification split (decision #36): a
real submission's `event_reservations.total_price` actually matching
this screen's displayed estimate, and the guest-count/date validators
firing before any network call is visible in the browser's network tab.
(The dropdown-reset behavior this originally also listed no longer
applies — see the decision #38 update above.)

### 38. Sprint 4, Task 5 — Reservation Confirmed screen, and swapping tabs in place instead of pushing

Built `ReservationConfirmedScreen` (`lib/screens/events/
reservation_confirmed_screen.dart`), matching Figma App-13: a dark
"Event reservation confirmed!" banner, a green check badge, "Reservation
Confirmed!" heading, and a Date/Time/Duration/Guests summary card, with
a "Back to Dashboard" gradient button.

**Takes its data via constructor, zero additional DB reads** — a new
`ReservationSummary` model (`lib/models/reservation_summary.dart`)
carries `eventDate`/`startTime`/`durationHours`/`guestCount` straight
from `ReserveEventScreen`'s own already-known form state, the same
pattern `PaymentSuccessScreen` already established for `MembershipPlan`
(decision #4).

**How this screen actually gets shown — the part this task's own
wording called out specifically:** it is never reached via
`Navigator.push`. A new `EventsTab` widget
(`lib/screens/events/events_tab.dart`) is what `MainShell` now puts in
the Events slot of its `IndexedStack` (replacing the direct
`ReserveEventScreen` from decision #37). `EventsTab` holds one piece of
local state — the just-confirmed `ReservationSummary`, or null — and its
`build()` is a plain conditional: null shows `ReserveEventScreen`,
non-null shows `ReservationConfirmedScreen`. `ReserveEventScreen` gained
an `onConfirmed` callback (replacing decision #37's success `SnackBar`)
that `EventsTab` uses to flip that state after a real RPC success.
"Back to Dashboard" on the confirmation screen clears that state *and*
calls `MainShell`'s existing tab-switching callback
(`onGoToHome` → `_goToTab(_homeTab)`) — the exact same `_goToTab`
callback pattern decision #29 (Sprint 3, Task 5) introduced for Home's
"Access Café"/"Reserve Event" quick actions and decision #35 later
reused for `QrAccessScreen`, not a new mechanism invented for this
screen.

**"Returning to Home doesn't leave a dangling nav stack entry" is true
by construction, not just by care taken on the way out** — this whole
transition (form → confirmation → back to Home) never calls
`Navigator.push` even once. There is nothing on the nav stack to leave
behind, because nothing was ever pushed onto it.

**Clearing the confirmed reservation on "Back to Dashboard" (not only
lazily on next entry)** means the next time the user opens the Events
tab via the bottom nav — not just the next time this specific widget
happens to rebuild — they see a fresh, blank `ReserveEventScreen`,
never the reservation they already confirmed. This also makes decision
#37's `DropdownButtonFormField`/`FormState.reset()` workaround moot: the
form widget is discarded and recreated on this path, not reset in
place, so a fresh instance starts with a blank dropdown by construction.

**Not yet verified live** — matches the design's layout by eye against
the Figma export, but needs the user's own click-through (per the
verification split, decision #36): confirming a real submission lands
on this screen with the right values, "Back to Dashboard" actually lands
on Home with the bottom nav still functional afterward, and returning to
the Events tab later shows a blank form rather than the old confirmation.

### 39. Sprint 4, Task 6 — logging this sprint's decisions (a checkpoint, not new work)

This task's three items were each already decided and written down as
they came up, rather than left to be reconstructed after the fact — this
entry is a pointer to where, not new content:

1. **The usage-allowances/door-access decoupling** — logged in decision
   #33 (decided pre-Sprint-4) and re-confirmed in decision #34's
   description of `log_door_access`: door access only ever writes to
   `door_access_logs`; nothing about it touches `usage_allowances`, and
   there is still no mechanism anywhere that increments
   `hookah_used`/`drinks_used` (same gap decision #25 already flagged).
2. **The guest-count naming distinction between the two screens** —
   logged in decision #33: Door Access's guest count (0–2, capped by the
   caller's own plan) and Event Reservation's guest count (5–100, the
   whole café) share a UI label but are deliberately separate fields,
   validators, and tables, called out specifically so a future "cleanup"
   pass doesn't merge them into one shared component and introduce a
   real bug.
3. **Placeholder event pricing + event-type list** — the pricing
   placeholder was first raised as an open question early in the project
   and settled pre-Sprint-4 in decision #33; the event-type list
   placeholder was decided when Reserve an Event was actually built
   (decision #37). Both are now filed together under "Genuinely open
   questions" below (updated in this pass to reflect that the screens
   using them are built, not hypothetical) rather than left as two
   separately-worded loose ends.

No code changed for this task — it's a documentation pass confirming
the sprint's decisions are traceable in this file, not just in chat
history that won't survive past this conversation.

### 40. Sprint 5, Task 1 -- Profile screen (read), built to exact Figma values

Built the real Profile tab (`lib/screens/profile/profile_screen.dart`,
Figma frame `1216:2169`), replacing the `ComingSoonScreen` stub `MainShell`
had in that slot. Every number below came from the Figma REST API's node
data for that frame (fills, radii, shadows, padding, gaps, font
size/weight/line-height/letter-spacing), not from eyeballing the PDF -- the
same method as decision #20. (The first personal access token supplied
came back `Invalid token`; a second one with the file-content read scope
worked. Neither is stored anywhere in the repo.)

**Data, all real, none re-fetched that already existed:**
- `ActiveMembership` is handed in from `MainShell` (decisions #27/#31/#35):
  plan name, valid-until, and max guests. Valid Until uses the same
  `M/d/yyyy` (no leading zeros) and the same `DateTime` as Home's status
  card, so the two screens always agree.
- Name / email / phone / member ID come from
  `ProfileService.fetchCurrentProfile()` (decision #18).
- The "PREMIUM Member" badge is `'${planName.toUpperCase()} Member'` from the
  real plan name -- Basic shows "BASIC Member", VIP "VIP Member".

**Where the screen deliberately differs from, or adds to, the Figma frame:**
- **Plan row text.** The design's demo data is the lowercase string
  `premium`, shown as "Premium" via Figma's Title-Case text setting. The real
  `membership_plans.name` is already "Premium"/"Basic"/"VIP", so it's shown
  as stored -- no casing transform (applying Title Case would turn "VIP" into
  "Vip").
- **Empty fields hide their row** (phone, member ID are nullable columns)
  instead of showing a placeholder, per "zero placeholder data".
- **A load-failure state** ("Couldn't load your profile." + Try again) that
  the design doesn't have. Without it a failed fetch would leave a blank
  screen with no way to reach Sign Out; the sections that don't depend on
  the profile (Membership Details, Settings, Sign Out) still render.
- **Icons are Material outlined glyphs**, not Figma's exact Lucide vectors --
  the same trade-off decision #26 already made for the bottom nav that sits
  right under this screen, so the two match each other. Swapping in exported
  SVGs would need a new dependency; not done.
- **Version line** ("Version 1.0.0 • Rosewater Café") is a constant matching
  `pubspec.yaml`, not read from the platform (would need a new package).
- The screen uses the design's own page-wash gradient as its background.
  Home currently uses the flat scaffold colour instead; worth aligning
  whichever way is right if the two look inconsistent side by side.

**Every row/button except Sign Out opens `ComingSoonScreen`** (Edit Profile,
Upgrade Membership, Payment Methods, Notifications, Privacy & Security, Help &
Support, App Settings) -- their real screens are later Sprint 5 tasks, and
there is no upgrade flow at all yet (decision #25). **Sign Out is real and
permanent** (decisions #21/#26): it ends the session, clears the whole nav
stack to Auth Landing, guards against a double tap, and shows a SnackBar if
the sign-out call itself fails.

**Verified:**
- `flutter analyze` -- same 3 pre-existing lint infos, nothing new.
- `flutter test` -- 44/44 (37 existing + 7 new in
  `test/profile_content_test.dart`: real data shown, badge follows the plan,
  hidden rows, retry state, every callback fires, Sign Out disabled while in
  progress). `ProfileContent` is split from the loading widget specifically so
  this mapping is testable without a Supabase connection.
- **Layout measured against Figma numerically**, since the app couldn't be
  launched (memory pressure): rendering at Figma's exact 374.98 width with a
  real font, the Profile card is 342.98x277.03, Membership Details
  342.98x361.03, Settings 342.98x353.03, both outlined buttons 342.98x51.09,
  section gaps 24, name line 32, badge offset 39.15 -- all identical to the
  design. (Badge width and the button icon's x-offset differ by ~2px only
  because the probe used Roboto, which is narrower than Inter.)

**Not verified:** the screen has not been looked at running in the app, so
colours, shadows and icon shapes have not been compared visually against the
design -- that click-through/eyeball check is the developer's. Also not
verified against a real account with no phone number.

**Notes for the next Sprint 5 tasks:**
- Edit Profile: `profiles` allows the client to UPDATE its own `email` column,
  which is separate from the login email in `auth.users`. Make it read-only
  there (or change it via `auth.updateUser`) so the two can't drift apart.
- `QrAccessScreen` and `ProfileScreen` each fetch the same profile row, so two
  identical queries run when `MainShell` builds. Harmless; could be hoisted
  into `MainShell` like `ActiveMembership` was.
- `ComingSoonScreen.showSignOut` is no longer used by anything.

### 41. Home rebuilt to the exact Figma frame -- the missing header, and a shared profile fetch

**Reported by the user:** the screen after sign-in had nothing about
"Welcome" and didn't look like the Figma design. Both true: decision #32
had deliberately built only the bell from Home's header, and the rest of
the dashboard had drifted from the design in spacing and type. Rebuilt
`lib/screens/home/home_screen.dart` against the Figma REST data for the
whole frame (node `1217:3554`), the same method as decisions #20/#40.

**What was missing or different, and is now to the design:**
- **Header** (new): "Welcome, {first name}!" (Inter Medium 36) and
  "Member ID: ..." on the left; the bell (no badge) and **Logout** on the
  right, bell first, 8px apart. 32px between the header and the status card.
- **Frame:** top padding 32 (was 16), the design's page-wash gradient
  behind the screen, `SafeArea` on top like the Profile tab.
- **Status card:** "Membership Status" at 80% white and "Valid until" at 90%
  white (were 100%), the design's line heights/spacing (title 30/36, 4px
  gap, 40px to "Valid until"), hairline 0.515 borders.
- **Usage cards:** the design's order is icon+label row, then the progress
  bar (40 below), then the "used this month" caption (32 below the bar) --
  the code had the caption first with 16/8 gaps.
- **Service Hours / Benefits cards:** 40px between the title and the content
  (was 24); type sizes with the design's line heights and letter spacing;
  service-hour rows use 12px padding and wrap on narrow screens instead of
  overflowing (the old rows overflowed a 375-wide phone).
- **Reserve Event button:** 1.545 border, as designed.

**Decisions made:**
- **Notification badge stays out**, by the user's call ("skip the
  notification thing till we build it"): the bell is still a stub that
  opens `ComingSoonScreen`, with no unread count. The design's "2" is demo
  data.
- **Logout is back on Home** (the design has it in the header) and calls the
  same sign-out as the Profile tab's Sign Out, via a new shared helper
  (`lib/screens/auth/sign_out.dart`). This supersedes the "Sign Out lives
  only on Profile" part of #21/#26: the design has both.
- **First name** = the first word of `profiles.full_name`. With no profile
  (fetch failed) or a blank name the greeting is a plain "Welcome!"; a
  missing member ID hides its line. No placeholder name/number ever shows.
- **Profile is now fetched once**, in `MainShell`, in parallel with the
  membership, and passed to Home, QR Code and Profile -- replacing the two
  separate fetches those last two did (the duplicate flagged at the end of
  #40). A failed profile fetch becomes `null` and each tab degrades on its
  own (Profile keeps its retry).
- **The wrapped "Premium Member" title is reproduced:** at 375 wide the
  design's 30px title wraps, and its second line spills into the 40px gap
  above "Valid until" while the card stays 169.03 tall. Kept: the title box
  is one line high with the overflow visible.
- **Unlimited (VIP) usage card:** the design has no unlimited variant, so
  with no bar the caption follows the label/value row 16px below (#28).
- Home gets the gradient background; the QR Code and Events tabs still use
  the flat scaffold colour. Align them if they look inconsistent next to Home.

**Verified:** `flutter analyze` (same 3 pre-existing infos) and `flutter test`
55/55 (44 + 11 new in `test/home_content_test.dart`). The layout test renders
at Figma's 374.98 width with a real font and matches the design: header-to-
card gap 32, status card 342.98x169.03, quick actions 96 tall 16 apart, usage
cards 197.03, section gaps 24.

**Not verified:** the screen has not been looked at running in the app. And
two things depend on Inter's real text widths, which the test font (Roboto,
narrower) can't reproduce: the design wraps the Member ID line and the two
service-hours rows to two lines at 375 wide; with Inter on a real device they
should wrap the same way (the row flex weights are the design's own box
widths), but that needs an eyeball check -- as do the Material icons vs the
design's exact vectors (same trade-off as #26/#40).

### 42. Sprint 5, Task 2 -- Edit Profile, the `avatars` bucket, and locking `profiles.email`

Built the real Edit Profile screen (`lib/screens/profile/edit_profile_screen.dart`,
Figma frame `1217:2403`, exact values via the REST API as in #20/#40/#41),
replacing the stub behind Profile's "Edit Profile" button.

**What's editable, and what isn't**
- **Editable:** full name, phone, profile photo.
- **Email is read-only, and genuinely so:** it is plain text, not a `TextField`
  (it can't be focused or typed into -- there's a widget test for exactly
  that), with the note "Your email can't be changed in the app." Changing a
  Supabase Auth email needs its own re-verification flow (a confirmation link to
  the new address), out of scope this sprint. Member ID and plan are read-only as
  in the design ("Contact support to change membership type").
- **Field text colour:** the design shows field values in Figma's muted grey
  (`#717182`), so all three inputs use it, exactly as designed -- darken it if
  typed text reads as too faint.

**Validation** (all before any network call)
- Name required; phone uses `Validators.phone` -- **decision #10's exact rule**
  (leading `+`, 8-15 digits, formatting characters stripped). It was *moved*, not
  rewritten, out of `CreateAccountScreen` into `lib/utils/validators.dart` so
  Create Account and Edit Profile can't disagree; both now call it. A new
  `test/validators_test.dart` pins the rule (it had no tests before).
- Widget tests use a fake `ProfileService` and prove an invalid phone (each
  shape from #10) or a blank name never reaches the service at all.

**Save** -- a plain `profiles` UPDATE, no RPC: exactly the self-owned write
decision #3 always allowed, scoped by the existing `auth.uid() = id` policy. Only
`full_name`, `phone` and (when a new photo was uploaded) `avatar_url` are sent;
`email` never is. The saved row comes back and is handed to `MainShell`, which now
**owns the profile** and rebuilds the tabs, so a name/photo change shows on the
Profile tab, Home's greeting and the QR tab immediately. Saving with nothing
changed makes no request.

**Photo** -- same pattern as ID documents (#18), separate bucket:
- Migration `20260922100000_avatars_bucket_and_profile_email_lock.sql` adds a
  **private `avatars` bucket** with the four per-user storage policies
  (`(storage.foldername(name))[1] = auth.uid()::text`), plus a bucket-level 5 MB
  cap and PNG/JPEG/WebP-only, so the limits hold even for a direct storage API call.
- `image_picker` (camera/gallery, capped at 1024px wide), validated by the new
  `AvatarService` (type + size) right after picking, shown as a local preview, and
  **uploaded only on Save** -- Cancel uploads nothing. Path
  `<user_id>/<timestamp>.<ext>` (a fresh name each time so a cached old photo never
  masks a new one); the replaced photo is deleted afterwards, and an upload whose
  save then failed is cleaned up.
- The path lives in the existing `profiles.avatar_url` column. The bucket is
  private, so `ProfileAvatar` shows it via a 1-hour **signed URL**, falling back to
  the design's gradient-and-icon circle if it can't load.

**A schema change nobody asked for, flagged on purpose:** the migration also adds
a `BEFORE UPDATE` trigger on `profiles` that keeps the old `email` whenever the
request comes from a signed-in user (`auth.uid()` set). Reason: the existing
UPDATE policy lets a client PATCH *any* column of its own row, so `profiles.email`
could drift from the real login email in `auth.users` -- the exact risk raised at
the end of #40. Same idea as the `member_id` lock. A server-side process with no
user session (e.g. a future email-sync after a verified change) is not affected.
A CHECK forcing `avatar_url` into the user's own folder was considered and left out
(an unreadable path is harmless, and a future OAuth avatar URL would break on it).

**Verified live** against the dev Supabase project, driven in the SQL Editor with
real role impersonation (`set local role` + `request.jwt.claims`), inside one
`DO` block that ends in a deliberate `RAISE EXCEPTION` so everything rolls back --
afterwards 0 test files remained in `avatars` and 0 profiles were touched. Two real
users (A, B):
- B reading A's file: **0 rows**. B inserting into A's folder: **blocked, 42501**.
  B updating A's file: **0 rows**. A reading its own file: **1**; A reading B's:
  **0**. B sees only its own avatars (**1** of 1 in the bucket). `anon` writing:
  **blocked, 42501**; `anon` reading: **0 rows**.
- B writing + reading its own folder: **1 row** (allowed).
- **Profiles:** B updating its own row with name, phone, avatar path *and*
  `email = 'hacked@example.com'` -> 1 row updated, name/phone changed, **email
  unchanged**. B updating A's profile: **0 rows**. A server-side update with no user
  session **can** change the email (not blocked).
- Bucket confirmed `public = false`, 5,242,880-byte limit, the three MIME types;
  all four policies present for `authenticated` only; the trigger enabled.
- **Not proven by SQL:** B *deleting* A's file. Supabase blocks direct SQL deletes
  from `storage.objects` for everyone ("Direct deletion from storage tables is not
  allowed. Use the Storage API instead."), so that statement errored for a platform
  reason, not the policy. The delete policy has the same `USING` clause as the read
  and update policies proven above, and it applies through the Storage API the
  app uses.
- Dart side: `flutter analyze` (only the pre-existing lints in Create Account), and
  `flutter test` 81/81 (55 + 26 new: validators, avatar service, Edit Profile with
  a fake service). Layout measured against Figma at 375 wide with a real font:
  header 343x40, photo card 343x213.03, Membership Information card 343x253.03,
  Cancel 163.5x49.03, Save 163.5x48, all section gaps 24. (The Personal Information
  card is taller than the design by exactly the email note.)

**Not verified:** the screen has not been looked at running in the app, and the
photo pick -> upload -> display path (camera/gallery, signed URL) has not been
exercised end to end -- the developer's click-through (and it needs a real image
file; automated file pickers can't drive it on Flutter web, #18). The Supabase SQL
Editor also kept two "Untitled query" entries from these runs in its Private list.

### 43. Sprint 5, Task 3 -- Payment Methods (list / add / set default / delete), and making "one default card" a database guarantee

Built the real Payment Methods screen (`lib/screens/profile/payment_methods_screen.dart`,
Figma frame `1217:2477`, exact values via the REST API as in #20/#40-#42) and an Add
Payment Method screen, replacing the stub behind Profile's "Payment Methods" row.

**Metadata only, exactly like the real Payment flow.** Only brand, last 4, expiry and
`is_default` are ever stored; the table has no column for a full number or CVV.
`PaymentMethodService.add` takes only those four/five values -- there is **no parameter
for a card number or CVV**, so it can't be passed by accident. On the Add screen the
number and CVV are validated for shape and then discarded (controllers cleared and
disposed, no autofill hints, never logged or sent).

**Add reuses Payment's validators (#22).** `PaymentValidators` (16 digits, MM/YY not in the
past, 3-digit CVV) are used unchanged; the Payment screen's field widgets
(`PaymentField`, `ExpiryInputFormatter`) were *moved* to `lib/widgets/payment_fields.dart`
(not rewritten) and the Payment screen now imports them. The Cancel/Save buttons and the
sub-screen header were likewise shared (`form_buttons.dart`, `screen_header.dart`) between
Edit Profile, Payment Methods and Add Payment Method.

**Logged plainly, as the same accepted simplification as `confirm_subscription_payment`
(#4/#16), not a new one:** with no payment processor, the brand and last 4 are
**derived client-side from the typed number** (`lib/utils/card_brand.dart`: Visa 4..., Mastercard
51-55 / 2221-2720, Discover 6011 / 644-649 / 65, otherwise a generic "Card") purely so a
saved card can display as "Visa •••• 4242". It is a display guess, never used to decide
validity. A real processor returns the true brand and last 4 with a token and this goes away.

**No Figma frame for the add form.** The design has the "Add New Payment Method" button
but not the form behind it (the only card fields in the file are on Complete Payment,
`1213:1281`), so Add Payment Method is built to match Complete Payment plus the other
Profile sub-screens' header/card/buttons -- the same situation as Payment Success (#23). Also
added, none in the design: an empty state, a failed-load retry, a confirm dialog before
deleting ("Remove this card?"), error SnackBars, and a "Set as default" checkbox on the add
form (hidden for a user's first card).

**Plain table access, no RPC** (self-owned rows, same reasoning as Task 2 / decision #3): the
existing RLS policies (`auth.uid() = user_id` for select/insert/update/delete) already cover
it. What RLS can't express is the rule *between* rows, so that moved into the database.

**The DB-level enforcement** (migration `20260923100000_payment_methods_default_enforcement.sql`):
- **The hard guarantee** is a **partial unique index** `unique (user_id) where (is_default)`.
  The old `AFTER` trigger that cleared the previous default was a convenience with nothing
  behind it -- two concurrent requests could both end up default.
- **A BEFORE insert/update trigger** (`enforce_single_default_payment_method`, replacing the old
  AFTER one) makes "set this default" one atomic step: it clears the user's other default
  first, then lets the write through -- so the client never unchecks the old default and
  sends one request. It also makes a user's **first card the default** whatever the client
  asked for, and rejects an already-expired card on insert (year *and* month).
- **An AFTER DELETE trigger** (`promote_default_payment_method`): deleting the default
  promotes the newest remaining card, so a user who has cards always has a default.
- Considered and left out: forbidding a client from un-defaulting the only default with a
  direct `is_default = false` update. The app never does it, and it would need a trigger-depth
  check; noted rather than built.
- **A latent bug in the original schema, found on the way and fixed:** the table's
  `CHECK (exp_year >= extract(year from now()))` is re-evaluated on **every** UPDATE of a row,
  so once a saved card's year had passed, *any* update of it failed -- including the trigger
  clearing an old default, which would have made "set a new default" fail whenever the old
  default card had expired. It is replaced by a plain year-range CHECK, with "not already expired"
  checked once, on insert only.
- A single statement that sets `is_default = true` on several of one user's rows is refused by
  Postgres itself (SQLSTATE `27000`, "tuple to be updated was already modified by an operation
  triggered by the current command") -- a block, never two defaults. The app only ever updates
  one row at a time.

**Verified live** against the dev Supabase project in the SQL Editor (real role impersonation,
one `DO` block ending in a deliberate `RAISE EXCEPTION` so it all rolled back; afterwards 0
cards left, both triggers enabled, the index present), with two real users (A, B):
- **Cross-user (RLS):** B listing A's card **0 rows**; B deleting it **0 rows**; B updating it
  **0 rows**; B inserting a card for A **blocked, 42501**. `anon` listing **0 rows**, inserting
  **blocked, 42501**.
- **Default rules, as B:** a first card added with `is_default = false` is **stored as default**;
  adding a 2nd card as default leaves **exactly 1 default** (the new one; the old is cleared by
  the trigger, not the client); a 3rd non-default card leaves 1; **one** `UPDATE` setting the 3rd
  as default leaves 1 (the 3rd); the direct-SQL "set every card default in one statement" attempt
  was **blocked (27000)**; an already-expired card **rejected (`card_expired`)**; a non-digit last4
  **rejected (23514)**; a full 16-digit number in `last4` **rejected (22001)**; deleting the
  default **promoted the newest remaining card** (1 default left); deleting every card works.
- **The index alone, trigger disabled** (simulating a race or a bug, as B): a direct `UPDATE`
  making a 2nd default **blocked, 23505**; a direct `INSERT` of a 2nd default row **blocked, 23505**.
- Dart: `flutter analyze` (only the two pre-existing Create Account lints), `flutter test` 106/106
  (81 + 25 new: card brand, the model, and both screens with a fake service that decides how the
  "server" reacts -- one test has it promote a *different* card than a client-side "next card"
  would, to prove the list shows what the server returned). Layout at 375 wide with a real
  font matches the design: add button 343x48, both cards 343x125.03, 16 between cards.

**Not verified:** the screens have not been looked at running in the app, and the add -> list ->
set default -> delete flow has not been exercised end to end against the real backend from the
app (the developer's click-through); the emoji tile (💳) renders with the platform's emoji font.
The default card's "Expires" line spills into the card's bottom padding by 4px, as the Figma export
has it. The SQL Editor also kept "Untitled query" entries from these runs in its Private list.

### 44. Sprint 5, Task 4 -- Notification settings, local-only

Built the real Notification settings screen
(`lib/screens/profile/notification_settings_screen.dart`, Figma frame `1217:2539`,
exact values via the REST API as in #20/#40-#43), replacing the stub behind Profile's
"Notifications" row. (The Home bell is a different thing -- the notifications *feed*, still
a stub, decision #32.)

**Local-only, as decided at the Sprint 2 checkpoint -- and kept that way on purpose.** The
seven toggles (Push, Email, SMS, Sound & Vibration; Event Reminders, Allowance Alerts,
Promotions & Offers) are saved to the device with `shared_preferences` through a new
`NotificationPrefs` (`lib/services/notification_prefs.dart`), the same thin-wrapper style as
`OnboardingPrefs`. **No table, no RPC, no backend storage.** Whether these preferences ever
belong in the database is tied to the still-open question of what a notification even is
(its schema, delivery, unread state -- decision #32 and the open-questions list), so building
storage for them while that is unresolved would be deciding it by accident. The
"Notification preferences storage" open question is now closed as *local*.

**No network calls at all.** The screen and `NotificationPrefs` import only
`flutter/material` and `shared_preferences` (plus pure-UI project widgets). This is not just
asserted: `test/notification_prefs_test.dart` follows every import of both files
transitively and fails if anything other than those two packages -- in particular
Supabase, `http`, or `dart:io` -- appears anywhere in the chain. The user id used to
namespace the saved keys is read by the *caller* (Profile) from the local session, so the
screen itself never touches the Supabase client.

**Behaviour**
- Each flip is shown at once and written to the device immediately -- the design has no Save
  button, only "Done", which just leaves the screen.
- **Persists across restart** (proven with a simulated close-and-reopen, below).
- Defaults are the states drawn in Figma: **SMS off, the other six on** -- nothing is written
  until the user changes a toggle, so a fresh install stores nothing.
- Keys are `notification_settings.<user id>.<toggle>`, so on a phone shared by two people one
  person's choices don't become the other's. (With no user, they belong to "the device".)
- If a write fails (storage full/unavailable), the switch goes back to what is actually stored
  and a SnackBar says so, rather than showing a value that won't be there next time.
- **The toggles only record preferences.** Nothing in the app sends push, email or SMS yet
  (and the notifications feed is a stub), so nothing acts on them yet. That is stated on
  purpose so a working-looking toggle isn't mistaken for a working notification system.

**Design details kept as exported:** the "Notification Types" title sits on a light-grey strip
(`#F3F4F6`) in the Figma file, unlike the gradient band above it -- reproduced as designed;
the toggle icons have slightly different sizes (15.31-20px); the switch is a custom 44x24 pill
(red `#EC003F` on, grey `#D1D5DC` off, 16px white thumb) rather than Material's `Switch`,
announced to screen readers as a toggle with its label. Icons are Material outlines, the same
trade-off as #26/#40.

**Verified:** `flutter analyze` (only the two pre-existing Create Account lints) and
`flutter test` 120/120 (106 + 14 new). The persistence tests write through the real
`SharedPreferences` API, drop the in-memory cache (`resetStatic`) to simulate closing the app,
and read the values back; the screen tests do the same through a fresh screen instance. Layout
at 375 wide with a real font matches Figma: Communication card 343x482.57 (482.59), Notification
Types card 343x404.06 (404.07), rows 70.51/90.51/70/90, 24 between rows and cards, switch 44x24
16.5 from the card edge.

**Not verified:** the screen has not been looked at running in the app, and "no network" is
proven by the import check and by the tests running with the Supabase client never
initialised -- not by watching the browser's Network tab (the developer can confirm that in one
click-through: open Profile > Notifications, flip toggles, and watch the tab stay empty).

### 45. Sprint 5, Task 5 -- Privacy & Security: real Change Password, Delete Account as a request queue, disabled placeholders

Built the Privacy & Security screen (`lib/screens/profile/privacy_security_screen.dart`,
Figma frames `1217:2644` default and `1217:2946` with the password form open),
replacing the stub behind Profile's "Privacy & Security" row. Three of its decisions
were put to the project owner before any code was written, and are recorded here as
**their explicit answers**:

**1. Biometric Authentication and Two-Factor Authentication -> disabled placeholders.**
The earlier "placeholders" answer was not actually written down anywhere in this log
(a search for biometric/2FA/auto-lock found nothing), so it was re-confirmed rather than
assumed to have carried forward. They are drawn as designed but switched **off, dimmed,
inert and marked "(Coming Soon)"** -- the same way the design already labels Dark Mode --
instead of working-looking switches that record a value and do nothing: a member could
believe 2FA was protecting them when it isn't. No storage, no behaviour.

**2. Auto-Lock -> placeholder too.** It shares one toggle between two different
features -- "lock after inactivity" (an idle timer plus a lock screen that asks for the
password) and "require biometric to unlock" (needs `local_auth` and Biometric to be real)
-- and neither is built. Note the design draws Auto-Lock **on**; it is shown **off** here
so nothing implies the app auto-locks.

**3. Delete Account -> a request queue (option b), not self-service deletion.** Supabase's
client SDK deliberately can't delete an auth user (an admin/service-role operation). A
`SECURITY DEFINER` function that deletes the caller's own `auth.users` row was rejected:
irreversible deletion of auth data through a client-callable function is real risk for
little training value. Instead (migration `20260924100000_deletion_requests.sql`):
- A new `deletion_requests` table (status enum `pending`/`cancelled`/`completed`), RLS on.
- A client can **insert** a request for itself **only as `pending`** and **read its own**.
  There is **no UPDATE or DELETE policy**: a member can't edit, cancel or hide a request from
  the app. Cancelling/processing one is a **manual staff step** (dashboard / service role) --
  deleting the auth user there cascades to the profile, its data, and the request row.
- A partial unique index allows **one open request per user**, so a double tap or a second
  device can't queue duplicates (the app then just shows the existing one).
- **Making a request deletes nothing, deactivates nothing and signs nobody out.** The screen
  says so plainly ("Deletion requested on M/D/YYYY ... Your account stays active until then").
  A confirm dialog comes first.
- There is no tooling to process requests yet -- that is deliberately a human step for now.

**Change Password is real, and asks for the current password first.** Supabase's
`updateUser(password:)` does not require it: anyone holding a live session could change the
password. That is the risk -- a phone left unlocked and open, its password silently changed by
someone else. So `AuthService.changePassword` re-authenticates with the user's own email and the
password they just typed (`signInWithPassword`) **before doing anything else; if that fails for any
reason, `updateUser` is never called** (a wrong password, a rate limit, a network error, no
session -- each has its own message, and a network failure is not misreported as a wrong
password). Only then does it update. Afterwards it also **signs out every other session**
(`signOut(scope: others)`, best effort, an unrequested extra: a stolen session should not survive
the password that was changed to lock it out; the current session stays signed in).
- **Strength rules are decision #10's, shared not rewritten:** the password rule moved out of
  Create Account into `Validators.password` (8+ chars, upper + lower + number, each missing rule its
  own message) and both screens call it -- the same move made for the phone rule in #42. Client-side
  only; the real enforcement stays Supabase's own password policy. The new password must also differ
  from the current one.
- Fields are hidden by default with a show/hide eye per field; nothing typed leaves the screen.

**Other things kept simple:** "View Privacy Policy" and "Terms of Service" open the coming-soon page --
no policy or terms text exists to show.

**Figma access for this screen.** The Figma REST API returned 429 with `Retry-After` ~58h (starter
plan, low limit tier -- exhausted by the earlier full-file downloads), so this screen's values were read
from the Figma app's Design panel in the browser: the card/row/button/input dimensions, paddings, gaps,
colours and type styles for Password, Privacy and the form; the Security Options card follows the
identical Notifications toggle pattern (its 364.07 total was confirmed). A few values not read directly
(the shield icon size in the band, icon sizes for the three toggles, the eye icon's exact offset, the
"Change Password" icon-to-label gap, which reuses Edit Profile's measured 17) are inferred from the
shared pattern -- worth a check once the API allows.

**Verified live (the part the task asked for -- Delete Account does exactly what was decided and
nothing more).** In the Supabase SQL Editor with real role impersonation, in one `DO` block ending in a
deliberate `RAISE EXCEPTION` so everything rolled back (afterwards the table held 0 rows, RLS on, both
policies and the unique index present), with two real users (A, B):
- B files a request for its own account: stored **`pending`**. B files a second: **blocked, 23505**
  (one open request). B files one for A: **blocked, 42501**. B files one already `completed`: **blocked,
  42501**. B can see **1** request (its own; A's is hidden). B tries to cancel its own: **0 rows changed**;
  to delete its own: **0 rows removed**; it is still `pending`. `anon` reading: **0 rows**; `anon` filing:
  **blocked, 42501**.
- **"Nothing more":** a snapshot of row counts across `auth.users`, `auth.sessions`, `profiles`,
  `subscriptions`, `usage_allowances`, `door_access_logs`, `event_reservations`, `payment_methods`,
  `id_documents`, `notifications` and `storage.objects` was identical before and after the request, and
  **B's `auth.users` row and profile row were byte-for-byte identical** (compared by hash). The only
  change anywhere was `deletion_requests` gaining its rows.
- Dart side: `flutter analyze` **clean (no issues at all)**, `flutter test` **155/155** (120 + 35 new).
  `test/change_password_test.dart` proves the ORDER with a fake auth client that logs every call
  (`signIn(current)` -> `updateUser(new)` -> `signOut(others)`) and that a wrong current password, a
  rate limit, a network failure or a missing session all leave `updateUser` uncalled.
  `test/privacy_security_screen_test.dart` covers the screen: placeholders inert, empty current
  password rejected, each #10 rule's message, same-as-current, mismatch (none reach the service), a
  valid form sends current + new, a wrong current password shown under its field, and Delete Account
  (one request, "only a request" notice, Cancel sends nothing, an existing request shown on arrival,
  failure keeps the button).
- Layout at 375 wide with a real font: Password card 343x209.54, Privacy card 343x249.54 (both
  identical to Figma), 24 between cards, inputs 309.97x36. The Security Options card is taller than
  Figma's 364.07 by the "(Coming Soon)" lines added under each placeholder.

**Not verified:** Change Password has **not been exercised against the live Auth API** -- the tests use a
fake client, so the real `signInWithPassword` -> `updateUser` -> `signOut(others)` sequence needs a
click-through with a throwaway account (change it, confirm the old password stops working and the new one
works). The screen has not been looked at running in the app. Deliberately not done: processing a deletion
request, and any Privacy Policy / Terms text.

### 46. Sprint 5, Task 6 -- Help & Support: the one real FAQ answer, honest placeholders for the rest

Built Help & Support (`lib/screens/profile/help_support_screen.dart`, Figma frame
`1217:3158`), replacing the stub behind Profile's "Help & Support" row.

**Contact cards (Live Chat / Email Us / Call Us) are static, as asked.** The design shows only
a label and a one-line description -- no real email address, phone number, or chat link exists
anywhere in the export -- so there is nothing to wire up: no `mailto:`/`tel:` intent, no chat
integration, not even tappable. A test taps where a card is and confirms nothing happens.

**FAQ accordion: exactly one real answer, three honest placeholders.** The Figma export has
four real questions but only the first ("How do I use my QR code to enter the café?") has an
answer -- the same "1 of 4 FAQ answers exported" gap flagged as open since the Sprint 2
checkpoint (and referenced again in decision #30). The other three show a plain **"Answer not
available yet."** -- never a plausible-sounding invented answer standing in for real copy. This
was the task's explicit acceptance bar, and it's checked in the test two ways: the placeholder
text is the literal same string for all three (not three separately-written fake answers), and
the whole rendered page is scanned for phrases a plausible fabricated answer would plausibly use
for each specific question (e.g. "renews"/"billing cycle" for the allowance question, "up to 2
guests" for the guest-policy question) and asserted absent.
- The accordion is **exclusive** -- opening one question closes whichever was open -- and the
  first item **starts open**, matching the one state the Figma export actually shows (there's no
  second exported state to know whether multiple-open was ever intended).
- The rows are literally exported as HTML `<details>`/`<summary>` elements (visible in the
  layer names) -- the widget mirrors that shape (one row's body exists only while its question is
  the expanded one) rather than just toggling visibility.

**Resources** (User Guide / Membership Benefits / Community Guidelines) have no content behind
them, so each opens a coming-soon page -- the same pattern as Privacy & Security's Privacy
Policy / Terms of Service (#45).

**Figma access, same situation as #45.** The REST API was still rate-limited (`Retry-After`
from the earlier full-file downloads), so this screen's values were read from the Figma app's
Design panel: contact-card dimensions (342.98x193.03, padding, and critically the internal
`gap: 36` between icon/title/description -- confirmed by measuring the total card height, which
was 24px short with a smaller assumed gap and matched exactly once both internal gaps were set
to 36), the FAQ card/header/row structure (row heights 80 collapsed / 176.51 expanded, question
16px regular, answer 14px regular, hairline `#F3F4F6` dividers), and the Live Chat icon colour
(`#EC003F`, confirmed via the panel). **Two colours are not confirmed via the API**: Email Us and
Call Us are given purple (`#9810FA`) and green (`#00A63E`) respectively, inferred from the
rendered design rather than measured -- flagged in code and worth a real check once the API
allows, the same category of caveat as decision #20's early passes before API access existed.
**One geometry value was judged rather than taken literally**: the card's exported padding read
as asymmetric (0 on one side), which -- like decision #28's progress-bar-width finding in this
same export -- reads as an artifact of the original React/shadcn layout rather than a deliberate
design choice; kept symmetric at 24, matching every other card in this app.

**Verified:** `flutter analyze` clean, `flutter test` **164/164** (155 + 9 new in
`test/help_support_screen_test.dart`). Layout matches Figma exactly once measured at 375 wide
with a real font: contact card 343x193.03, 16 between contact cards, 24 before/between/after the
FAQ and Resources cards.

**Not verified:** the screen has not been looked at running in the app; the two inferred icon
colours are worth a visual check.

### 47. Sprint 5, Task 7 -- App Settings: real cache management, everything else visual-only (Sprint 5 complete)

Built App Settings (`lib/screens/profile/app_settings_screen.dart`), replacing the last stub
behind Profile's rows -- Sprint 5 is now fully built out.

**Dark Mode and Language: exactly decision #5, re-applied, not re-litigated.** Both are drawn
for visual accuracy and are fully inert -- Dark Mode off with the design's own "(Coming Soon)"
label, the language list always showing English selected with no row tappable. Nothing new was
decided here; this task just had to not quietly build more than #5 already settled.

**Animations, Sound Effects and Haptic Feedback: the same treatment, for a narrower reason.**
The task's own acceptance bar is "no functionality built beyond what's decided in scope," and
only Dark Mode/Language were explicitly in scope (from #5) -- these three weren't asked for
either, so they're drawn at the design's shown state (on) and are inert, with no
`AnimatedContainer` global setting, no app-wide `HapticFeedback` calls wired up. **Worth flagging
explicitly so it isn't "helpfully" merged later:** this screen's "Sound Effects" (general UI
sound) is a *different* setting from the Notifications screen's real, working "Sound &
Vibration" toggle (decision #44, notification sound specifically) -- same kind of label overlap,
different meaning, as decision #33's two different "guests" fields. Kept as separate storage and
separate widgets on purpose.

**Data & Storage is real -- the task's explicit "your call."** This app has almost nothing to
manage locally (grep confirms the only real use of Flutter's image cache anywhere in the app is
`ProfileAvatar`'s `Image.network` for the profile photo's signed URL), so the real feature stays
proportionate to what the app actually has:
- **"Cache Size" shows the real, computed number of bytes** in Flutter's image cache
  (`PaintingBinding.instance.imageCache.currentSizeBytes`, via the new `AppSettingsService`) --
  **never** the design's fabricated static "12.5 MB". Same principle as #32's notification badge
  and #46's FAQ answers: a plausible-looking invented number is exactly the kind of fake data
  this project avoids, even somewhere this low-stakes.
- **"Clear Cache" really clears it** (`imageCache.clear()` + `clearLiveImages()`) and the shown
  size updates immediately -- meaningful specifically because it forces the cached profile photo
  to re-fetch, not a no-op gesture.
- **"Clear All App Data" really wipes every local `shared_preferences` value** (the onboarding
  flag, any saved notification settings) after a confirm dialog, **then signs the device out for
  real** -- a device with no local preferences shouldn't still look signed in. The sign-out step
  is injectable (`onDataCleared`, defaulting to the real `signOutAndShowLanding`) purely for
  testing, the same reason Edit Profile/Payment Methods/Privacy & Security inject their services
  -- widget tests can't initialise a live Supabase client, and this project's own established
  pattern (ProfileScreen/HomeScreen) is to keep the real sign-out call itself thin and verified by
  click-through, not by mocking Supabase.
- The footer shows the **real** app version (`pubspec.yaml`'s `1.0.0+1` → "Version 1.0.0",
  "Build 1") instead of the design's mock "Build 2024.01.14" -- the same "replace demo data with
  something real" move as decision #3's member-ID format.

**Verified:** `flutter analyze` clean, `flutter test` **179/179** (164 + 15 new).
`test/app_settings_service_test.dart` proves the cache claims against Flutter's *real* image
cache (a trivial in-memory `ImageProvider` puts a real decoded image in it -- no network, no
fixtures) and against a real `SharedPreferences` instance, not a fake standing in for either.
`test/app_settings_screen_test.dart` covers the screen: every placeholder is provably inert (its
`SettingSwitch.onTap` is null, and tapping changes nothing), Cache Size/Clear Cache use an
injected fake service to prove the real service methods are called and the shown size updates,
and Clear All App Data is proven end-to-end once with the real `AppSettingsService` (real
`SharedPreferences` actually ends up empty) and once with a fake to prove the confirm-then-clear-
then-sign-out ordering. Layout at 375 wide: 24px between all three cards, no overflow.

**Not verified:** the screen has not been looked at running in the app, and the
Clear-All-App-Data → real sign-out path (via the real `signOutAndShowLanding`, not the injected
test double) hasn't been exercised against the live Supabase client -- worth one click-through
with a throwaway account: clear all data, confirm it lands on Auth Landing, and confirm signing
back in still works normally (nothing server-side was touched).

**Sprint 5 is now complete:** Profile (#40), Edit Profile (#42), Payment Methods (#43),
Notification settings (#44), Privacy & Security (#45), Help & Support (#46), App Settings (#47).
Every row on the Profile tab now opens something real except **Upgrade Membership**, which has
no flow to send it to yet (decision #25's deferred re-subscribe gap).

### 48. Sprint 6, Task 1 -- Closing Sprint 5's live-verification gaps: Change Password and Clear All App Data confirmed live

Sprint 5 shipped Change Password (#45) and Clear All App Data (#47) verified only against a
fake auth client (proving call order and logic), not the real Supabase Auth API -- flagged at
the time as open items, and Sprint 6 Task 1 exists specifically to close them. Per the
established split (decision noted after #36: database/SQL verification is driven directly by the
assistant, app-level click-through is the user's own), this was the user's click-through, done
against the real dev project with a throwaway account. **Both confirmed working, all steps as
expected:**

**Change Password, against the live Auth API:**
- Wrong current password: rejected inline ("Current password is incorrect."), form stayed open,
  nothing changed -- confirms `AuthService.changePassword`'s re-authentication step (`signInWithPassword`
  with the typed current password) genuinely runs against the real API before anything is touched,
  not just in the fake-client test's call-order check.
- Correct current password + a new password meeting decision #10's rule: succeeded, form closed,
  "Password updated." shown.
- **Signed out and back in with the new password: worked.** Confirms `updateUser(password:)` really
  took effect server-side, not just that the mocked call was made.
- Signing in with the old password afterward: failed, as expected -- the old password is genuinely
  no longer valid.

**Clear All App Data, against the live Auth API:**
- Cancel on the confirm dialog: no effect, stayed signed in.
- Confirming ("Clear & Sign Out"): landed on Auth Landing immediately.
- **Signed back in with the same account afterward: worked normally, active membership intact** --
  confirms the action only ever touched local device state (preferences + the local session), never
  anything server-side, matching the design in #47.
- The one expected side effect flagged ahead of time (wiping the local "seen onboarding" flag along
  with everything else, so a reload before signing back in can show onboarding again instead of Auth
  Landing) was not specifically re-checked, but doesn't affect either acceptance point above.

**No bugs found, nothing decided differently.** Both Sprint 5 open items (Sprint 5 report's items 1
and 2) are now closed. Remaining open items from that same report: item 3 (`ComingSoonScreen`'s dead
`showSignOut` flag, no remaining callers) is still open, earmarked for a real cleanup pass later in
Sprint 6 per the user's own note when reviewing the Sprint 5 report; item 4 (Figma REST API rate
limit) status wasn't rechecked as part of this task; item 5 (leftover Supabase SQL Editor "Untitled
query" entries / possibly-still-open Chrome tabs from Sprint 5's verification work) is still open,
manual cleanup on the user's side.

### 49. Sprint 6, Task 2 -- Dead code audit: stub-era scaffolding removed

Audited the repo for leftovers from before every screen route had a real destination
(the specific gap flagged as item 3 of the Sprint 5 report), and for anything in the
same spirit found along the way. Every item below was confirmed by grep to have zero
remaining callers/usages before being removed -- nothing here changed behaviour.

**`ComingSoonScreen.showSignOut`** -- the flag, its default, the `if (showSignOut)`
button, and the `_signOut` method underneath it that only that button called (and its
now-unused `auth_landing_screen.dart`/`supabase_client.dart` imports). Added for decision
#15's task ("a way to actually sign out and verify signing out returns to Landing" while
Home/Choose Membership were still stubs) and dead since the real screens replaced those
stubs across Sprint 3-5. No call site anywhere passed `showSignOut: true`.

**`ComingSoonScreen.subtitle`** -- same shape: the field and its `if (subtitle != null)`
render line, added so ID Upload's subscription id stayed visible while that screen was
still a stub (decisions #17/#18). Dead since ID Upload became a real screen; no call site
passes `subtitle:` anymore. The now-pointless `Spacer()` that only existed to push the
Sign Out button to the right was removed with it.

**Nine `.gitkeep.dart.txt` placeholders** -- `git rm`'d from `lib/models/`,
`lib/screens/auth/`, `lib/screens/events/`, `lib/screens/home/`,
`lib/screens/membership/`, `lib/screens/profile/`, `lib/screens/qr_access/`,
`lib/services/` and `test/`. These existed only so the (then-empty) folder would be
tracked by git before any real file existed in it; every one of those folders now holds
real files.

**`lib/providers/`** -- deleted entirely (it held only its own `.gitkeep.dart.txt`) now
that `provider` is also gone from `pubspec.yaml` (below) -- there is nothing left to
reserve the folder for.

**`web_entrypoint.dart`** -- an empty (0-byte) file at the repo root, referenced by
nothing (`pubspec.yaml`, `web/index.html`, build configs) -- deleted. The real entry
point remains `lib/main.dart`.

**Five unused `pubspec.yaml` dependencies** -- `provider`, `http`, `sqflite`, `path`,
`cupertino_icons`, none imported anywhere in `lib/` or `test/` (already flagged as such
in `MASTER.md`'s original audit, decision #40-era). A different category from the four
items above -- not navigation-stub scaffolding, just dependencies added ahead of
features that ended up built a different way (`sqflite`/`path` for on-device reservation
storage, superseded by storing them server-side in Postgres instead -- see decisions
#37/#38) -- called out to the user separately from the task's literal "screen route"
wording, and removed with their explicit go-ahead. Removed from `pubspec.yaml`;
`pubspec.lock` regenerated with `flutter pub get`.

**Not touched, and why:** `findPendingSubscription()`/`PendingSubscription` -- already
fully removed as part of decision #22's own cleanup; re-checked, nothing remains.

**Verified:** `flutter analyze` -- clean, no issues (confirms no orphaned imports were
left behind by any of the above). `flutter test` -- 179/179, unchanged, since nothing
removed was reachable from any live code path. `flutter pub get` succeeded after the
`pubspec.yaml` edit.

---

### 50. Sprint 6, Task 3 -- Figma fidelity re-check via the Figma app, and decision #20's pattern extended to two more screens

The Figma REST API was still rate-limited (429, ~38h retry-after) when this task
started, so the user chose the Figma app in browser over waiting. Re-verified all 4
Onboarding slides, Auth Landing, Sign In, Create Account, and Forgot Password (built
from PDF-estimated values before real Figma access existed, per the Sprint 3
checkpoint's explicit deferral) against real, inspected design data for the first time,
plus re-checked Help & Support's two inferred icon colors and App Settings' spacing.

**Confirmed correct, no changes:** all 4 Onboarding slides' card geometry, shadows, icon
badge gradients/shadows, heading/body typography, and spacing gaps -- exact matches
throughout. Help & Support's two inferred icon colors (`#9810FA` Email Us, `#00A63E`
Call Us) were both exactly right. App Settings' section spacing (24px gaps, 16/32
padding) matched exactly, and its card border already used the correct Figma hairline
value (it was Sprint 5 work, done with real Figma access from the start).

**Found and fixed -- a hairline card border, present in Figma but missing from four
screens:** Sign In, Create Account, and Forgot Password's cards had no border at all
in code (shadow only); Auth Landing had one, but at the wrong width. Figma specifies
`Border.all(color: Colors.black @ 10%, width: ~0.515)` on the three form cards and
`Border.all(color: #FFCCD3, width: ~0.515)` on Auth Landing's -- the same fractional
hairline value already correctly used by App Settings' `_hairline` constant (Sprint 5).
Auth Landing's color was already right; only its width (1.55, a PDF-era guess) was
wrong. Added the missing border to the three form screens and corrected Auth Landing's
width, all to `0.515`.

**Found, discussed, deliberately left alone -- two copy differences that predate
security decisions already made:** Figma's Forgot Password copy says "we'll send you a
**verification code**" / button "Send Verification Code"; the real screen implements a
magic-link email reset (`resetPasswordForEmail`) with anti-account-enumeration wording,
by design (see the screen's own code comments). Figma's Create Account password helper
says "Must be at least 8 characters"; the real rule is stricter
(`Validators.password`, decision #10: uppercase, lowercase, and a number too). In both
cases the code's current wording accurately describes what the app actually does and
Figma's text simply predates the decision -- the user confirmed keeping the current
wording over changing it to match Figma's now-stale copy.

**Found, not actioned -- a second, unbuilt registration-style Figma frame
(`RegistrationForm`):** sits near "Choose Membership" / "Complete Payment", structurally
different from the real, already-matching Create Account screen (`SignUpScreen` in
Figma) -- no password field, but a Subscription Plan selector and an ID Upload step,
ending in "Continue to Payment". Doesn't correspond to anything built. Left alone per
the user -- worth its own scoping discussion if it turns out to represent an intended
future flow, not something to build as a byproduct of a fidelity check.

**Also noted, not actioned:** Onboarding slide 3's ("Monthly Allowances") icon circle
has an extra `black @ 20%` fill layer in Figma that slides 1, 2, and 4 don't have --
almost certainly import noise from the HTML-to-Figma pipeline (same root cause as
decision #28), not a real design intent; no code change made.

**Verified:** `flutter analyze` -- clean. `flutter test` -- 179/179 passing (border
additions are visual-only, no widget tree/semantics changes the existing tests assert
on).

---

### 51. Sprint 6, Task 4 -- Migration file audit, and proving handoff actually works from empty

Two-part task: (1) confirm every schema change in this log has a corresponding
migration file, correctly ordered; (2) prove -- not assume -- that
`supabase/migrations/` alone reproduces the real database from nothing, since "the
dev project has the right state" and "the migration files reproduce that state from
scratch" are different claims and only the second is what the company will actually
run on handoff.

**Part 1 -- static audit, clean.** Read all 13 migration files and cross-referenced
every schema/RLS/RPC/cron/storage change described anywhere in this log. Every one
has a matching migration file; filenames sort into correct dependency order (e.g. the
`pending` enum-value migration commits before the migration that uses it, required
because Postgres forbids using a new enum value in the same transaction that added
it); no acknowledged "never backported" gap existed in the log's own text --
including decision #16's `anon` EXECUTE-revoke fix, which explicitly says it went
into both the live DB and the migration file at the time, and it's there.

**Part 2 -- the real test.** Getting a genuinely empty environment took three tries:

- A second cloud Supabase project was blocked -- the account is capped at 2 free
  projects total, **account-wide across every org**, not per-org (confirmed by
  testing: switching from Husam-ali-Alhajj's Org to a different org the same account
  administers, "Iamma", hit the identical cap).
- The Docker/Supabase-CLI local-stack route (`supabase start`) was tried next, but
  the first-run image pull exhausted available system memory badly enough that
  Claude Code's own background-process monitor killed it, and even `docker ps`
  was unresponsive afterward.
- The user's call: since the dev project held no data worth keeping (test accounts
  and fixtures only), don't spin up a second environment at all -- wipe everything
  the migrations are responsible for **in the real Rosewater Cafe project itself**,
  replay all 13 files top-to-bottom, and compare the schema before vs. after. This
  both tests the claim (does empty + migrations reproduce what was there) and
  rebuilds a clean workspace in the same action.

**Method:** captured a full schema fingerprint of the live project first (one SQL
query returning table/column definitions, RLS-enabled flags + policies, full function
definitions via `pg_get_functiondef` -- which embeds `SECURITY DEFINER` and
`search_path` -- function EXECUTE grants, the `pg_cron` job, storage buckets +
their policies, and the `membership_plans` seed rows, as one JSON blob). Then tore
down everything the migrations own: unscheduled the cron job, deleted both storage
buckets via the Storage API (raw `DELETE` on `storage.objects` is blocked by
Supabase's own `protect_delete()` guard trigger -- "Use the Storage API instead" --
so the dashboard's bucket-delete action was used instead, which goes through that
API correctly), dropped every table/function/type the migrations create, and cleared
`auth.users` (confirmed by the user: test accounts only, nothing to preserve). Then
ran all 13 migration files in exact order via the SQL Editor, pasting each file's own
committed content unmodified. Then took the same fingerprint again and diffed the
two, structurally (arrays sorted by stable keys first, so catalog-scan ordering
differences don't register as false diffs).

**Result: every category matched exactly** -- columns, RLS-enabled flags, RLS
policies, indexes, enum values, triggers, the cron job, storage buckets, storage
policies, function grants (the `anon`-revoke hardening, all 52 grant rows), and all 3
seed rows in `membership_plans` including their `features` arrays. The only
difference found was in 4 functions' stored body text
(`cancel_subscription`, `enforce_single_default_payment_method`,
`lock_profile_email`, `promote_default_payment_method`) -- and stripping comments
and whitespace from both sides showed the difference is **purely
formatting/line-endings/comments**, not logic: the live versions had at some point
been applied with different whitespace than what's in the committed migration files
(one was squished onto a single line with no comments at all), most likely from an
earlier SQL Editor paste that predates the final migration file text. No behavioral
drift found anywhere.

**Also found, not a gap:** `rls_auto_enable()`, an event-trigger function that
appeared in both the before and after fingerprints identically -- not created by any
migration in this project. This is Supabase's own platform-level "automatically
enable RLS on new tables" project feature (the checkbox seen on project creation),
not something our migrations are responsible for or need to reproduce.

**Net effect:** the live Rosewater Cafe project is now exactly what
`supabase/migrations/` produces from empty -- no leftover test data, no stale
accounts, nothing hand-applied and never captured in a file. Handoff is proven to
work, not assumed.

---

### 52. Sprint 6 -- Delete Account made real self-service, replacing decision #45's request queue

The user asked directly: after a full functional audit of every button/toggle across
Settings, Notifications, Privacy & Security and Help & Support (which surfaced Delete
Account's actual behaviour -- files a request for staff to process, deletes nothing
immediately), they wanted it to actually delete the account, not queue a request.

**The tradeoff decision #45 made was surfaced first, not silently reversed.** Its
exact reasoning: *"A `SECURITY DEFINER` function that deletes the caller's own
`auth.users` row was rejected: irreversible deletion of auth data through a
client-callable function is real risk for little training value."* That was this
assistant's own call at the time, not something the user had weighed in on directly
-- worth saying so before rebuilding on top of it. Two real implementation paths
exist (a client-callable Postgres function vs. a Supabase Edge Function calling the
real Admin API), each with different tradeoffs; put to the user rather than picked
alone. **Their answers:** a database function (the existing migration-only
architecture, no new infrastructure), and no audit trail kept after deletion.

**What changed:**

- **New migration** (`20260925100000_delete_own_account.sql`): `delete_own_account()`
  -- `SECURITY DEFINER`, `search_path` pinned, reads `auth.uid()` itself (never a
  caller-supplied id, the same rule every RPC in this project follows), and does
  exactly `delete from auth.users where id = v_user_id`. `EXECUTE` revoked from
  `public`/`anon`, granted only to `authenticated` -- verified live afterward
  (`pg_proc.prosecdef = true`; grants show only `authenticated`/`postgres`/
  `service_role`, no `anon`). Deleting the `auth.users` row cascades through the FK
  chain already in place from decision #3 onward (`profiles.id references
  auth.users(id) on delete cascade`, and every one of a user's own rows cascades
  from `profiles` the same way) -- nothing is left behind by construction, not by a
  follow-up cleanup step.
- **The `deletion_requests` table, its policies, and the `deletion_request_status`
  type are dropped** (same migration) -- a request queue has no remaining purpose
  once deletion is immediate, and the user explicitly chose not to keep a lasting
  record (which would've needed a separate, non-cascading table anyway, since this
  one would disappear along with everything else the moment its owning profile
  does). Verified live: `information_schema.tables` shows zero rows for
  `deletion_requests`.
- **`lib/services/deletion_request_service.dart` replaced with
  `lib/services/account_deletion_service.dart`** (`AccountDeletionService.
  deleteAccount()`, throwing `DeleteAccountFailure` with an already-safe message --
  same shape as every other service in this app).
- **`PrivacySecurityScreen` updated:** the confirmation dialog now says plainly that
  deletion is immediate and permanent and cannot be undone (previously: "your
  account stays active until we process the request"); its destructive button reads
  "Delete Permanently" rather than repeating "Delete Account" verbatim, matching the
  same distinct-label pattern `AppSettingsScreen`'s "Clear All App Data" dialog
  already uses (avoids two same-text widgets on screen at once, in the UI and in
  tests). On success, the screen ends the local session and returns to Auth Landing
  via `signOutAndShowLanding` -- the account is gone server-side, so a device
  with no live account shouldn't still look signed in, the identical reasoning
  `AppSettingsScreen`'s `onDataCleared` already uses. `onAccountDeleted` is
  injectable the same way, for the same reason: widget tests can't initialise a real
  Supabase client.
- All "request queue" UI (the "already requested" notice, the pending-request check
  on screen load) is removed -- there is no longer a pending state to show.

**Verified:** `flutter analyze` -- clean. `flutter test` -- 178/178 (the old 4-test
"Delete Account is a request, not a deletion" group became a 3-test "Delete Account
is real, immediate deletion" group: confirming calls the RPC once and ends the
session; Cancel calls nothing; a failure shows a message, leaves the button
available, and never ends the session). Migration applied live and verified as
described above.

---

### 53. Sprint 6, Task 5 -- Full RLS/RPC security audit, consolidated: the actual sign-off for handoff

Every role-impersonation check this project ran piecemeal, task by task, across Sprints
2-6, run as **one** pass against the current, final schema (post decision #51's
empty-project rebuild and #52's `delete_own_account`) -- this entry is the single
written record the task asked for, not a pointer back to older scattered ones.

**Note on scope:** the task as given named "the deletion_requests isolation" as one of
the things to test. That table no longer exists (decision #52 replaced it with
`delete_own_account`) -- tested that instead, since it's the real current equivalent.

**Method.** Two real accounts were signed up live through the actual Supabase Auth API
(not synthetic ids -- matching how every earlier live test in this log worked), each
seeded with one real row in every table via the app's own RPCs and normal inserts
(a subscription via `start_subscription`/`confirm_subscription_payment`, a payment
method, a door-access log via `log_door_access`, an event reservation via
`create_event_reservation`, a notification, an id document). Every check below used
real role impersonation (`set local role`; `set local request.jwt.claims`) inside
`begin; ... rollback;` blocks for anything read/write, so nothing touched real data
except the two accounts' own rows, which were fully deleted via `delete_own_account`
itself at the end (doubling as its own live test -- see below). One real, unrelated
account already existed in the project from the user's own testing since decision #51's
wipe (`husamalhj47@gmail.com`) -- confirmed completely untouched by every check here,
since every check was scoped to the two audit accounts' specific ids throughout.

**1. Cross-user read isolation -- every table, tested at once.** Impersonated as
account B, queried account A's row count in all 8 owner-scoped tables in a single
query: `profiles`, `subscriptions`, `payment_methods`, `usage_allowances`,
`door_access_logs`, `event_reservations`, `notifications`, `id_documents`.
**Result: 0 for every one.** B correctly saw only its own profile and payment method
(1 each) in the same query.

**2. Cross-user write isolation.** As B, attempted to `UPDATE` A's row in every table
with an UPDATE policy (`profiles.full_name`, `payment_methods.is_default`,
`event_reservations.total_price`, `notifications.is_read`), then re-read A's actual
values with role reset to confirm nothing changed. **Result: all four unchanged** --
A's name stayed "Audit User A", the reservation stayed at its real $450 (3h x $150),
the notification stayed unread, the payment method's default stayed with its
original card.

**3. Same-user privilege check on `event_reservations.total_price` -- FOUND AND
FIXED.** Distinct from #2: does the table's own *owner* have more power over a column
than they should? As A, updating A's own reservation's `total_price` directly
**succeeded** -- $450 became $0.01. This is the same gap the Sprint 4 review flagged
(the UPDATE policy dropped by decision #36's migration was for direct-INSERT only;
the UPDATE policy was never touched). Checked the app first: nothing in
`lib/services/event_reservation_service.dart` or `lib/screens/events/` ever calls
`.update()` on this table -- the policy has zero legitimate use today. Presented to
the user with that context; **fixed live** (migration
`20260926100000_close_event_reservations_update_gap.sql`, drops the "Users can
update own reservations" policy entirely, leaving only the SELECT policy). Re-verified
with a fresh third throwaway account: the identical tamper attempt on a real $300
(2h x $150) reservation now leaves it at **$300, unchanged**.

**4. Direct-insert bypass on every RPC-only table.** As A, attempted a raw `INSERT`
(no RPC) into `subscriptions`, `usage_allowances`, `door_access_logs`, and
`event_reservations`, plus an `id_documents` insert claiming `verification_status =
'verified'` instead of the enforced `'pending'`. **All five blocked** -- the first
four with `42501 insufficient_privilege` (no INSERT policy exists for `authenticated`
on any of them), the fifth by its `WITH CHECK` clause rejecting a non-`pending` value.

**5. `anon` rejected on every table.** A single query as `anon` across all 9 tables
(including `membership_plans`, public reference data but `to authenticated` only) --
**0 rows on every one.**

**6. `anon` rejected on every RPC.** All 7: `start_subscription`,
`confirm_subscription_payment`, `cancel_subscription`, `log_door_access`,
`create_event_reservation`, `expire_subscriptions`, `delete_own_account` --
**every one blocked at the permission level** (`42501`), not merely failing their own
internal `auth.uid() is null` check (the distinction decision #16 originally found
mattered: a function `anon` can *invoke* but that then fails internally is a weaker,
defense-in-depth-only guarantee than one `anon` is refused outright).

**7. `expire_subscriptions` rejects `authenticated` too, not just `anon`.** Confirmed
separately: a real signed-in user calling it directly also gets `42501` -- only
`pg_cron`'s own scheduled invocation (as the database owner) can run it, exactly as
designed.

**8. Payment methods: one-default-per-user, live.** Inserting a second card with
`is_default = true` correctly cleared the first card's default (exactly 1 remained
default throughout). Deleting the default card correctly promoted the remaining card
to default automatically. Matches decision #43's original proof, re-confirmed against
the current schema.

**9. Storage bucket isolation -- both buckets.** As A: inserting an object into A's own
folder in `id-documents` and `avatars` succeeded; inserting into B's folder in either
bucket was **blocked** (`42501`). As B: selecting or updating (renaming) an object in
A's folder in either bucket affected **0 rows** -- confirmed A's real object was
byte-for-byte unchanged afterward. (Direct `DELETE` on `storage.objects` itself is
blocked for every role, including `service_role`, by Supabase's own `protect_delete()`
guard -- consistent with what decision #51 already found; object cleanup must go
through the Storage API, not raw SQL.)

**10. `delete_own_account` -- self-only scope and full cascade, live.** As B: called it,
then confirmed with an unrestricted read: B's `auth.users` row, profile, payment
method, and notification all gone (0 each) -- **and every one of A's rows was still
present, unchanged** (profile, subscription, payment method, door log, reservation,
id document, notification all still 1). Then called it as A too: A's `auth.users` row
gone, full cascade the same way. Both accounts left the project with zero residue
except in one place (next item).

**Noted, not a security issue -- informational only:** `storage.objects` rows are
**not** cleaned up by `delete_own_account`'s cascade (no FK relationship exists
between `profiles` and `storage.objects` -- Supabase's storage schema tracks
ownership by folder-path convention, not a real foreign key). A deleted user's old
files remain in the bucket, inaccessible to anyone (the RLS policies still gate them
by folder name, and that uid can never sign in again to claim them), but not
automatically deleted either. Worth a scheduled cleanup job if this project goes to
production; not something this audit's scope (RLS/RPC correctness) required fixing.
Two harmless test-metadata storage rows (no real file content) were left over from
this audit's own setup -- couldn't be removed via the Storage API from this session
(a `Bucket not found` response despite the buckets definitely existing, not
investigated further given zero security impact); fine to clear from the Storage tab
in the dashboard whenever convenient.

**Verified:** `flutter analyze` -- clean. `flutter test` -- 178/178 (unaffected; this
task's one code change was a pure SQL migration, no Dart touched). The
`event_reservations` fix was applied live and re-verified live, as described in #3.

**Sign-off:** every table's row-level isolation, every RPC's `anon` rejection, the
payment-methods default-uniqueness guarantee, and `delete_own_account`'s self-only
cascade are all confirmed correct against the live project as it exists today. The one
real gap found (`event_reservations.total_price` self-tampering) was fixed and
re-verified in the same pass, not just logged. Nothing else in this audit surfaced a
finding requiring further action.

---

### 54. Hardening real Delete Account: current-password re-check + storage cleanup

Closes the two gaps decision #53 explicitly flagged as out of that audit's scope: no
re-authentication before the irreversible delete, and `storage.objects` rows never
getting cleaned up (no FK to `auth.users`, so the RPC's cascade can't reach them).
The user asked for both directly, in the same terms Change Password already sets: a
current-password check first, and no files left behind with no owner.

**Two design questions with no Figma frame to follow (the original design never had
self-service deletion) were put to the user before writing any code:**

1. *How should the password re-check appear?* **Chosen: an inline form** -- tapping
   "Delete Account" expands the SAME row into a form in place, the exact
   expand-in-place pattern Change Password already uses on this screen (warning
   text, a `Current Password` field, Cancel / "Delete Permanently"). Rejected: a
   password field inside the existing `AlertDialog`, since showing a wrong-password
   error inline inside a modal dialog is more awkward than a full form.
2. *If storage cleanup fails partway, what happens?* **Chosen: abort the whole
   deletion.** The order has to be re-auth -> clean up storage -> delete the account
   (storage cleanup must run BEFORE the account row is deleted -- storage RLS checks
   the object's folder against the CURRENT session's `auth.uid()`, which stops
   working once that account, and the session tied to it, no longer exists). If
   cleanup fails, `delete_own_account` is never called: account and files stay
   exactly as they were, the user sees an error and can retry. Rejected: deleting
   the account anyway and leaving orphaned files, the "best-effort" approach
   `AvatarService.deleteQuietly` already uses elsewhere -- fine for a routine photo
   replace, not for a step that's supposed to guarantee no orphans on an
   irreversible action.

**What changed:**

- **`AuthService.verifyCurrentPassword`** (new): the exact re-authentication step
  `changePassword` already does (`signInWithPassword` with the caller's own email +
  the password they typed; nothing proceeds unless it succeeds), pulled out so
  Delete Account can reuse the identical check without touching `changePassword`'s
  already-tested internals. Throws `ReauthenticationFailure` with an already-safe
  message, same error-code mapping as `changePassword` (`invalid_credentials` ->
  "Current password is incorrect.").
- **`IdDocumentService.bucket`** (new constant, `'id-documents'`): the same pattern
  `AvatarService.bucket` already has, added so `AccountDeletionService` can name
  both buckets to clean up without a hardcoded string literal.
- **`AccountDeletionService.deleteAccount`** now takes `{required String
  currentPassword}` and runs three steps, strictly in order: (1) re-verify the
  password via `AuthService.verifyCurrentPassword` (injected, defaults to the real
  one); (2) list then remove every object under `<user_id>/` in **both** `avatars`
  and `id-documents`, aborting the whole call on any failure; (3) only then call
  `delete_own_account`. `DeleteAccountFailure` gained a `field` (`'password'` vs.
  general), the same shape `ChangePasswordFailure` already has, so the screen can
  show a wrong-password error under the field specifically.
- **`PrivacySecurityScreen`**: the "Delete Account" row's `AlertDialog` confirmation
  is gone. Tapping it now expands an inline form in the Privacy card (View Privacy
  Policy / Terms of Service stay visible above it, untouched) -- the warning text,
  a `Current Password` field (the same `_PasswordField` widget Change Password
  uses), and Cancel / "Delete Permanently". A wrong password shows inline under the
  field and the form stays open; any other failure shows below the form; success
  ends the local session via `onAccountDeleted`/`signOutAndShowLanding`, unchanged
  from decision #52.
- **New `_DangerButton` widget** (file-local to this screen): the same shape as
  `SaveButton` (48 tall, radius 8, Inter Medium 14 white label) but solid
  `_deleteInk` red instead of the app's primary gradient -- confirming an
  irreversible destructive action shouldn't look like a normal "Save".

**Also resolved in passing:** decision #53's note that two leftover test storage
rows "couldn't be removed via the Storage API... a `Bucket not found` response...
not investigated further" was a **testing mistake, not a product bug** -- that curl
session was calling `POST /storage/v1/object/remove/{bucket}`, which isn't a real
Supabase Storage endpoint. The correct one, confirmed live while testing this task
(and what `supabase_flutter`'s own storage client already calls under the hood, so
the Dart code was never at risk) is `DELETE /storage/v1/object/{bucket}` with
`{"prefixes": [...]}` in the body.

**Verified:** `flutter analyze` -- clean. `flutter test` -- 181/181 (net +3 over
decision #53's 178: the 3-test "Delete Account is real, immediate deletion" group
became a 6-test "Delete Account requires current-password re-confirmation" group,
covering the inline form appearing, an empty password rejected client-side, Cancel
clearing the field, a correct password deleting + ending the session, a wrong
password showing inline with the form staying open, and a general failure -- e.g.
storage cleanup -- showing below the form with the button available again).

**Live test, the same before/after snapshot method as decisions #51/#53** (a
throwaway account created live through the real Auth API, not synthetic):
uploaded one real file to each bucket (`avatars`, `id-documents`) and inserted the
matching `id_documents` row, mirroring exactly what the app's own upload flows do,
so there was something real to lose if cleanup were ever skipped.

- **Before:** 1 row each in `auth.users`, `profiles`, `id_documents`; 1 storage
  object in each bucket for this user.
- **Wrong password:** `POST /auth/v1/token?grant_type=password` with the wrong
  password returned `400 invalid_credentials` -- confirmed server-side rejection,
  the exact call `verifyCurrentPassword` makes and the exact failure that stops
  everything after it from ever running.
- **Correct password:** the same call succeeded (`200`), proving the path forward
  opens only once the password is actually right.
- **Storage cleanup:** listed then removed both files via the real Storage API (the
  same list-then-remove sequence `AccountDeletionService` performs), then
  re-listed -- both buckets came back empty for this user **while the account still
  existed**, proving cleanup doesn't depend on the account being gone yet.
- **`delete_own_account`:** called, returned `204`.
- **After:** `auth.users`/`profiles`/`id_documents` all **0** for this user;
  `storage.objects` across the **entire project** had exactly **1** row left -- the
  one real user's own legitimate ID document, confirming nothing else was touched
  and nothing was left orphaned.

**Sign-off:** wrong current password blocks deletion, verified against the real
Auth API, not just the widget layer. Correct password deletes the account with zero
rows remaining in any table and zero orphaned files in either storage bucket,
verified with a before/after snapshot against the live project. Decision #53's two
scope exclusions are now both closed.

---

### 55. Forgot Password: building the missing "set new password" half, and two real deep-link bugs found live

Closes the gap flagged live by the user (recorded in MASTER.md's Known Gaps since
Task 1's audit): the reset email genuinely sent, but tapping its link had nowhere
useful to go -- no screen ever finished the flow. This entry is both the feature
build and, unusually, a live-debugging log: the first two live attempts both
failed in different ways, and both fixes are recorded here rather than silently
folded in, since understanding why they failed is most of the value of this task.

**Two decisions with no Figma frame or existing pattern to follow, put to the user
first:**

1. *Which platform to actually test on?* **Chosen: Flutter Web**, run with a fixed
   port (`flutter run -d chrome --web-port=5000`) so the redirect URL stays valid
   across restarts. Rejected: mobile (Android/iOS), which would need a custom URL
   scheme in `AndroidManifest.xml`/`Info.plist` -- real platform config with no
   device/emulator in active use to test it against right now. Mobile deep-linking
   remains unbuilt; `SupabaseConfig.passwordRecoveryRedirectUrl` is written to make
   that the one place to change later.
2. *What happens right after the password is set?* **Chosen: sign out of the
   recovery session and return to Sign In** with a "Password Updated" confirmation
   screen -- matches the user's own acceptance script (set the password, THEN
   separately confirm sign-in works with the new one and fails with the old one) by
   forcing an explicit, ordinary re-authentication rather than silently continuing
   on the recovery session.

**What was built:**

- **`AuthService.completePasswordRecovery`** (new): calls `updateUser(password:)`
  inside the active recovery session -- no "current password" field, since the
  whole point of this flow is the user doesn't remember it; the recovery token
  itself already proved this is really them. `resetPassword` now passes
  `redirectTo: SupabaseConfig.passwordRecoveryRedirectUrl`.
- **`SetNewPasswordScreen`** (new, `lib/screens/auth/`): same card-on-gradient
  shape as `ForgotPasswordScreen`, new password + confirm with decision #10's
  rules ([Validators.password], same as signup), a form-to-success-view swap.
  Reachable ONLY via the deep-link listener below -- no button anywhere links here
  on purpose.
- **`auth_deep_link_listener.dart`** (new): listens for
  `AuthChangeEvent.passwordRecovery` and routes to `SetNewPasswordScreen`.
- Supabase dashboard: `http://localhost:5000/**` added to Auth -> URL
  Configuration -> Redirect URLs (otherwise Supabase silently falls back to the
  project's default Site URL, `http://localhost:3000`, and the link would 404).

**Bug #1, found on the first live attempt: the event fired, but into an empty
room.** Clicking a real reset link landed on the normal signed-in Home screen, not
Set New Password -- confirmed by reading `supabase_flutter`'s own source
(`supabase.dart`/`supabase_auth.dart`, v2.17.2): on Flutter Web,
`Supabase.initialize()` processes the recovery deep link and fires
`AuthChangeEvent.passwordRecovery` entirely INSIDE its own awaited chain, before
returning to `main()` -- which means before `runApp()` builds a single widget. The
original code did `await Supabase.initialize(...)` and only started listening
after, so the event had already fired into a stream nobody was subscribed to yet,
and was lost for good (broadcast streams don't replay past events). **Fix:**
subscribe in the gap between *calling* `Supabase.initialize()` and *awaiting* it --
Dart runs an async function's body synchronously up to its own first `await`, and
`Supabase.instance.client` is constructed synchronously before that point, so this
is the earliest a listener can exist.

**Bug #2, found on the retest with fix #1 in place: caught the event, still landed
on the wrong screen.** This time on a fresh throwaway account with no
subscription, the link landed on Choose Membership -- not Home, but still not Set
New Password, which gave away what was still wrong. Subscribing earlier was only
half the fix: the listener tried `navigatorKey.currentState?.pushAndRemoveUntil(...)`,
but on web the event fires (per Bug #1's finding) before `runApp()` ever runs --
so `navigatorKey.currentState` was still `null`, and the `?.` silently swallowed
the whole navigation call. The app just fell through to `AppEntryPoint`'s normal
session-based routing, which is exactly what a signed-in session with no
subscription resolves to. **Fix:** the listener now sets a `pendingPasswordRecovery`
flag when the Navigator isn't ready yet, instead of silently dropping the event;
`AppEntryPoint._resolve()` checks that flag first, before its normal branching, on
its very first resolve -- which is guaranteed to run after the recovery exchange
has already completed, by the same ordering Bug #1 established.

**Verified:** `flutter analyze` -- clean after each fix. `flutter test` -- 188/188
(7 new: `AuthService.resetPassword` passes the redirect URL; `completePasswordRecovery`
sets the password with no current-password check, rejects with no active session,
maps `same_password`/`weak_password` to the password field and rate-limit/network
failures to a general one -- ForgotPasswordScreen has no widget test either, so
`SetNewPasswordScreen` follows that same established precedent rather than adding
one new to this screen family).

**Live test.** A throwaway account was created via the real Auth API using Gmail
`+` addressing (`husamalhaj45+resettest<timestamp>@gmail.com` -- delivers to a real,
already-authenticated inbox without touching whatever real test account the bare
address's existing reset emails belonged to). Both live bugs above were reproduced
and fixed through real click-throughs against the actual dev project: real signup,
real "Forgot Password" request, the real email opened, the real link clicked, each
failure observed directly (Home, then Choose Membership) before its fix. After
fix #2, the user ran the complete script themselves end to end -- request reset,
open the email, click the link, land on Set New Password (not a dead end), set a
new password, confirm sign-in fails with the old password and succeeds with the
new one -- and confirmed it worked.

**Sign-off:** Forgot Password is now a complete flow, not a dead end. Both bugs
that blocked it were found and fixed through real, live reproduction rather than
guessed at from documentation.

---

### 56. "Remember me" made real

Closes the gap Sign In's own code comment already flagged as a placeholder
(decision #15): the checkbox existed, looked interactive, and did nothing --
Supabase persisted a session regardless of it. The task's own instructions
settled the two things that would otherwise need deciding: check at
`AppEntryPoint`'s existing session check, not "on close" (a mobile OS can kill a
process with no callback to act on) or at sign-out time; store the checkbox's
value in `shared_preferences`, device-local, not account data.

**What was built:**

- **`RememberMePrefs`** (new, `lib/services/`): the same thin `shared_preferences`
  wrapper shape `OnboardingPrefs` already uses. `isRemembered()` defaults to `true`
  when nothing's been stored yet -- matches decision #15's original, unconditional
  behavior, and covers every sign-in path with no checkbox at all (Create Account
  signs up remembered by default, unchanged).
- **`SignInScreen`**: `initState` now loads the last stored value into the
  checkbox itself, so it reflects the last choice rather than always resetting to
  checked. A successful sign-in saves whatever the checkbox was set to -- an
  unsuccessful attempt saves nothing, since there's no session yet to have an
  opinion about.
- **`AppEntryPoint._resolve()`**: right after finding a session and BEFORE the
  existing Home/Choose Membership branch gets a say, checks
  `RememberMePrefs.isRemembered()`. If `false`, signs out on the spot (the session
  was technically still valid; this is the one place that actually ends it) and
  falls through to the normal signed-out branch below. If `true` (the default),
  nothing about decision #15's original routing changes at all.

**Verified:** `flutter analyze` -- clean. `flutter test` -- 192/192 (4 new, for
`RememberMePrefs`: fresh-install default, a value persisting across a simulated
restart, flipping it back, and that storage is device-local with no account
scoping -- the same `SharedPreferences.resetStatic()` restart-simulation pattern
`notification_prefs_test.dart` already established. `SignInScreen`/`AppEntryPoint`
get no widget test, following the same precedent `ForgotPasswordScreen` already
set -- neither takes injectable dependencies, so neither can be driven without a
live Supabase client).

**Live test, run by the user** against the real dev project, the Flutter Web build
from decision #55's setup (a page reload standing in for force-close-and-reopen,
same equivalence decision #15's own live test already used): signed in with
"Remember me" unchecked, reloaded -- landed on Auth Landing despite a real, valid
session, exactly as required. Signed in again with it checked, reloaded -- landed
straight back on the signed-in destination, decision #15's original behavior,
unchanged. Both confirmed working.

**Sign-off:** "Remember me" now does what it has always looked like it does.

---

### 57. Change Login Email

Closes the last remaining Known Gap from the functional audit that started this
sprint: `profiles.email` was locked against client edits (decision #9) specifically
because changing the real login email "needs its own re-verification flow" --
this builds that flow.

**Found before writing any code, not mentioned in the task itself:**
`profiles.email` had no way to follow `auth.users.email` once it actually changed.
`handle_new_user()` only fires on `INSERT` (initial_schema.sql); nothing updates
`profiles.email` after that, ever. Without a fix, the app would show the OLD email
forever after a real, confirmed change. Decision #9's own lock-trigger comment had
already anticipated exactly this and blessed the fix in advance: *"A server-side
process with no user session -- e.g. a future trigger that syncs the email after a
verified change -- is not affected."* Built that trigger (below) and proved the
prediction correct live, before writing any UI: directly updated `auth.users.email`
as `postgres` (no JWT context, `auth.uid()` returns `NULL` -- matching exactly how
Supabase's own `/verify` endpoint runs), and confirmed the lock trigger did NOT
block the sync.

**Two decisions with no Figma frame or existing pattern to follow, put to the user
first:**

1. *Where does "Change Email" live?* **Chosen: Privacy & Security, next to Change
   Password** -- a new "Email" card between Password and Privacy, the identical
   expand-in-place pattern (prompt -> form -> back to prompt) those two sections
   already use. Rejected: making Edit Profile's read-only email field editable,
   which would mix a sensitive security action into a screen that's otherwise just
   name/phone/photo.
2. *Does it require the current password first?* **Chosen: yes** -- matches this
   app's own established pattern for every other sensitive account action (Change
   Password, and Delete Account after decision #54's hardening), even though
   neither the task's wording nor Supabase's own requirement (`Secure email
   change` is OFF for this project -- confirmed in the dashboard -- so Supabase
   itself only requires the NEW email to confirm) asked for it.

**What was built:**

- **Migration `20260927100000_sync_profile_email_on_change.sql`**:
  `sync_profile_email()`, `SECURITY DEFINER`, fires `AFTER UPDATE ON auth.users`
  with a `WHEN (new.email IS DISTINCT FROM old.email)` guard -- critical, since
  `auth.users` rows update constantly (every sign-in touches `last_sign_in_at`) and
  this must never fire on any of that. Keeps `profiles.email` following the real,
  CONFIRMED value only -- there's no "pending" value to reflect here, since
  Supabase's own `/verify` endpoint updates `auth.users.email` server-side before
  ever redirecting the browser back to the app (confirmed by reading the actual
  "Change email address" template: it uses `{{ .ConfirmationURL }}`, the same
  `/auth/v1/verify?...` pattern as "Reset password").
- **`AuthService.changeEmail`** (new): re-verifies the current password (reuses
  `verifyCurrentPassword`, the same method decision #54 built for Delete Account),
  then calls `updateUser(email:)` with `emailRedirectTo:
  SupabaseConfig.authRedirectUrl` -- the SAME redirect value decision #55's
  password recovery already uses, since both are "land back on the app with
  nothing further to do" (renamed from `passwordRecoveryRedirectUrl` to
  `authRedirectUrl` to reflect that; decision #55's own text is left as originally
  written, since it was accurate for what existed then). Also added
  `AuthService.currentUserEmail` / `.pendingEmailChange` getters (`_auth
  .currentUser?.email` / `.newEmail`) -- not strictly part of the request flow, but
  needed so `PrivacySecurityScreen`'s Email card can display the right thing
  through the SAME injectable `authService` the screen already takes, rather than
  reaching for the live Supabase singleton directly (see the bug below).
- **`PrivacySecurityScreen`**: new "Email" card -- current email, a pending notice
  ("Confirmation sent to X -- click the link there to finish. Your current email
  still works until then.") whenever `pendingEmailChange` is non-null, and "Change
  Email" opening a form (New Email Address + Current Password, `Validators.email`)
  in the same place. Nothing else on this screen changes; there's no follow-up
  action once the request succeeds -- the actual change happens server-side,
  whether or not this screen (or even this device) is still open when the link is
  clicked.

**Bug found and fixed before this ever reached a live test:** the first version of
the Email card read `supabase.auth.currentUser?.email` directly instead of going
through `widget.authService`. That's the live Supabase singleton, never
initialised in a widget test -- and since this card renders unconditionally as
part of the screen's normal layout, it broke ALL 21 previously-passing tests in
`privacy_security_screen_test.dart`, not just new ones. Caught by running the
existing suite right after adding the card, before writing a single new test.
Fixed by adding the `currentUserEmail`/`pendingEmailChange` getters to
`AuthService` above instead, so the same fake already injected for Change
Password/Delete Account covers the Email card too.

**Verified:** `flutter analyze` -- clean. `flutter test` -- 208/208 (7 new for
`AuthService.changeEmail` mirroring `change_password_test.dart`'s fake-`GoTrueClient`
pattern; 9 new widget tests for the Email card, extending the same suite the bug
above was caught in).

**Live test, the same before/after snapshot method as every hardening task this
sprint.** A throwaway account was created via the real Auth API using Gmail `+`
addressing for BOTH the old and new address (`...+emailchangetest<ts>@gmail.com`
and `...+emailchangetest<ts>new@gmail.com`), so both confirmation emails landed in
a real, already-authenticated inbox this session could read directly -- this whole
task was verified through the real Auth API and a real inbox, without needing the
Flutter app running at all, since the UI wiring itself is already covered by the
widget tests above.

- **Before:** `auth.users.email` = old address; `profiles.email` = old address
  (matches); no pending change.
- **Requested the change** (`PUT /auth/v1/user`, mirroring what `updateUser`
  sends): `200`, response shows `new_email` = the new address.
- **During the pending window:** signing in with the OLD email succeeded (`200`);
  signing in with the NEW email failed (`400 invalid_credentials` -- not
  confirmed yet). Exactly the required behavior.
- **Opened the real confirmation email, clicked the real link.**
- **After:** `auth.users.email` = new address; `profiles.email` = new address too
  -- the sync trigger worked correctly on the real end-to-end path, not just the
  isolated test that proved the mechanism before any UI was built; the pending
  field was cleared.
- **Sign-in, retested:** OLD email now fails (`400`); NEW email now succeeds
  (`200`), signed in as the new address.

**Sign-off:** old email keeps working for the entire pending window; the new email
only works after its link is clicked; the old one stops working at exactly that
point; `profiles.email` stays correct throughout, on the real end-to-end path, not
just in isolation. This closes the last Known Gap from Sprint 6's functional
audit.

---

### 58. Sprint 8 Task 1 — Shared SettingsProvider (foundation, not wired to any screen yet)

The first task of a sprint whose remaining tasks (Dark Mode, Animations,
Sound/Haptics, Auto-Lock, Biometric login, real 2FA, English/Arabic i18n) all need
one thing in common: somewhere real to store the setting they turn on. This task
is that somewhere, nothing more.

**Audited before writing any code, per the acceptance criterion's "no screen still
uses its own separate `shared_preferences` call for these":** none did. App
Settings' Dark Mode/Animations/Sound Effects/Haptic Feedback and Privacy &
Security's Auto-Lock/Biometric toggles are all still exactly the inert, hardcoded
placeholders decisions #5/#45/#47 left them as (`value: <hardcoded>, onToggle:
null`) -- zero prior storage to migrate away from. Confirmed with a project-wide
grep for `SharedPreferences`/`shared_preferences`, not just by reading the two
screens.

**Two decisions with no prior art in this project to follow, put to the user
first:**

1. *What should `themeMode` default to?* **Chosen: `ThemeMode.light`, not
   `ThemeMode.system`.** `AppTheme.dark` is currently just Flutter's bare
   `ThemeData.dark()` -- no brand colors, no Inter font, none of this app's
   custom button/card/input styling (confirmed by reading `app_theme.dart`
   directly). Defaulting to `system` would mean a fresh install on a device
   already in dark mode shows that unstyled stub the moment a later task wires
   `themeMode` into `MaterialApp` -- looking broken, not just unfinished.
   Matches today's actual behavior exactly: `MaterialApp` currently has no
   `darkTheme`/`themeMode` argument at all, so it's always light regardless of
   the device's setting.
2. *Does this task wire any existing toggle to the new provider?* **Chosen: no
   -- foundation only.** Every toggle stays exactly as inert as it was before
   this task; each gets wired to `SettingsProvider`, and made to actually do
   something, in its own dedicated later Sprint 8 task. Avoids duplicating work
   each of those tasks would otherwise redo.

**What was built:**

- **`provider: ^6.1.2`** added to `pubspec.yaml` -- this project's first state-
  management package; everything before this was local `StatefulWidget` state
  plus direct service calls.
- **`SettingsProvider`** (new, `lib/services/`): a `ChangeNotifier` wrapping
  `shared_preferences`, with a typed getter + async setter pair for all seven
  values the task named (`themeMode`, `animationsEnabled`, `soundEnabled`,
  `hapticsEnabled`, `autoLockEnabled`, `autoLockTimeoutSeconds`,
  `biometricEnabled`). Every setter updates the in-memory field, calls
  `notifyListeners()`, THEN persists -- listeners see the change immediately,
  not after a disk write completes. Storage keys namespaced `settings.*`.
  Deliberately device-local (matches `OnboardingPrefs`/`RememberMePrefs`'s
  scoping, not `NotificationPrefs`'s per-user one) -- these are
  how-this-device-behaves preferences, not account data.
- **Async `SettingsProvider.load()` factory**, awaited in `main()` BEFORE
  `runApp()` -- the same "resolve everything first" ordering decision #15
  already established for session routing (and decision #55 had to re-learn the
  hard way for the deep-link listener). Building this synchronously with
  in-memory defaults and correcting them once the real stored values loaded
  would mean an actual dark-mode user sees a visible flash of light theme (or
  vice versa) on every cold start -- not just a technicality, a real visible
  bug decision #15's pattern already exists specifically to avoid.
- **`main.dart`**: wraps `MaterialApp` in `ChangeNotifierProvider<SettingsProvider>
  .value(value: settings, ...)`, above everything else in the tree -- any
  screen reaches it via `context.watch`/`context.read` without prop-drilling,
  per the task's own requirement. `RosewaterCafeApp` now takes the
  already-loaded `settings` as a constructor parameter rather than constructing
  it itself.

**Verified:** `flutter analyze` -- clean. `flutter test` -- 221/221 (13 new:
fresh-install defaults for all seven values including the `ThemeMode.light`
default's reasoning; each of the seven persisting across a simulated restart
individually; a flipped-back value persisting; changing one setting leaving the
other six untouched; every setter calling `notifyListeners()` exactly once;
storage keys namespaced under `settings.*` with no collision against any other
local preference).

**Sign-off:** every value persists across a restart; no screen has its own
separate storage for any of these seven settings, confirmed by direct audit, not
assumption. No visible or behavioral change to the app yet -- exactly as scoped.

---

### 59. Sprint 8 Task 2 — Real Dark Mode, rebuilt after live feedback caught what a code review alone didn't

**First pass (a cloud session, reviewed but not merged as-is):** built the
underlying architecture -- `AppSemanticColors extends ThemeExtension`
(`surface`/`inputFill`/`border`/`textPrimary`/`textMuted`/`success`/`warning`/
`danger`/`pageBackgroundGradient`, each with a `.light` and `.dark` instance),
`AppTheme.dark` registering it, `MaterialApp`'s `themeMode` bound to
`SettingsProvider.themeMode` via a `Consumer`. This part was sound and kept
as-is: reviewed the WCAG contrast math by hand (relative-luminance formula, not
trusting a comment) and it passed AA on every token pair.

**What was wrong, found by the user's own live click-through, not by that code
review:** two separate problems, reported together --

1. *Incomplete coverage.* The first pass converted some screens to
   `context.colors` but left others on hardcoded light-mode `AppColors.*`
   constants -- Events (Reserve an Event, Reservation Confirmed) and QR / Door
   Access stayed fully light regardless of the toggle. A project-wide
   `grep -L app_semantic_colors` (run independently, moments around the same
   time as the user's report) confirmed roughly 15 files were never touched.
2. *The palette itself was bad.* `AppColors.dark*`'s background and surface
   colors sat in the same dark-purple hue family as the pink/purple brand accent,
   so the UI read as flat and "muddy" rather than the accent popping against a
   neutral backdrop -- a real design defect a contrast-ratio check alone doesn't
   catch, only looking at it does.

The user pointed at a specific reference (a Figma community banking-app UI kit
with its own light/dark system) for aesthetic cues -- not to copy its blue
brand color, but for the *structural* idea of a neutral, sufficiently-dark
backdrop that a saturated accent color sits on top of, rather than blends into.
Asked directly whether to keep Rosewater's pink/purple accent given that
reference: **chose to stay open to a different dark accent** rather than
preserving pink/purple unconditionally -- in the end the accent
(`AppColors.primaryGradient`) was left untouched, because the actual problem
traced to the *background* being too close to the accent's hue, not to the
accent itself being wrong; changing the backdrop already fixed the "blends in"
complaint without also re-skinning the app's brand color.

**Rebuilt:**

- **`lib/theme/app_colors.dart`'s dark palette**, redone deeper and more
  neutral: `darkBackground`/`darkSurface`/`darkSurfaceElevated`/`darkInputFill`
  near-black with only a faint purple cast (not the previous same-family purple),
  `darkBorder` a translucent white hairline, `darkTextPrimary`/`darkTextMuted`
  kept high-contrast off-white/grey. `pageBackgroundGradientDark` re-picked to
  match. `success`/`warning`/`danger` dark variants unchanged -- they already
  cleared AA. `primaryGradient` and every membership-tier gradient
  deliberately untouched, per the task's own "still reads as Rosewater Café"
  requirement.
- **Full file-coverage pass**, not just the screens the user named: every
  remaining screen and shared widget converted to `context.colors`, in this
  order -- Events (`reserve_event_screen`, `reservation_confirmed_screen`), QR
  / Door Access (`qr_access_screen`), the rest of Membership
  (`id_upload_screen`, `payment_screen`, `payment_success_screen`, plus
  `payment_fields.dart` and `outlined_secondary_button.dart`, the latter's
  `borderColor`/`textColor` changed from hardcoded-default `Color` to nullable
  `Color?` resolved via `context.colors` so callers that don't override it get
  the theme instead of a fixed light value), all seven remaining Profile
  screens (`profile_screen`, `edit_profile_screen`, `payment_methods_screen`,
  `add_payment_method_screen`, `notification_settings_screen`,
  `help_support_screen`, `privacy_security_screen` -- the last one carrying
  Delete Account / Change Password / Change Email's forms from decisions
  #54/#57, its `_deleteInk` mapped onto `colors.danger`, the semantic token
  already re-picked per brightness to clear AA, not a generic color), plus
  `setting_toggle_row.dart`'s switch off-state and Onboarding
  (`onboarding_screen.dart`). A handful of decorative colors were deliberately
  left as fixed literals rather than tokenized, each with a comment explaining
  why: the QR code's own white background (scanner contrast requirement), the
  purple/amber info-box tints on Reserve an Event / QR Access (brand-tinted,
  not neutral, so they get their own light/dark pair via a local brightness
  check rather than a semantic token), every accent gradient and
  `AppColors.bottomNavActive`-style brand color (per the architecture's own
  stated intent, see `app_semantic_colors.dart`'s doc comment), and
  `DotsIndicator`'s inactive-dot grey (no existing token fits a small solid
  control sitting directly on the page wash -- `border` is a translucent
  hairline, `surfaceElevated` is a card fill and, in light mode, pure white --
  so it picks its own brightness-appropriate pair instead of reusing the wrong
  token).
- **`SettingToggleRow`'s switch track**, on closer look during this pass, also
  had a leftover fixed light-grey "off" state (`0xFFD1D5DC`). First attempt
  moved it to `colors.surfaceElevated` -- wrong, and caught by a separate
  cloud-session commit (`0f9a518`, "Fix: Dark Mode switch... invisible in
  light mode"): `surfaceElevated` IS `AppColors.cardWhite` in light mode, the
  exact same solid white as the card the switch already sits on, so an "off"
  switch rendered as an invisible white-on-white pill with nothing to tap.
  Corrected to its own dedicated brightness-aware grey pair instead (same
  fix shape `DotsIndicator.inactiveColor` already needed for the same
  underlying reason -- a small solid control sitting ON a card can't reuse
  that card's own fill token).

**v2 verified:** `flutter analyze` -- clean, whole project. `flutter test` --
222/222 (no widget test asserts on a specific hex color, so none needed
updating for the palette change). Live verification via the running Flutter
Web dev server was attempted but the browser tab repeatedly froze mid-render
in this sandboxed environment (confirmed the dev server itself was fine --
`curl` got a fast `200` the whole time) -- the actual look-and-feel check was
handed to the user to do themselves, on their own machine, per the
project's established DB/SQL-vs-app-level verification split.

**v3 (this same task, third pass):** the user's own live check of v2 came
back "too bad," "not matching," and asked for the dark palette to lean
blue -- explicitly **not** to preserve anything from v2 if it didn't work
("don't stick with anything"). Asked directly whether "blue" meant just the
background/neutral tones or the accent color too, given the architecture's
stated intent (`app_semantic_colors.dart`'s v2 doc comment) was to keep the
brand gradient identical in both themes: **the user chose the bigger
change** -- blue-black neutrals AND a dedicated blue accent for dark mode,
not just a cooler backdrop under the same pink/purple buttons.

- **Palette redone a second time**, now genuinely navy rather than
  near-neutral: `darkBackground`/`darkSurface`/`darkSurfaceElevated`/
  `darkInputFill` moved from a whisper-of-violet near-black to real
  slate-blue (`0xFF0A0E1A` → `0xFF1B2540`), `darkBorder` changed from plain
  white-at-20% to accent-blue-at-20% (so the hairline itself reads as part
  of the same color family instead of a neutral afterthought),
  `darkTextMuted` moved off a warm lavender-grey onto a cool slate-blue
  (`0xFF94A3C0`). `pageBackgroundGradientDark` re-picked as a visible navy
  movement instead of a barely-perceptible one.
- **New dark-mode-only accent**, `AppColors.primaryGradientDark` (blue ->
  indigo, `0xFF3B82F6` → `0xFF6366F1`, same left-to-right structure as the
  light-mode pink/purple gradient) and `AppColors.accentDark` (`0xFF5B9BFF`,
  a single-color stand-in for `bottomNavActive`). Both explicitly flagged in
  their own code comments as a first attempt, not a locked-in final answer --
  matching the user's "don't stick with anything" brief.
- **`AppSemanticColors` gained `accentGradient`/`accent`**, the first tokens
  on that extension that DO differ by theme (everything else added in v1/v2
  is deliberately identical in both) -- light instances point at the
  existing `AppColors.primaryGradient`/`bottomNavActive` unchanged, dark
  instances point at the two new dark-only constants above. The membership
  tier gradients (Basic/Premium/VIP) were deliberately left OUT of this --
  those identify a plan, changing "VIP purple" per theme would make the tier
  itself harder to recognize, a different problem than the action-color
  swap this task is actually about.
- **Every direct `AppColors.primaryGradient`/`AppColors.bottomNavActive`
  reference project-wide (16 files) switched to
  `context.colors.accentGradient`/`.accent`**: the four auth screens' lock
  badge, `GradientButton`'s and `OnboardingIconBadge`'s own default gradient
  (both changed from a fixed light-mode `Color`/`Gradient` default to
  nullable, resolved via `context.colors` -- the same "null defaults to the
  theme" pattern `OutlinedSecondaryButton` already used, so callers that
  don't override it now get the theme instead of a stale light value), Home's
  "Access Café" quick action and its "Reserve Event" icon color,
  `AppBottomNav`'s active-tab color, every gradient-banded card header in
  Profile (App Settings' Appearance card, Notification Settings, Help &
  Support's FAQ card, Privacy & Security's Security Options), Payment
  Methods' "Add New Payment Method" button, `form_buttons.dart`'s
  `SaveButton`, and `DotsIndicator`'s default (currently dead code -- the one
  live caller, Onboarding, always passes its own per-slide gradient -- kept
  theme-aware anyway rather than left on a stale default). Along the way,
  found and fixed several `AppColors.danger`-as-a-link-color reuses in Create
  Account / Sign In ("Terms of Service," "Sign In," "Forgot Password?" etc.)
  that were never actually error states -- moved to `colors.accent`, the
  semantically correct token for a highlighted link. App Settings' language-
  selected row wash and its "Clear All App Data" destructive button were
  also caught still on fixed pink/red literals and moved to
  `colors.accent.withValues(alpha: ...)`/`colors.danger` respectively.

**v3 verified:** `flutter analyze` -- clean, whole project. `flutter test` --
222/222. Live look-and-feel check is, again, the user's own to do -- per
their own explicit instruction this round ("don't open google and test
things just do the changes in the code and I will verify them"), no browser
automation was attempted for v3 at all.

**Sign-off:** architecture from v1 kept (sound); v2 fixed coverage and
de-muddied the palette; v3 gives dark mode its own blue identity (palette
and accent both) rather than a cooler wrapper around the light-mode brand
color, on the user's explicit direction to not preserve anything that
wasn't working. **Still not signed off end-to-end** -- pending the user's
own visual click-through, same as v2's open item, now against the v3 blue
palette instead.

---

### 60. Sprint 8 Task 3 — Real Animations toggle

**The core problem:** `MaterialPageRoute` doesn't expose its transition
duration as a constructor parameter -- it's a fixed `Duration(milliseconds:
300)` override baked into the class. There's no `ThemeData`-level "make all
navigation instant" switch either. Confirmed with the user before building
anything (per the standing rule) that the only way to actually hit the
acceptance criterion's "any screen-to-screen navigation" was a custom route
class, read at every one of the app's 28 `Navigator.push(MaterialPageRoute
(...))` call sites -- not a smaller sample first. Chose the full sweep.

**What was built:**

- **`AppPageRoute<T> extends MaterialPageRoute<T>`** (new,
  `lib/widgets/app_page_route.dart`): takes `animationsEnabled` at
  construction, overrides `transitionDuration`/`reverseTransitionDuration`
  to return the normal 300ms when true, **1ms (not `Duration.zero`) when
  false** -- the acceptance criterion's own explicit requirement, since a
  zero-length transition can leave a route's animation stuck mid-flight
  instead of settling on `.completed`/`.dismissed`.
- **`appRoute(context, builder)`**, a drop-in replacement for
  `MaterialPageRoute(builder: ...)` that reads
  `SettingsProvider.animationsEnabled` at push time and builds an
  `AppPageRoute` with it. **Every one of the 28 call sites app-wide switched
  to it** (~20 files: every auth screen, Home, Main Shell, the whole
  membership signup flow, every Profile sub-screen, Onboarding, and
  `auth_deep_link_listener.dart`'s non-widget-triggered navigation, which
  reaches a real `BuildContext` via `navigator.context` -- a
  `NavigatorState` is itself a `State`, so this works even though nothing
  built that listener from a widget).
- **`context.animDuration(normal)`** (new, `lib/utils/app_animations.dart`):
  the equivalent for every explicit `Animated*` widget duration that isn't
  a route transition -- `SettingToggleRow`'s switch thumb/track,
  `DotsIndicator`'s active-dot resize, Help & Support's FAQ chevron
  rotation, and Onboarding's slide-to-slide `PageController.nextPage`/
  `.previousPage` (handled separately, as a getter, since a
  `PageController` call takes a `Duration` argument directly rather than
  rendering a widget with one). Same near-zero-not-zero reasoning.
- **Both fall back to animations-ON when no `SettingsProvider` is in the
  widget tree** -- the same fallback `context.colors` already established
  for the same reason: most of this app's ~20 existing widget test files
  pump a screen directly (`MaterialApp(home: SomeScreen())`) without
  registering `SettingsProvider`, and none of them should have to just
  because the screen they're testing happens to navigate somewhere or use
  a switch. Confirmed this was the actual failure mode, not guessed at:
  before this fallback existed, running the full suite took it from
  222/222 to 47 failing, all `ProviderNotFoundException`s surfacing as
  cascading `RenderFlex` overflows and missing-text failures several layers
  removed from the real cause.
- **The Animations row in App Settings is real now** -- `value:
  settings.animationsEnabled`, `onToggle:` flips it, same pattern as Dark
  Mode (decision #59). `test/app_settings_screen_test.dart`'s old "all
  three [Animations/Sound/Haptic] are on and inert" test split: Animations
  moved to its own group proving the toggle actually reads/writes
  `SettingsProvider` and starts at whatever's stored; Sound/Haptic stay in
  the inert-placeholder group, unchanged (out of this task's scope, same
  as decision #47 left them).
- **`test/notification_prefs_test.dart`'s import-graph test** (asserts
  Notification Settings and its whole transitive import tree can never
  reach the network) needed its allow-list updated to include
  `package:provider/provider.dart`, now pulled in transitively through
  `SettingToggleRow` → `app_animations.dart`. Added deliberately, not
  loosened carelessly: `provider` is a pure `InheritedWidget` wrapper with
  no I/O of its own, so the test's actual guarantee (no `supabase`, no
  `http`, no `dart:io`) still holds -- confirmed the loop asserting that
  is untouched, only the allow-list's exact-match set changed.
- **New test coverage**, not just relying on existing screen tests passing
  incidentally: `test/app_page_route_test.dart` -- `AppPageRoute`'s
  duration with animations on/off (and explicitly asserts it's never
  `Duration.zero`), `appRoute()` reading the live `SettingsProvider` value
  at push time in both states plus its no-provider fallback, and
  `context.animDuration`'s same three cases. This is the test that directly
  proves the acceptance criterion ("compare a screen-to-screen navigation
  with it on vs off"), rather than leaving it as something only a manual
  click-through could confirm.

**Verified:** `flutter analyze` -- clean, whole project. `flutter test` --
232/232 (10 new: 2 for the real Animations toggle in App Settings, 8 in the
new `app_page_route_test.dart`). No browser automation was used for this
task -- the user asked, this round, to skip that and just review the code
changes themselves.

**Sign-off:** every screen-to-screen navigation and every explicit
`Animated*` duration in the app now collapses to 1ms the instant Animations
is switched off, and returns to normal the instant it's switched back on --
covered by real tests, not just code review. Live click-through
confirmation is, like decision #59's dark-mode look-and-feel, the user's
own to do.

---

### 61. Sprint 8 Task 4 — Real Sound & Haptic Feedback

**Three real decisions, put to the user before building anything** (per the
standing rule):

1. *How to play the sound?* **Chosen: `SystemSound.play()`** -- Flutter's
   built-in platform sound (generic click/alert), zero new dependency, over
   bundling distinct success/error audio assets (would need an audio-player
   package and real sound files this project doesn't have). Matches "a
   short system sound" from the task text literally.
2. *Does a button press also play a sound, or is sound reserved for
   success/error?* **Chosen: haptic only on button presses.** Sound is
   reserved for the success/error moments; most apps don't click on every
   tap, and the task's own examples list sound and haptics somewhat
   separately ("HapticFeedback... for button presses... a short system
   sound... for success/error").
3. *Real-device verification* -- the acceptance criterion explicitly
   requires a real device (haptics don't exist in a browser), and this
   session only has Chrome/web automation. **Chosen: same split as every
   other look-and-feel check this sprint** (decisions #59/#60) -- built and
   tested everything code-verifiable, the user does the real haptic/sound
   check on their own device.

**What was built:**

- **`context.triggerButtonPress()`/`.triggerSuccess()`/`.triggerError()`**
  (new, `lib/utils/app_feedback.dart`): a small, fixed set of real trigger
  points, not instrumenting every tap, per the task's own framing.
  Sound and haptics are gated **independently** through
  `SettingsProvider.soundEnabled`/`.hapticsEnabled` -- two separate `if`s,
  not one combined gate -- so sound off + haptics on still vibrates, and
  vice versa, exactly as the acceptance criterion requires. `triggerSuccess`
  uses `SystemSoundType.click`, `triggerError` uses `.alert` -- Flutter's
  only two system sound types, picked so a success and a failure don't
  sound identical even without custom audio assets. Falls back to both
  enabled when no `SettingsProvider` is in the tree, same fallback
  `context.colors`/`context.animDuration` already use.
- **`GradientButton`** wired once, centrally, at its own `InkWell.onTap`
  (`context.triggerButtonPress()` before calling the real `onPressed`) --
  every primary CTA in the app gets it for free, rather than adding a call
  at each of `GradientButton`'s dozens of call sites.
- **The three named success trigger points**: payment confirmed
  (`payment_screen.dart`, right after `confirmSubscriptionPayment`
  succeeds), door opened (`qr_access_screen.dart`, right after
  `logDoorAccess` succeeds), reservation confirmed
  (`reserve_event_screen.dart`, right before handing off to
  `onConfirmed`).
- **The two named error trigger points**: failed sign-in
  (`sign_in_screen.dart`'s `SignInFailure` catch, and its generic
  catch-all too), failed payment (`payment_screen.dart`'s
  `ConfirmPaymentFailure` catch, and its generic catch-all). Deliberately
  did NOT add error feedback to door-access or reservation failures --
  only the two the task explicitly named, matching "a small fixed set,"
  not "every catch block in the app."
- **App Settings' Sound Effects / Haptic Feedback rows are real now**
  (were inert placeholders since decision #47) -- same
  read/write-`SettingsProvider` pattern as Dark Mode (#59) and Animations
  (#60).
- **New test coverage proving the acceptance criterion directly**,
  `test/app_feedback_test.dart`: records the actual
  `HapticFeedback`/`SystemSound` platform-channel calls a mocked
  `SystemChannels.platform` handler receives (rather than trusting the
  wiring by inspection), across all four on/off combinations of the two
  toggles -- explicitly proving the independent-gating requirement, plus
  the no-`SettingsProvider` fallback. `test/app_settings_screen_test.dart`'s
  old "Sound Effects / Haptic Feedback: drawn at the design state, inert"
  test replaced with one proving each toggle reads/writes its own
  `SettingsProvider` field independently (flipping one leaves the other
  alone).

**Verified:** `flutter analyze` -- clean, whole project. `flutter test` --
241/241 (9 new: 8 in `app_feedback_test.dart`, 1 replacing the old inert-
placeholder test). Real-device haptic/sound verification is, like decisions
#59/#60's look-and-feel checks, the user's own to do -- this environment has
no physical device or emulator, and haptics are meaningless in a browser
regardless.

**Sign-off:** every named trigger point fires the right channel(s), gated
independently and provably (not just by code review) -- **code-side signed
off; real-device confirmation is still open**, the same honest gap #59/#60
already established this sprint's pattern for.

---

### 62. Sprint 8 Task 5 — Real Auto-Lock + Biometric login

**Three real decisions, put to the user before building anything** (per the
standing rule -- this task had the most open architecture questions of the
sprint):

1. *Where does the lock screen live, and does it gate the whole app or only
   signed-in screens?* **Chosen: `MaterialApp.builder` wraps the entire
   navigated app in `AppLockGate`, scoped to signed-in sessions only.**
   Auto-Lock needs to appear over whatever screen is on top when the app
   RESUMES, not just at cold start -- `AppEntryPoint`'s existing
   session-based routing (decision #15) only ever runs once, at the very
   start, so it can't be where this lives. Nothing sensitive exists before
   sign-in, so Onboarding/Auth Landing/Sign In are never gated -- locking
   them would be a confusing dead end, not a security feature.
2. *Does the very first cold start also require biometric, per the task's
   own "optionally"?* **Chosen: no, resume-only** -- matches the
   acceptance criteria exactly (background-past-timeout-then-resume, and
   the no-biometric fallback), and a cold-start lock check would be a real
   behavior change to `AppEntryPoint`'s existing flow beyond what either
   the task or the acceptance bar actually asked for.
3. *What happens when someone tries to turn Biometric Authentication on but
   the device has none enrolled?* **Chosen: block it with a real message**
   (`BiometricService.isAvailable()` checked before the toggle is allowed
   to flip on at all) -- matches the task's own "fail gracefully... rather
   than a toggle that silently does nothing" literally. Turning it back
   off never needs the check.

**What was built:**

- **`local_auth: ^2.3.0`** added. Platform config done, but **unbuildable
  and unverifiable in this environment** (no Android SDK, no Xcode, no
  physical device --confirmed via `flutter doctor`): `MainActivity.kt`
  changed from `FlutterActivity` to `FlutterFragmentActivity` (required for
  Android's `BiometricPrompt`), `AndroidManifest.xml` gained the
  `USE_BIOMETRIC` permission, `Info.plist` gained
  `NSFaceIDUsageDescription`. All three are standard, documented
  `local_auth` setup steps, not guesses -- but genuinely can't be proven to
  compile here.
- **`BiometricService`** (new, `lib/services/biometric_service.dart`): a
  thin wrapper around `local_auth`'s `LocalAuthentication`, matching this
  project's constructor-injection pattern for every other real service
  (`AuthService`, `AccountDeletionService`, ...) so a fake can stand in
  without a real device. `isAvailable()` checks both
  `isDeviceSupported()` AND `canCheckBiometrics` (device capable of
  biometrics at all, AND something actually enrolled) and never throws --
  any plugin-level error is treated the same as "not available."
  `authenticate()` uses `biometricOnly: true` deliberately: never falls
  through to the OS's own device-PIN prompt, so this app's own "Use
  Password Instead" is the one fallback path, not two stacked ones.
- **`AppLockGate`** (new, `lib/widgets/app_lock_gate.dart`): a
  `WidgetsBindingObserver` watching `AppLifecycleState.paused`/`.resumed`
  specifically (not `.inactive`, which flickers during perfectly normal use
  -- a system dialog, an incoming call banner -- without the app ever
  actually leaving the foreground). Records a timestamp on pause; on
  resume, if there's a signed-in session AND `autoLockEnabled` AND elapsed
  time exceeds `autoLockTimeoutSeconds`, shows [AppLockScreen] in a `Stack`
  on top of the app's own content rather than replacing it -- the
  Navigator underneath keeps its state (scroll position, form values)
  instead of losing it, since it's covered, not torn down. Takes injectable
  `now`/`hasSession` functions (default to the real clock / real Supabase
  session) so tests can control elapsed time and sign-in state without
  waiting on a real clock or a real session.
- **`AppLockScreen`** (new, `lib/widgets/app_lock_screen.dart`): fires a
  biometric prompt automatically (once the first frame is up, not from
  `initState` directly) when Biometric is on; "Try Again" and "Use Password
  Instead" are BOTH always visible, never revealed only after a failed
  attempt -- the acceptance criterion's own point is a real path forward,
  not a dead end for a device/user without working biometrics. The
  password path calls the already-existing
  [AuthService.verifyCurrentPassword] (the same re-authentication check
  Change Password/Delete Account already use, decision #54) -- reused, not
  reimplemented.
- **Security Options' Biometric Authentication and Auto-Lock rows are real
  now** (were disabled "(Coming Soon)" placeholders since decision #45).
  **Two-Factor Authentication stays a placeholder** -- a separate later
  task, not this one.
- **New test coverage**, each targeting a different layer since none of
  this can be proven on a real device here: `test/app_lock_gate_test.dart`
  (7 tests) -- does resuming show the lock screen or not, for every
  combination (elapsed under/over the timeout, Auto-Lock on/off, signed in
  or not, a transient `.inactive` blip that never actually paused) --
  using `tester.binding.handleAppLifecycleStateChanged` to simulate real
  lifecycle transitions and the injectable clock to control elapsed time
  without waiting on it. `test/app_lock_screen_test.dart` (7 tests) -- the
  unlock interaction itself: auto-attempt on show, failed-attempt UI state,
  the password fallback (right password unlocks, wrong password shows the
  real error and stays locked), switching back and forth between the two
  paths. `test/biometric_service_test.dart` (5 tests) -- against a fake
  `LocalAuthPlatform` (the plugin's own platform interface), not the real
  plugin: `isAvailable()`'s two independent checks, `authenticate()`
  swallowing a plugin-level error into `false` rather than throwing.
  `test/privacy_security_screen_test.dart`'s old "Security Options are
  disabled placeholders" group split: Two-Factor keeps its own (still
  accurate) inert-placeholder test; Biometric/Auto-Lock get real ones,
  including the capability-check-blocks-with-a-message case.

**Verified:** `flutter analyze` -- clean, whole project. `flutter test` --
264/264 (19 new). **Real-device verification is explicitly NOT done and
can't be from here** -- no Android SDK, no Xcode, no physical device or
emulator (`flutter doctor` confirms), and biometrics are meaningless in a
browser regardless, same root cause as decision #61's sound/haptics gap.
This is the task this sprint where that gap matters most: the acceptance
criteria's two real-device scenarios (background-past-timeout-then-resume
blocking content until biometric succeeds; the no-biometric-capability
fallback actually working, not a dead end) are UNVERIFIED, not just
"the polish is the user's call" the way #59/#60's look-and-feel checks were.

**Sign-off:** architecture and logic are real and covered by 19 tests
proving the decision points directly (not just by inspection) --
**explicitly not signed off end-to-end.** The user needs to confirm, on an
actual Android/iOS device or emulator: (1) backgrounding the app past the
timeout and resuming shows the lock screen and it actually blocks content;
(2) with biometrics disabled/unavailable, the password fallback is a real
path forward, not a dead end; (3) the Android/iOS build actually compiles
with the `MainActivity.kt`/manifest/`Info.plist` changes above.

---

### 63. Sprint 8 Task 6 — i18n infrastructure + English/Arabic (phase 1: infra + 3 screens)

**The scale problem, put to the user before writing anything:** this app
has ~30 screens; the task's own text says the string extraction, not the
plumbing, is "the bulk of the effort," and RTL correctness means auditing
LAYOUT code (not just strings) on top of that. Two real decisions:

1. *Pace it all at once, or phase it?* **Chosen: phase it** -- build the
   full i18n infrastructure (real, app-wide, not a stub), then fully do
   (strings AND RTL layout) the exact three screens the acceptance
   criteria names -- bottom nav, a form screen (Sign In), Home's
   icon-badge rows -- check in on the approach, extend to the rest of the
   app afterward. Not "infra only" -- the three named screens are
   completely real, not placeholders.
2. *Who reviews the Arabic?* No translation service exists in this
   project. **Chosen: the user does** -- every Arabic string below is
   AI-written and explicitly unreviewed by a fluent speaker. Flagged here,
   not silently presented as authoritative.

**Infrastructure built:**

- **`flutter_localizations` + ARB files** (`lib/l10n/app_en.arb`,
  `app_ar.arb`), `flutter: generate: true` in `pubspec.yaml` + `l10n.yaml`
  -- `flutter gen-l10n` runs automatically on `pub get`/`run`/`build`,
  generating `lib/l10n/app_localizations.dart` (never hand-edited).
  `intl` bumped `^0.19.0` → `^0.20.2`: `flutter_localizations` pins an
  exact `intl` version, and the old constraint made `pub get` unsolvable.
- **`SettingsProvider.locale`** (new field, `'en'` default, ISO 639-1
  codes): the user's PICKED language, not necessarily what's shown --
  French/Spanish are real, storable picks (the design shows all four as
  selectable) with no ARB file yet.
- **`MaterialApp.locale`/`supportedLocales`/`localizationsDelegates`**
  wired in `main.dart`, reading `SettingsProvider.locale`.
  `supportedLocales` only lists `[en, ar]` -- **this is what makes the
  French/Spanish fallback automatic**, not extra code: Flutter's own
  locale-resolution algorithm falls back to the first supported locale
  (English) for a `Locale` it doesn't recognize, rather than crashing or
  showing missing-key text. Arabic being in `supportedLocales` is also
  what flips `Directionality` app-wide -- derived from the resolved
  `Locale`, not set separately.
- **App Settings' Language list is real for English/Arabic**
  (`_LanguageRow` now tappable, calls `SettingsProvider.setLocale`).
  French/Spanish stay tappable and show selected too (real, storable
  picks) -- decision #63's "say so plainly in the picker" requirement is
  a caption shown under the list while one of them is picked ("French and
  Spanish aren't translated yet..."), not silence. Each language is shown
  in its OWN script (`"العربية"`, not `"Arabic"`) -- the standard
  language-picker convention, unrelated to `AppLocalizations`.

**The three screens, fully done (strings + RTL), not stubbed:**

- **`AppBottomNav`** needed ZERO layout changes -- confirmed by reading
  the render logic, not assumed: every tab is a plain vertical `Column`
  (icon, dot, label), no left/right positioning to mirror, and the
  enclosing `Row` already reverses its children's visual order under RTL
  `Directionality` (Flutter's own default `Row` behavior). Only the four
  tab labels needed translating.
- **Sign In** (the form screen): found and fixed two real RTL bugs while
  auditing, not guessed at -- `grep` for `Alignment\.`/`EdgeInsets\.only`
  found exactly one physical-alignment bug in this file
  (`Alignment.centerLeft` on the credentials-error text → 
  `AlignmentDirectional.centerStart`) and the back arrow, which doesn't
  auto-mirror (`Icons.arrow_back` isn't one of the codepoints Flutter's
  bidi icon-mirroring covers), so it now checks `Directionality.of(context)`
  explicitly and swaps to `Icons.arrow_forward`. The "Don't have an
  account? Create Account" row's trailing space was moved out of the
  translated string into a `SizedBox` gap -- a translated string
  shouldn't have to carry layout spacing baked into it.
- **Home** (icon-badge rows): same audit found one more physical-alignment
  bug (`Alignment.topLeft` on the wrapping-text `OverflowBox` in
  `_MembershipStatusCard` → `AlignmentDirectional.topStart`). Every
  icon-badge row (`_UsageCard`, `_HomeHeader`, `_ServiceHoursCard`'s
  title) needed no changes -- same `Row`-auto-reverses reasoning as the
  bottom nav, proven directly in `home_content_test.dart` by measuring an
  icon's screen position relative to its label in both directions, not
  just asserted. Real data (the member's name, member ID, plan name,
  plan's own `featureBullets`) is interpolated into translated strings,
  never itself translated.
- **`ComingSoonScreen`** (shared, reached from Home's notification bell
  and elsewhere) got the same back-arrow fix and its one string
  localized, since it's a single shared widget already on both screens'
  critical path, not per-screen duplicated effort.
- **Validators**: `SignInScreen`'s own `_validatePassword` (a local
  method with `this.context` available) is localized; the shared
  `Validators.email`/etc. (`lib/utils/validators.dart`, used by ~10+
  screens) is explicitly NOT -- it's a plain `String? Function(String?)`
  with no `BuildContext` parameter, and giving it one is a real signature
  change touching every call site app-wide, out of this phase's scope.
  Logged as a known follow-up, not silently left inconsistent.

**A real bug found along the way, unrelated to i18n:** writing
`test/sign_in_screen_test.dart` at a phone-realistic width (400px, instead
of this suite's usual 800px canvas) surfaced a `RenderFlex` overflow on
the "Remember me / Forgot Password?" and "Don't have an account? / Create
Account" rows -- **in English too**, confirmed independently before
concluding it wasn't an RTL regression. Pre-existing, not introduced by
this task; the test was widened to match this suite's established
800px-canvas convention (used everywhere else specifically to keep
narrow-width responsiveness a separate concern from what each test is
actually checking) rather than silently worked around. Left as a known
gap for a future task, not fixed here -- fixing general responsiveness is
outside Task 6's scope.

**Verified:** `flutter analyze` -- clean, whole project. `flutter test` --
277/277 (12 new: 4 in `app_bottom_nav_test.dart`, 4 in
`sign_in_screen_test.dart`, 4 added to `home_content_test.dart` --
covering both languages, `Directionality`, and, for Home, actually
measuring the icon-badge row's mirrored screen position rather than just
checking translated text appears). `app_settings_screen_test.dart`'s old
"Language is visual only" test replaced with one proving the real
tap-to-switch-locale behavior and the French/Spanish fallback caption.

**Sign-off:** infrastructure is real and app-wide, not a stub; all three
acceptance-criteria screens are fully translated AND RTL-correct, proven
by tests that measure actual mirrored positions, not just check for
translated text. **Two things explicitly still open, not silently
closed:** the Arabic translations are unreviewed by a fluent speaker (the
user's own to check), and the remaining ~27 screens are untouched --
Phase 1 only, per the pacing decision above. Extending this to the rest
of the app is the next task, not assumed to be "mostly done" because the
pattern is now proven.

### 64. Sprint 8 Task 6 — i18n Phase 2: the remaining ~27 screens, same pattern extended app-wide

Picked up right where #63 left off, with the user's go-ahead to run
straight through the rest of the app the same way (real strings, RTL
audited, tested at every stop) rather than checking in screen-by-screen.
Worked in eight groups, each with its own ARB keys, RTL audit, `flutter
analyze` and `flutter test` pass before moving on:

- **Auth** (Auth Landing, Create Account, Forgot Password, Set New
  Password, Confirm Email Pending): ~35 keys. RTL bugs: the back arrow
  (same `Icons.arrow_back`-doesn't-auto-mirror fix as #63) on Create
  Account and Forgot Password, plus `Alignment.centerLeft` on each
  screen's terms/error text → `AlignmentDirectional.centerStart`.
- **Membership** (Choose Membership, ID Upload, Payment, Payment
  Success): ~35 keys. RTL bug: ID Upload's back arrow +
  `Alignment.centerLeft` on "Back to Plans" + a stray `TextAlign.left`.
- **Events + QR** (Events Tab, Reserve Event, Reservation Confirmed, QR
  Access): ~65 keys, including the four placeholder event types
  (decision #37/#38) and both guest-count/duration validators. RTL bugs:
  the same back-arrow pattern on Reserve Event's and QR Access's own
  "Back to Dashboard" buttons. `intl`'s own `TextDirection` enum turned
  out to shadow `dart:ui`'s when both packages are imported unqualified
  (`import 'package:intl/intl.dart'` alongside `Directionality.of(...) ==
  TextDirection.rtl`) -- fixed by hiding it (`import
  'package:intl/intl.dart' hide TextDirection`), not by qualifying every
  reference.
- **Onboarding**: the 4-slide `_pages` list, previously a `static const
  List`, had to become a method taking `AppLocalizations` (same pattern
  as #63's bottom-nav tabs) since Dart consts can't hold looked-up
  strings. RTL: the Skip button's `Alignment.centerRight` →
  `AlignmentDirectional.centerEnd`, and the Next/Previous chevrons now
  swap (`chevron_right`↔`chevron_left`) under `Directionality`, the same
  "points toward reading-forward, not literally right" reasoning as every
  other directional icon this task touches.
- **Profile + Edit Profile**: ~45 keys. Fixed the shared **`ScreenHeader`**
  widget here (back arrow + a hardcoded "Back" tooltip) -- used by six
  more screens still to come, so fixing it once here instead of
  per-screen. Also fixed the shared **`SettingToggleRow`**'s custom switch
  thumb (`AnimatedPositioned(left: ...)` → `AnimatedPositionedDirectional
  (start: ...)`), used by Notifications, App Settings, and Privacy &
  Security. `_EditField`'s custom icon overlay (a `Positioned` + fixed
  `contentPadding`, not `InputDecoration.prefixIcon`, so it doesn't
  auto-mirror) converted to `PositionedDirectional` +
  `EdgeInsetsDirectional` -- flagged in-code as the same "form field
  icons" trap the original Task 6 acceptance criteria called out.
  Fixing `ScreenHeader`/`SettingToggleRow` mid-task broke five *other*
  screens' existing tests that construct a bare `MaterialApp` with no
  `AppLocalizations` delegate (their own screens aren't localized yet) --
  fixed by registering the delegate in each of those test files (the same
  fallback pattern #63 already established), and by extending
  `notification_prefs_test.dart`'s "no network" import-allowlist test
  with `flutter_localizations` and its own transitive imports, once
  `ScreenHeader` started pulling them in. Not a scope violation: these
  were pre-existing tests broken by a shared-widget fix, fixed to keep
  passing, not new screens localized early.
- **Payment Methods + Add Payment Method**: ~15 keys, including the
  "Remove this card?" confirm dialog. No RTL bugs -- both screens already
  used `Row`/`InputDecoration.prefixIcon` throughout.
- **Notification Settings + App Settings**: ~30 keys. `_communicationToggles`/
  `_typeToggles` (Notification Settings) converted from const lists to
  functions the same way Onboarding's `_pages` was. RTL bug:
  `_TypesCard`'s "Notification Types" strip used `Alignment.centerLeft`.
- **Privacy & Security + Help & Support**: ~55 keys, the largest single
  file in this phase (Change Password / Delete Account / Change Email,
  each its own inline form and validators). RTL bugs: `_PasswordField`'s
  show/hide eye icon (`Positioned(right:)` + fixed `contentPadding`, the
  same non-`prefixIcon` overlay pattern as Edit Profile's `_EditField`)
  and `_PrivacyRow`'s `Alignment.centerLeft`. Help & Support:
  `_ResourcesCard`'s row chevrons get the same RTL flip as
  `ProfileScreen`'s `_SettingsRow`; the FAQ accordion's own chevron
  (rotates in place to indicate open/closed, not a "leads forward"
  navigation cue) was deliberately left unmirrored -- reversing its
  glyph would also have required inverting its rotation direction to
  still land pointing down when open, and that's a real behavior change
  outside what the acceptance criteria asks for, not a one-line
  consistency fix.

**Pattern held from #63, confirmed at scale, not just asserted:** every
icon-then-text `Row` across all eight groups auto-mirrored with zero
changes; the only real bugs were physical `Alignment`/`Positioned`/
`EdgeInsets` values and un-mirrored directional icons (back arrows,
forward/previous chevrons, list-row chevrons) -- exactly the two
categories #63 predicted, no new category of RTL bug turned up across
~27 more screens.

**Final sweep caught two more files** the eight groups above didn't
cover, because they're `lib/widgets/`/`lib/screens/auth/` helpers, not
one of the ~27 screens on the task list: **`AppLockScreen`** (Sprint 8
Task 5's real lock screen, decision #62 -- shown whenever Auto-Lock
actually fires, so very much user-facing) had five hardcoded strings
plus the native biometric prompt's own reason text
(`BiometricService.authenticate(reason:)`, which the OS shows in its own
system dialog); and **`signOutAndShowLanding`** (`sign_out.dart`, shared
by every Sign Out control) had one SnackBar string. Both fully localized,
no RTL fixes needed (neither uses physical `Alignment`/`Positioned`).
Found by grepping the whole `lib/` tree for `Text('[A-Z]` a second time
after all eight groups were done, specifically to check for exactly this
kind of gap rather than assuming the group-by-group pass was exhaustive.

**One category of string deliberately left un-localized, same reasoning
as decision #63's `Validators` gap:** the `*Failure.message` strings
thrown by `lib/services/*.dart` (`ChangePasswordFailure`,
`DeleteAccountFailure`, `PaymentMethodFailure`, `ProfileUpdateFailure`,
etc.) -- these are plain Dart exception messages built inside service
methods with no `BuildContext` available at the throw site, then
displayed via `e.message` by the screens that catch them (already
localized this phase). Giving every service method a `BuildContext` or
`AppLocalizations` parameter to build these server-facing-error strings
would be a real signature change touching every service class and call
site app-wide -- the same scope boundary #63 already drew around
`Validators.email`. Logged here explicitly, not silently left
inconsistent: these ~15 messages across 6 service files still show
English text regardless of locale.

**Verified:** `flutter analyze` -- clean, whole project, after every
group. `flutter test` -- 277/277 throughout (English text never changed,
so no test needed updating for content, only the handful whose
`MaterialApp` needed the `AppLocalizations` delegate added because of the
shared-widget fixes above).

**Sign-off:** i18n/RTL now covers every screen and dialog a user can
actually navigate to, matching #63's acceptance criteria extended
app-wide. **Three things explicitly still open, not silently closed:**
(1) the Arabic translations -- now ~65 more strings on top of #63's --
remain AI-written and unreviewed by a fluent speaker, the user's own to
check per the earlier "you review the Arabic yourself" decision; (2)
French/Spanish stay real, storable picks with no translation yet
(decision #63's fallback caption still applies everywhere); (3) the
service-layer exception-message strings above stay English-only,
same scope boundary as `Validators`.

---

## Checkpoint: status of every open item, as of the end of Sprint 2

Went through every open gap/question in this file with the user before
starting the next task. Resolutions below.

- **ID Upload live file-picker flow (decision #18's testing gap):**
  confirmed — the user manually uploaded a real file and it worked
  correctly end to end. Closed, see the update at the end of decision #18.
- **Leftover test rows** (`RLS_TEST_...` in `storage.objects`, a stray
  `pending` `id_documents` row for `task2test`): **deliberately left in
  place for now** — the user will clean up test data in the database in
  one pass at the end rather than piecemeal. Not a bug, just deferred
  housekeeping.
- **No Sign Out on Choose Membership/Verify Your Membership** (decision
  #21): **confirmed intentional.** Sign out belongs on a Settings screen,
  the same way most apps do it — not sprinkled across every authenticated
  screen. It'll be built when Settings is built; no stopgap needed before
  then.
- **Other screens' fidelity to Figma** (Onboarding, Auth Landing, Sign In,
  Create Account, Forgot Password — decision #20's leftover scope):
  **deliberately not re-auditing these proactively.** The user will flag
  specific mismatches as they find them rather than have every screen
  re-checked against the API up front.
- **Payment gateway is mocked** (decision #4/#16): **staying mocked
  on purpose.** The user will get real Stripe credentials from the
  company later and wire that in as its own task — not guessed at now.
- **Custom SMTP via personal Gmail** (decision #14): the user confirmed
  Forgot Password actually delivers a real email right now, so the
  current setup is functionally working. The "fragile, personal-account"
  concern from decision #14 stands as a pre-handoff cleanup item, not
  something broken today.
- **PKCE code verifier in plain text** (decision #6): no strong opinion
  from the user either way. Leaving it as originally assessed — low
  priority, inactive risk since no magic-link/OAuth flow exists yet — and
  will revisit if such a flow gets built.
- **Signup flow order** (decision #1): **confirmed correct by the
  company** — this is the actual order they specified, not a guess
  anymore. Updated decision #1 above to drop the "unconfirmed" caveat.

## Genuinely open questions, deferred until their screens get built

These only matter once we're actually building the related screen — no
need to think about them now:

- **"Subscription Plan" field on the old two-screen signup confusion**
  (decision #1): moot in practice, since we made this field read-only
  rather than an editable dropdown — nothing left to decide here.
- **Event reservation pricing and event-type list**: both are live
  placeholders now, not hypothetical — the Event Reservation screens got
  built in Sprint 4 Tasks 4–5 (decisions #37/#38). Pricing is a flat
  "$150/hour", computed server-side from the single named
  `c_price_per_hour` constant in `create_event_reservation` (decision
  #36) exactly as decision #33 planned, so plugging in real numbers (and
  whether price should vary by event type) is a one-line change in one
  place, not a redesign. The Event Type dropdown's four options
  (Birthday / Corporate / Private Party / Other) are likewise a
  placeholder fixed in-code list (decision #37) — no backing table, and
  the design never confirmed a real list. Both still need the real
  answer from the company; nothing here blocks further work until then.
- **Full FAQ copy**: only 1 of 4 answers was visible in the design
  export — the other 3 are needed only once the Help & Support screen
  gets built.
- **Notification preferences storage** -- **resolved (#44):** local on-device
  setting only (`shared_preferences`), no table. Moving them to the backend stays
  tied to the open notifications-feed question below.
- **Notifications feed and its backing schema** (raised explicitly by
  Sprint 3, Task 8): what a notification actually is here (payment
  receipts? event reminders? door-access alerts? some mix?), whether it
  needs its own table or is synthesized from existing tables
  (`subscriptions`, `door_access_logs`, `event_reservations`), how
  read/unread state is tracked, and whether delivery
  is in-app-only or also push/email — all undecided. The Home bell
  (decision #32) deliberately stays a stub with no unread-count badge
  until this is answered, rather than a schema getting invented to make
  a badge number appear.

---

## Working process

- The company gave us the Figma design only — no written spec or task list.
  We're creating our own task breakdown as we go.
- We work through one screen/feature at a time and confirm it's right before
  moving to the next, rather than building everything at once.
