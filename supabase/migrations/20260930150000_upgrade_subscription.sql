-- Sprint 9 Task 3 -- upgrade_subscription: lets a member switch from
-- their current active plan straight to a more expensive one, in one
-- call, without an intermediate "cancel, then start_subscription, then
-- confirm_subscription_payment" dance the client would otherwise have to
-- orchestrate itself (and could get half-done if it crashed partway).
--
-- Security model, same pattern as every prior RPC in this project
-- (start_subscription/confirm_subscription_payment, cancel_subscription,
-- log_door_access, create_event_reservation, delete_own_account, ...):
--
--  * SECURITY DEFINER with `search_path` pinned to `public`.
--  * Reads auth.uid() itself rather than accepting a user_id argument --
--    a caller-supplied user_id would let any authenticated user upgrade
--    (and re-bill, once real payments exist) a stranger's subscription.
--  * EXECUTE is revoked from PUBLIC *and*, explicitly, from `anon` --
--    revoking from PUBLIC alone is not enough on Supabase, which grants
--    EXECUTE on every new function directly to `anon`/`authenticated`/
--    `service_role` as separate ACL entries the moment it's created, a
--    bare `revoke ... from public` does not touch those (decision #16).
--
-- Two things this function does NOT trust the client for:
--
--  1. "Active" means the same defensive thing it means everywhere else
--     in this project (decision #27's `log_door_access`/Home dashboard
--     check): `status = 'active' AND valid_until > now()`, not just
--     `status = 'active'` -- a stale row the daily expire_subscriptions
--     cron hasn't caught up to yet must not be upgradeable, the same way
--     it must not still grant door access.
--  2. Whether the target plan is actually more expensive: the row is
--     locked (`for update`) and its price re-read from
--     `membership_plans` inside this same transaction, never trusted
--     from anything the client claims about either plan. Equal or
--     cheaper is rejected with a fixed, machine-readable
--     `downgrade_not_supported` error (task's own wording) -- downgrades
--     are a different feature, with different proration/refund
--     implications, that this project hasn't built.
--
-- `for update of s` locks the caller's current active row for the rest
-- of this transaction: without it, two concurrent upgrade calls could
-- each read the same "currently active, price X" snapshot and both
-- proceed, racing each other through the cancel-then-insert below.
--
-- The cancel happens BEFORE the insert, deliberately, not just for
-- transaction ordering neatness: `uq_subscriptions_one_active_per_user`
-- (initial_schema.sql) is a partial unique index on `(user_id) where
-- status = 'active'` -- inserting the new active row before the old one
-- is flipped to `cancelled` would violate that constraint and abort the
-- whole upgrade.
--
-- Fresh `valid_until`/`usage_allowances` row, not prorated from whatever
-- time was left on the old plan -- same flat "30 days from now, one new
-- usage_allowances row" shape `confirm_subscription_payment` already
-- uses for a brand new subscription, since this project has no proration
-- logic anywhere and the task didn't ask for any. The new
-- `usage_allowances` row's `hookah_used`/`drinks_used` need no explicit
-- `0` here -- that's the column's own default (initial_schema.sql),
-- exactly like every other place this project creates one.
create or replace function public.upgrade_subscription(p_new_plan_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_valid_until timestamptz := now() + interval '30 days';
  v_old_id uuid;
  v_old_price integer;
  v_new_price integer;
  v_new_sub_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  select s.id, mp.price_cents
  into v_old_id, v_old_price
  from public.subscriptions s
  join public.membership_plans mp on mp.id = s.plan_id
  where s.user_id = v_user_id
    and s.status = 'active'
    and s.valid_until > now()
  for update of s;

  if v_old_id is null then
    raise exception 'no_active_subscription';
  end if;

  select price_cents into v_new_price
  from public.membership_plans
  where id = p_new_plan_id;

  if v_new_price is null then
    raise exception 'plan_not_found';
  end if;

  if v_new_price <= v_old_price then
    raise exception 'downgrade_not_supported'
      using detail = json_build_object(
        'current_price_cents', v_old_price,
        'requested_price_cents', v_new_price
      )::text;
  end if;

  update public.subscriptions
  set status = 'cancelled'
  where id = v_old_id;

  insert into public.subscriptions (user_id, plan_id, status, started_at, valid_until)
  values (v_user_id, p_new_plan_id, 'active', now(), v_valid_until)
  returning id into v_new_sub_id;

  insert into public.usage_allowances (user_id, period_start, period_end)
  values (v_user_id, current_date, v_valid_until::date);

  return v_valid_until;
end;
$$;

revoke execute on function public.upgrade_subscription(uuid) from public;
revoke execute on function public.upgrade_subscription(uuid) from anon;
grant execute on function public.upgrade_subscription(uuid) to authenticated;
