-- Notification preferences, stored in the database so the server can respect them (for example, not
-- sending emails to users who turned them off).
--
-- One row per user, one column per switch. The defaults match the app (SMS off, the rest on). No
-- row is created up front: the app creates it the first time a switch is changed, and a missing row
-- means "all defaults".

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

-- Users can read, create and change only their own row. No DELETE: the row is removed with the
-- profile.
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

-- Grant exactly what the policies allow. Supabase grants everything on new tables by default, so
-- revoke that first.
revoke all on public.notification_preferences from anon;
revoke all on public.notification_preferences from authenticated;
grant select, insert, update on public.notification_preferences to authenticated;
