-- Sprint 5 Task 5 (Privacy & Security): Delete Account as a REQUEST QUEUE.
--
-- Decision (docs/decisions.md #45): Supabase's client SDK deliberately cannot
-- delete an auth user -- that is an admin (service_role) operation. Rather than
-- build a client-callable SECURITY DEFINER function with power over the auth
-- schema, "Delete Account" in the app only records a request here, for a person
-- to process manually. NOTHING is deleted, deactivated or changed by making a
-- request: the account, its data and its sessions stay exactly as they were
-- until staff act on it in the dashboard.
--
-- What the client can do, and nothing more:
--   * INSERT a request for itself, and only as 'pending' (the policy's WITH CHECK
--     rejects any other status or another user's id).
--   * SELECT its own requests (so the app can show "deletion requested").
--   * There is NO UPDATE or DELETE policy: a user can't edit, cancel or hide a
--     request from the app. Cancelling, completing or rejecting one is done by
--     staff (dashboard / service role), which bypasses RLS.
-- A partial unique index allows at most one open ('pending') request per user,
-- so tapping the button twice (or racing two requests) can't queue duplicates.
--
-- Processing a request is a manual staff step, not part of this migration: look
-- up user_id, delete the auth user in the dashboard (which cascades to the
-- profile and everything hanging off it, including this row), or mark the
-- request 'cancelled'.

create type public.deletion_request_status as enum ('pending', 'cancelled', 'completed');

create table public.deletion_requests (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  status       public.deletion_request_status not null default 'pending',
  requested_at timestamptz not null default now(),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index idx_deletion_requests_user_id on public.deletion_requests (user_id);

create unique index uq_deletion_requests_one_pending_per_user
  on public.deletion_requests (user_id)
  where (status = 'pending');

create trigger trg_deletion_requests_updated_at
before update on public.deletion_requests
for each row execute function public.set_updated_at();

alter table public.deletion_requests enable row level security;

create policy "Users can view own deletion requests"
on public.deletion_requests for select to authenticated
using (auth.uid() = user_id);

create policy "Users can request deletion of own account"
on public.deletion_requests for insert to authenticated
with check (auth.uid() = user_id and status = 'pending');
