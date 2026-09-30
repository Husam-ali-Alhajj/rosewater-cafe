-- Fix: a same-day re-subscribe could fail in confirm_subscription_payment
-- (decision #81).
--
-- usage_allowances allows one row per user per period_start, and this
-- function always inserted a new row starting today. A member can't reach
-- that through the app (they can't cancel an active membership, nor start
-- one while active), but if a membership is cancelled directly in the
-- database (e.g. by staff) and the member re-subscribes the same day,
-- paying failed with `23505 duplicate key value violates unique
-- constraint "usage_allowances_user_id_period_start_key"` -- reproduced on
-- the live dev project. upgrade_subscription had the same problem and got
-- this same fix in 20260930160000.
--
-- Only change from 20261001100000's version: the usage insert reuses
-- today's row when one exists (ON CONFLICT DO UPDATE).

create or replace function public.confirm_subscription_payment(p_subscription_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_valid_until timestamptz := now() + interval '30 days';
  v_found_id uuid;
  v_plan_id uuid;
  v_plan_name text;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  update public.subscriptions
  set status = 'active',
      started_at = now(),
      valid_until = v_valid_until
  where id = p_subscription_id
    and user_id = v_user_id
    and status = 'pending'
  returning id, plan_id into v_found_id, v_plan_id;

  if v_found_id is null then
    raise exception 'subscription_not_found_or_not_pending';
  end if;

  -- A usage row starting today may already exist (see this migration's
  -- header) -- reuse it as this subscription's fresh period instead of
  -- failing on `unique (user_id, period_start)`: re-pointed here, usage
  -- back to zero, low-allowance markers (#70) cleared. Same fix as
  -- upgrade_subscription's (20260930160000).
  insert into public.usage_allowances (user_id, subscription_id, period_start, period_end)
  values (v_user_id, v_found_id, current_date, v_valid_until::date)
  on conflict (user_id, period_start) do update
    set subscription_id = excluded.subscription_id,
        period_end = excluded.period_end,
        hookah_used = 0,
        drinks_used = 0,
        hookah_alert_sent = false,
        drinks_alert_sent = false;

  select name into v_plan_name from public.membership_plans where id = v_plan_id;

  insert into public.notifications (user_id, type, title, body, related_id, data)
  values (
    v_user_id,
    'subscription_activated',
    'Membership Activated',
    'Your ' || v_plan_name || ' membership is now active until ' || to_char(v_valid_until, 'Mon DD, YYYY') || '.',
    v_found_id,
    jsonb_build_object('plan_name', v_plan_name, 'valid_until', v_valid_until)
  );

  return v_valid_until;
end;
$$;

revoke execute on function public.confirm_subscription_payment(uuid) from public;
revoke execute on function public.confirm_subscription_payment(uuid) from anon;
grant execute on function public.confirm_subscription_payment(uuid) to authenticated;
