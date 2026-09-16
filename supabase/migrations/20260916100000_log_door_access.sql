-- log_door_access: records a real door-entry event (arrival + guest
-- count) into door_access_logs. This is the ONLY way a row gets written
-- to that table from the client -- there is no INSERT policy on
-- door_access_logs for the `authenticated` role (see initial_schema.sql;
-- it only has a SELECT policy).
--
-- Security model, same pattern as every prior RPC in this project
-- (start_subscription/confirm_subscription_payment, cancel_subscription,
-- expire_subscriptions):
--
--  * SECURITY DEFINER with `search_path` pinned to `public` -- an
--    unpinned search_path on a SECURITY DEFINER function is a classic
--    privilege-escalation bug (decision #16).
--  * Reads auth.uid() itself rather than accepting a user_id argument --
--    a caller-supplied user_id would let any authenticated user log
--    access (and consume someone else's guest allowance) as a stranger.
--  * EXECUTE is revoked from PUBLIC *and*, explicitly, from `anon`.
--    Revoking from PUBLIC alone is not enough on Supabase -- its
--    platform grants EXECUTE on every new `public` function directly to
--    `anon`/`authenticated`/`service_role` as separate ACL entries the
--    moment it's created, which a bare `revoke ... from public` does not
--    touch (decision #16).
--
-- Two checks this function does NOT trust the client for, per decision
-- #34 (see docs/decisions.md):
--
--  1. Active membership: re-runs the exact `status = 'active' and
--     valid_until > now()` check from decisions #25/#27 -- a lapsed
--     member shouldn't be able to log door access at all, not just fail
--     to see "Active" rendered on Home. A stale `status = 'active'` row
--     the daily expire_subscriptions() cron hasn't caught yet is still
--     correctly rejected here because of the `valid_until` half of the
--     check.
--  2. Guest count: fetches the caller's own plan's real `max_guests` and
--     validates `0 <= guest_count <= max_guests` server-side. The
--     client's own stepper widget enforcing this is UX, not security --
--     this function must reject an out-of-range value even if someone
--     calls the RPC directly with a number the UI would never send.
--
-- Deliberately does NOT touch usage_allowances (decision #33) -- this
-- app has no way to know what a member actually consumes once inside
-- (a hookah lit, a drink poured), so a door access event only ever
-- records arrival + guest count, nothing else.
create or replace function public.log_door_access(p_guest_count integer)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_max_guests integer;
  v_log_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_guest_count is null then
    raise exception 'guest_count_required';
  end if;

  select p.max_guests into v_max_guests
  from public.subscriptions s
  join public.membership_plans p on p.id = s.plan_id
  where s.user_id = v_user_id
    and s.status = 'active'
    and s.valid_until > now()
  limit 1;

  if not found then
    raise exception 'no_active_subscription';
  end if;

  if p_guest_count < 0 or p_guest_count > v_max_guests then
    raise exception 'guest_count_exceeds_plan_limit'
      using detail = json_build_object(
        'max_guests', v_max_guests,
        'requested', p_guest_count
      )::text;
  end if;

  insert into public.door_access_logs (user_id, guest_count)
  values (v_user_id, p_guest_count)
  returning id into v_log_id;

  return v_log_id;
end;
$$;

revoke execute on function public.log_door_access(integer) from public;
revoke execute on function public.log_door_access(integer) from anon;
grant execute on function public.log_door_access(integer) to authenticated;
