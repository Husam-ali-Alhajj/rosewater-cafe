-- Notifications roadmap, step 1: notification preferences move from the
-- device (shared_preferences, decision #44) into the database.
--
-- Why now: every channel still to be built -- email, push, scheduled
-- event reminders, allowance alerts, promotions -- is sent by the SERVER,
-- and the server can't see a phone's local storage. A toggle that only
-- lives on the device could never stop an email from going out.
--
-- One row per user, one boolean column per toggle on the Notification
-- Settings screen. Column defaults are exactly the Figma frame's initial
-- state (SMS off, everything else on) and match
-- `NotificationSetting.defaultValue` in lib/services/notification_prefs.dart,
-- so a user with no row yet and a freshly inserted row mean the same
-- thing. No row is created up front: the app upserts one the first time a
-- toggle is flipped, and every reader (the app now, server-side senders
-- later) treats a missing row as "all defaults" via coalesce.

create table public.notification_preferences (
  user_id          uuid primary key references public.profiles (id) on delete cascade,
  push             boolean not null default true,
  email            boolean not null default true,
  sms              boolean not null default false,
  sound            boolean not null default true,
  event_reminders  boolean not null default true,
  allowance_alerts boolean not null default true,
  promotions       boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create trigger trg_notification_preferences_updated_at
before update on public.notification_preferences
for each row execute function public.set_updated_at();

-- Client access: a user reads, creates and changes only their own row.
-- No DELETE -- turning everything off is an UPDATE, and the row goes away
-- with the profile (on delete cascade).
alter table public.notification_preferences enable row level security;

create policy "Users can view own notification preferences"
  on public.notification_preferences for select
  to authenticated
  using (user_id = auth.uid());

create policy "Users can create own notification preferences"
  on public.notification_preferences for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "Users can update own notification preferences"
  on public.notification_preferences for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Table privileges to match the policies exactly, rather than relying on
-- the blanket grants Supabase gives every new table (decision #16: a
-- `revoke ... from public` alone doesn't undo those).
revoke all on public.notification_preferences from anon;
revoke all on public.notification_preferences from authenticated;
grant select, insert, update on public.notification_preferences to authenticated;
