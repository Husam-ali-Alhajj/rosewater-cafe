-- Delete Account requests, processed by staff (later replaced by self-service deletion in
-- 20260925100000).
--
-- Users could insert a 'pending' request for themselves and read their own requests, but not change
-- or delete them. One open request per user.

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
