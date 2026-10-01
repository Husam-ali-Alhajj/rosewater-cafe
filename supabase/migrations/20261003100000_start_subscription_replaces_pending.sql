-- Choosing a plan now replaces an unpaid (pending) membership instead of rejecting the request.
--
-- Before, a user who picked a plan and closed the app before paying was stuck: Choose Membership
-- refused every plan ("request in progress") and nothing let them cancel the old one.
--
-- Only the pending check changed: the old pending row is cancelled, then a new one is created.
-- An active membership is still rejected.

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

  -- An unpaid one from earlier is replaced by this choice.
  update public.subscriptions
  set status = 'cancelled'
  where user_id = v_user_id and status = 'pending';

  insert into public.subscriptions (user_id, plan_id, status)
  values (v_user_id, p_plan_id, 'pending')
  returning id into v_subscription_id;

  return v_subscription_id;
exception
  when unique_violation then
    -- Two plan choices at the same moment; the other one won.
    raise exception 'pending_subscription_exists';
end;
$$;

revoke execute on function public.start_subscription(uuid) from public;
revoke execute on function public.start_subscription(uuid) from anon;
grant execute on function public.start_subscription(uuid) to authenticated;
