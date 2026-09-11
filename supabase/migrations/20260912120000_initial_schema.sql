-- Rosewater Café — initial schema
-- Apply with the Supabase CLI: supabase link --project-ref <ref>  then  supabase db push
-- (or paste into Dashboard > SQL Editor for a one-off run). Fresh-project only, not idempotent.

create extension if not exists pgcrypto;

create type public.subscription_status as enum ('active', 'expired', 'cancelled');
create type public.reservation_status as enum ('pending', 'confirmed', 'cancelled');
create type public.verification_status as enum ('pending', 'verified', 'rejected');

-- Generic "touch updated_at on every UPDATE" trigger, shared by all tables below.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================
-- profiles  (1:1 extension of auth.users)
-- ============================================================
create table public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  full_name  text,
  email      text not null,
  phone      text,
  avatar_url text,
  member_id  text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- Human-readable membership number, e.g. RC-000001. Assigned once, then immutable.
create sequence public.member_id_seq start 1;

create or replace function public.generate_member_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' then
    new.member_id := old.member_id; -- member_id can never be changed after assignment
    return new;
  end if;

  if new.member_id is null then
    new.member_id := 'RC-' || lpad(nextval('public.member_id_seq')::text, 6, '0');
  end if;
  return new;
end;
$$;

create trigger trg_profiles_member_id
before insert or update on public.profiles
for each row execute function public.generate_member_id();

-- Auto-create a profile row whenever someone signs up via Supabase Auth.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.email
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ============================================================
-- membership_plans  (reference / seed data — not user-writable)
-- ============================================================
create table public.membership_plans (
  id           uuid primary key default gen_random_uuid(),
  name         text not null unique,
  price_cents  integer not null check (price_cents >= 0),
  hookah_limit integer check (hookah_limit is null or hookah_limit >= 0), -- null = unlimited
  drinks_limit integer check (drinks_limit is null or drinks_limit >= 0), -- null = unlimited
  max_guests   integer not null default 0 check (max_guests >= 0),
  is_popular   boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create trigger trg_membership_plans_updated_at
before update on public.membership_plans
for each row execute function public.set_updated_at();

-- Assumption: Premium marked "popular" as the middle tier — adjust if you meant a different plan.
insert into public.membership_plans (name, price_cents, hookah_limit, drinks_limit, max_guests, is_popular)
values
  ('Basic',   9900,  10,   10,   1, false),
  ('Premium', 19900, 20,   20,   2, true),
  ('VIP',     39900, null, null, 2, false);

-- ============================================================
-- subscriptions  (writes are server-only — see RLS section)
-- ============================================================
create table public.subscriptions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  plan_id     uuid not null references public.membership_plans (id),
  status      public.subscription_status not null default 'active',
  started_at  timestamptz,
  valid_until timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_subscriptions_user_id on public.subscriptions (user_id);
create index idx_subscriptions_plan_id on public.subscriptions (plan_id);

-- Only one active subscription per user at a time.
create unique index uq_subscriptions_one_active_per_user
  on public.subscriptions (user_id)
  where (status = 'active');

create trigger trg_subscriptions_updated_at
before update on public.subscriptions
for each row execute function public.set_updated_at();

-- ============================================================
-- payment_methods  (tokenized references only — never raw PAN/CVV)
-- ============================================================
create table public.payment_methods (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  card_brand text not null,
  last4      char(4) not null check (last4 ~ '^[0-9]{4}$'),
  exp_month  smallint not null check (exp_month between 1 and 12),
  exp_year   smallint not null check (exp_year >= extract(year from now())::int),
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_payment_methods_user_id on public.payment_methods (user_id);

create trigger trg_payment_methods_updated_at
before update on public.payment_methods
for each row execute function public.set_updated_at();

-- Enforce "only one default card per user" without relying on client logic.
create or replace function public.enforce_single_default_payment_method()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_default then
    update public.payment_methods
    set is_default = false
    where user_id = new.user_id
      and id <> new.id
      and is_default;
  end if;
  return new;
end;
$$;

create trigger trg_payment_methods_single_default
after insert or update of is_default on public.payment_methods
for each row
when (new.is_default)
execute function public.enforce_single_default_payment_method();

-- ============================================================
-- usage_allowances  (writes are server-only — see RLS section)
-- ============================================================
create table public.usage_allowances (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  period_start date not null,
  period_end   date not null,
  hookah_used  integer not null default 0 check (hookah_used >= 0),
  drinks_used  integer not null default 0 check (drinks_used >= 0),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (user_id, period_start)
);

create index idx_usage_allowances_user_id on public.usage_allowances (user_id);

create trigger trg_usage_allowances_updated_at
before update on public.usage_allowances
for each row execute function public.set_updated_at();

-- ============================================================
-- door_access_logs  (writes are server-only — see RLS section)
-- ============================================================
create table public.door_access_logs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  accessed_at timestamptz not null default now(),
  guest_count integer not null default 0 check (guest_count >= 0),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_door_access_logs_user_id on public.door_access_logs (user_id);

create trigger trg_door_access_logs_updated_at
before update on public.door_access_logs
for each row execute function public.set_updated_at();

-- ============================================================
-- event_reservations
-- ============================================================
create table public.event_reservations (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  event_type     text not null,
  event_date     date not null,
  start_time     time not null,
  duration_hours numeric(4, 2) not null check (duration_hours > 0),
  guest_count    integer not null default 1 check (guest_count >= 0),
  status         public.reservation_status not null default 'pending',
  total_price    numeric(10, 2) not null check (total_price >= 0),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index idx_event_reservations_user_id on public.event_reservations (user_id);

create trigger trg_event_reservations_updated_at
before update on public.event_reservations
for each row execute function public.set_updated_at();

-- ============================================================
-- notifications
-- ============================================================
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  type       text not null,
  title      text not null,
  body       text,
  is_read    boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_notifications_user_id on public.notifications (user_id);

create trigger trg_notifications_updated_at
before update on public.notifications
for each row execute function public.set_updated_at();

-- ============================================================
-- id_documents  (verification_status is server-only — see RLS section)
-- ============================================================
create table public.id_documents (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references public.profiles (id) on delete cascade,
  storage_path        text not null,
  verification_status public.verification_status not null default 'pending',
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index idx_id_documents_user_id on public.id_documents (user_id);

create trigger trg_id_documents_updated_at
before update on public.id_documents
for each row execute function public.set_updated_at();

-- ============================================================
-- Storage: private bucket for ID documents
-- Convention: object path must be "<user_id>/<filename>"
-- ============================================================
insert into storage.buckets (id, name, public)
values ('id-documents', 'id-documents', false);

create policy "Users can read own id documents in storage"
on storage.objects for select
to authenticated
using (
  bucket_id = 'id-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can write own id documents in storage"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'id-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update own id documents in storage"
on storage.objects for update
to authenticated
using (
  bucket_id = 'id-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can delete own id documents in storage"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'id-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================================
-- Row Level Security
-- ============================================================
alter table public.profiles           enable row level security;
alter table public.membership_plans   enable row level security;
alter table public.subscriptions      enable row level security;
alter table public.payment_methods    enable row level security;
alter table public.usage_allowances   enable row level security;
alter table public.door_access_logs   enable row level security;
alter table public.event_reservations enable row level security;
alter table public.notifications      enable row level security;
alter table public.id_documents       enable row level security;

-- profiles: SELECT/UPDATE own row. No INSERT policy — rows are created
-- exclusively by the handle_new_user trigger (security definer).
create policy "Users can view own profile"
on public.profiles for select to authenticated
using (auth.uid() = id);

create policy "Users can update own profile"
on public.profiles for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- membership_plans: public reference data, readable by anyone, writable by
-- no one from the client (manage via dashboard / service role).
create policy "Anyone can view membership plans"
on public.membership_plans for select to authenticated
using (true);

-- subscriptions: SELECT only from the client. Activating/renewing/cancelling
-- a subscription is billing-authoritative and must happen server-side
-- (e.g. a payment webhook using the service role key) — otherwise a user
-- could grant themselves free VIP access by writing their own row.
create policy "Users can view own subscriptions"
on public.subscriptions for select to authenticated
using (auth.uid() = user_id);

-- payment_methods: fully user-managed, including removal.
create policy "Users can view own payment methods"
on public.payment_methods for select to authenticated
using (auth.uid() = user_id);

create policy "Users can add own payment methods"
on public.payment_methods for insert to authenticated
with check (auth.uid() = user_id);

create policy "Users can update own payment methods"
on public.payment_methods for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own payment methods"
on public.payment_methods for delete to authenticated
using (auth.uid() = user_id);

-- usage_allowances: SELECT only from the client. Counters must only be
-- incremented by a trusted server process (e.g. when a door scan or drink
-- order is recorded) — otherwise a user could reset their own limits.
create policy "Users can view own usage allowances"
on public.usage_allowances for select to authenticated
using (auth.uid() = user_id);

-- door_access_logs: SELECT only from the client, no DELETE (audit trail).
-- A log entry is proof someone physically scanned in — it must be written
-- server-side, not self-reported/edited by the user's own device.
create policy "Users can view own door access logs"
on public.door_access_logs for select to authenticated
using (auth.uid() = user_id);

-- event_reservations: fully user-managed except DELETE (history is kept).
create policy "Users can view own reservations"
on public.event_reservations for select to authenticated
using (auth.uid() = user_id);

create policy "Users can create own reservations"
on public.event_reservations for insert to authenticated
with check (auth.uid() = user_id);

create policy "Users can update own reservations"
on public.event_reservations for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- notifications: fully user-managed except DELETE.
create policy "Users can view own notifications"
on public.notifications for select to authenticated
using (auth.uid() = user_id);

create policy "Users can create own notifications"
on public.notifications for insert to authenticated
with check (auth.uid() = user_id);

create policy "Users can update own notifications"
on public.notifications for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- id_documents: users can upload their own ID and view its status, but
-- cannot set verification_status themselves (no UPDATE policy at all) —
-- that's an admin/service-role-only action.
create policy "Users can view own id documents"
on public.id_documents for select to authenticated
using (auth.uid() = user_id);

create policy "Users can upload own id documents"
on public.id_documents for insert to authenticated
with check (auth.uid() = user_id and verification_status = 'pending');
