-- Marks subscriptions as 'expired' once valid_until has passed. The app also checks valid_until
-- itself, since this only runs once a day.
--
-- This is a batch job over every user, so no app role may call it (EXECUTE is revoked from
-- authenticated too). Only the scheduled job runs it.
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

-- Needs the pg_cron extension (Dashboard > Database > Extensions).
create extension if not exists pg_cron with schema cron;

-- Safe to re-run: remove an existing job with the same name first, so it isn't scheduled twice.
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
