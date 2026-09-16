-- Scheduled expiry: nothing else in this project ever flips an 'active'
-- subscription to 'expired' once valid_until passes -- without this, Home
-- (Sprint 3, the first screen that actually *reads* subscriptions/
-- usage_allowances instead of just writing them once) would show a
-- subscription from months ago as active forever. See docs/decisions.md
-- #25 for the full writeup, including why this is deliberately paired with
-- a defensive check in SubscriptionService.hasActiveSubscription() instead
-- of relying on the cron job alone.
--
-- expire_subscriptions() is NOT a per-user RPC like start_subscription /
-- confirm_subscription_payment / cancel_subscription -- it's a batch job
-- that touches every user's rows, not just the caller's own. So unlike
-- those three, EXECUTE is revoked from `authenticated` too, not just
-- `anon`/PUBLIC: no client role should ever be able to call this directly.
-- Only pg_cron's own scheduled invocation (which runs as the database
-- owner, not through PostgREST/a client role) is meant to run it.
create or replace function public.expire_subscriptions()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.subscriptions
  set status = 'expired'
  where status = 'active'
    and valid_until < now();
end;
$$;

revoke execute on function public.expire_subscriptions() from public;
revoke execute on function public.expire_subscriptions() from anon;
revoke execute on function public.expire_subscriptions() from authenticated;

-- Requires the pg_cron extension enabled on this project (Dashboard ->
-- Database -> Extensions -> pg_cron, or this CREATE EXTENSION does it
-- directly if the migration runner has privileges to).
create extension if not exists pg_cron with schema cron;

-- Idempotent on rerun: cron.schedule() with a name already in cron.job
-- would otherwise add a second, duplicate job instead of replacing it.
do $$
begin
  if exists (select 1 from cron.job where jobname = 'expire-subscriptions-daily') then
    perform cron.unschedule('expire-subscriptions-daily');
  end if;
end;
$$;

select cron.schedule(
  'expire-subscriptions-daily',
  '0 3 * * *',
  $$select public.expire_subscriptions()$$
);
