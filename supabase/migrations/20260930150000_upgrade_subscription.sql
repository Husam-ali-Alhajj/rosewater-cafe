-- upgrade_subscription: moves a member from their active plan to a more expensive one in a single
-- call.
--
-- Same security setup as the other functions: SECURITY DEFINER, fixed search_path, auth.uid()
-- instead of a user id, and EXECUTE revoked from PUBLIC and anon.
--
-- It checks on the server that:
-- 1. the membership is active and hasn't ended (not just status = 'active', since expiry runs only
-- once a day), and
-- 2. the new plan costs more. Equal or cheaper plans are rejected with `downgrade_not_supported`.
--
-- The current row is locked (`for update`) so two upgrades at the same moment can't both go
-- through. The old subscription is cancelled before the new one is inserted, because only one
-- active subscription per user is allowed.
--
-- The new plan gets a fresh 30-day period and a new usage row (no proration).
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
