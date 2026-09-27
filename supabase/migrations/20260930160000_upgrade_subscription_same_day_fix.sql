-- Fix for 20260930150000_upgrade_subscription (decision #75 follow-up).
--
-- Found verifying that migration on the live project: upgrading on the
-- same day a usage period already started -- a member who paid for a
-- plan today and upgrades today, or upgrades twice in one day -- failed
-- with `23505 duplicate key value violates unique constraint
-- "usage_allowances_user_id_period_start_key"`: usage_allowances allows
-- one row per user per period_start, and the upgrade always inserted a
-- new row starting today. The whole upgrade rolled back, so nothing was
-- corrupted, but the upgrade was impossible.
--
-- Only change from 20260930150000: that usage insert now reuses today's
-- row when there is one (ON CONFLICT DO UPDATE), resetting it to a fresh
-- zeroed period. Everything else -- auth, locking, the price check, the
-- cancel-then-insert order, the grants -- is identical.

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

  -- A usage row starting today may already exist (paid today, or a
  -- second upgrade today) -- `unique (user_id, period_start)` would reject
  -- a second one and abort the whole upgrade. Reuse it as the fresh
  -- period instead: new end date, usage back to zero, and the low-
  -- allowance "already alerted" markers (decision #70) cleared.
  insert into public.usage_allowances (user_id, period_start, period_end)
  values (v_user_id, current_date, v_valid_until::date)
  on conflict (user_id, period_start) do update
    set period_end = excluded.period_end,
        hookah_used = 0,
        drinks_used = 0,
        hookah_alert_sent = false,
        drinks_alert_sent = false;

  return v_valid_until;
end;
$$;

revoke execute on function public.upgrade_subscription(uuid) from public;
revoke execute on function public.upgrade_subscription(uuid) from anon;
grant execute on function public.upgrade_subscription(uuid) to authenticated;
