-- Subscriptions are created and activated with two functions.
--
-- - Users can't write to subscriptions or usage_allowances directly (no INSERT/UPDATE policy), so
-- these functions are the only way in.
-- - They are SECURITY DEFINER with a fixed search_path, so they can't be tricked into running
-- someone else's objects.
-- - They use auth.uid() instead of taking a user id, so nobody can act on another user's
-- subscription.
-- - EXECUTE is revoked from PUBLIC and also from `anon`: Supabase grants every new function to
-- `anon` directly, so revoking from PUBLIC alone isn't enough.

-- New subscriptions start unpaid, so they can only be activated through
-- confirm_subscription_payment.
alter table public.subscriptions
  alter column status set default 'pending';

-- Stops two requests at the same moment from creating two pending subscriptions. The function
-- catches the error and reports it normally.
create unique index uq_subscriptions_one_pending_per_user
  on public.subscriptions (user_id)
  where (status = 'pending');

create or replace function public.start_subscription(p_plan_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_subscription_id uuid;
  v_existing record;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  -- Already active: don't start a second one.
  select id, plan_id, valid_until into v_existing
  from public.subscriptions
  where user_id = v_user_id and status = 'active'
  limit 1;

  if found then
    raise exception 'active_subscription_exists'
      using detail = json_build_object(
        'subscription_id', v_existing.id,
        'plan_id', v_existing.plan_id,
        'valid_until', v_existing.valid_until
      )::text;
  end if;

  -- Already has an unpaid pending subscription: tell the app instead of creating another.
  select id, plan_id into v_existing
  from public.subscriptions
  where user_id = v_user_id and status = 'pending'
  limit 1;

  if found then
    raise exception 'pending_subscription_exists'
      using detail = json_build_object(
        'subscription_id', v_existing.id,
        'plan_id', v_existing.plan_id
      )::text;
  end if;

  insert into public.subscriptions (user_id, plan_id, status)
  values (v_user_id, p_plan_id, 'pending')
  returning id into v_subscription_id;

  return v_subscription_id;
exception
  when unique_violation then
    -- Another request created the pending row first.
    raise exception 'pending_subscription_exists';
end;
$$;

revoke execute on function public.start_subscription(uuid) from public;
revoke execute on function public.start_subscription(uuid) from anon;
grant execute on function public.start_subscription(uuid) to authenticated;

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
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  -- TODO(payments): there's no real payment gateway yet, so this just marks the subscription paid.
  -- A signed-in user could activate their own pending subscription for free by calling this
  -- directly. Must be replaced with a server-verified payment before going live.
  --
  -- The `status = 'pending'` check makes repeat calls do nothing, and together with `user_id =
  -- v_user_id` stops anyone activating another user's subscription.
  update public.subscriptions
  set status = 'active',
      started_at = now(),
      valid_until = v_valid_until
  where id = p_subscription_id
    and user_id = v_user_id
    and status = 'pending'
  returning id into v_found_id;

  if v_found_id is null then
    raise exception 'subscription_not_found_or_not_pending';
  end if;

  insert into public.usage_allowances (user_id, period_start, period_end)
  values (v_user_id, current_date, v_valid_until::date);

  return v_valid_until;
end;
$$;

revoke execute on function public.confirm_subscription_payment(uuid) from public;
revoke execute on function public.confirm_subscription_payment(uuid) from anon;
grant execute on function public.confirm_subscription_payment(uuid) to authenticated;
