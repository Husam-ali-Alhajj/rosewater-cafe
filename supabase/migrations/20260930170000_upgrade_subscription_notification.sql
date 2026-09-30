-- upgrade_subscription now also creates a "Membership Upgraded" notification, which also triggers
-- the email, the live badge and the arrival sound.
--
-- The only changes: the old and new plan names are read, and one notification is inserted at the
-- end.

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
  v_old_plan_name text;
  v_new_plan_name text;
  v_old_price integer;
  v_new_price integer;
  v_new_sub_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  select s.id, mp.price_cents, mp.name
  into v_old_id, v_old_price, v_old_plan_name
  from public.subscriptions s
  join public.membership_plans mp on mp.id = s.plan_id
  where s.user_id = v_user_id
    and s.status = 'active'
    and s.valid_until > now()
  for update of s;

  if v_old_id is null then
    raise exception 'no_active_subscription';
  end if;

  select price_cents, name into v_new_price, v_new_plan_name
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

  -- A usage row starting today may already exist (paid today, or a second upgrade today). Reuse it
  -- instead of failing: new end date, usage back to zero, alert flags cleared.
  insert into public.usage_allowances (user_id, period_start, period_end)
  values (v_user_id, current_date, v_valid_until::date)
  on conflict (user_id, period_start) do update
    set period_end = excluded.period_end,
        hookah_used = 0,
        drinks_used = 0,
        hookah_alert_sent = false,
        drinks_alert_sent = false;

  -- Notify the user about the upgrade, using the plan names and date this function just read or
  -- set.
  insert into public.notifications (user_id, type, title, body, related_id, data)
  values (
    v_user_id,
    'subscription_upgraded',
    'Membership Upgraded',
    'You''ve upgraded from ' || v_old_plan_name || ' to ' || v_new_plan_name ||
      '. Your new membership is active until ' || to_char(v_valid_until, 'Mon DD, YYYY') || '.',
    v_new_sub_id,
    jsonb_build_object(
      'previous_plan_name', v_old_plan_name,
      'plan_name', v_new_plan_name,
      'valid_until', v_valid_until
    )
  );

  return v_valid_until;
end;
$$;

revoke execute on function public.upgrade_subscription(uuid) from public;
revoke execute on function public.upgrade_subscription(uuid) from anon;
grant execute on function public.upgrade_subscription(uuid) to authenticated;
