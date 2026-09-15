-- ============================================================
-- Two-RPC subscription activation pattern
--
-- Security model (read this before touching either function below):
--
--  * subscriptions and usage_allowances have no INSERT/UPDATE policy for
--    the `authenticated` role (see initial_schema.sql -- both tables only
--    have a SELECT policy). With RLS enabled, "no policy for this command"
--    means every direct write from the client is denied, full stop.
--
--  * These two functions are therefore the ONLY way rows get written to
--    either table. They are SECURITY DEFINER (run with the function
--    owner's privileges, bypassing RLS) with `search_path` pinned to
--    `public`, matching every other SECURITY DEFINER function in this
--    project (generate_member_id, handle_new_user,
--    enforce_single_default_payment_method). An unpinned search_path on
--    a SECURITY DEFINER function is a classic privilege-escalation bug:
--    a caller could get an object they control (e.g. in a schema earlier
--    in their own search_path) resolved and executed with the definer's
--    elevated privileges instead of the intended one.
--
--  * Both functions read `auth.uid()` themselves for whose row to touch --
--    neither accepts a user_id argument. If user_id were a parameter,
--    any authenticated caller could pass someone else's id and write to
--    a stranger's subscription.
--
--  * EXECUTE is revoked from PUBLIC *and*, explicitly, from `anon`. Just
--    revoking from PUBLIC is not enough on Supabase: its platform runs a
--    default-privileges trigger that grants EXECUTE on every new function
--    in `public` directly to `anon`/`authenticated`/`service_role` as
--    separate ACL entries the moment it's created -- REVOKE ... FROM
--    PUBLIC only removes the generic "everyone" grant, it does not touch
--    those already-existing per-role grants. Skipping the explicit
--    `revoke ... from anon` leaves signed-out callers able to execute the
--    function (verified: it let `anon` invoke start_subscription, which
--    then only failed because of the internal auth.uid() is null check --
--    that's defense-in-depth catching it, not the intended primary
--    defense).
-- ============================================================

-- New subscriptions must start unpaid. (The old default of 'active'
-- predates this pending step and would let any future insert activate a
-- subscription without ever going through confirm_subscription_payment.)
alter table public.subscriptions
  alter column status set default 'pending';

-- Defense in depth against a race: two concurrent start_subscription calls
-- for the same user could both pass the "no existing pending row" check
-- below before either one commits its insert. This index makes the second
-- insert fail instead of silently creating two pending rows; the function
-- catches that failure and reports it the same way as the checked case.
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

  -- Already active: don't silently start a second one. Plan upgrades /
  -- switches are a separate feature for a later sprint -- for now the app
  -- should catch this, show the existing plan + valid_until, and ask the
  -- user what they want to do.
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

  -- Already has an unpaid pending subscription: don't silently cancel it
  -- and don't silently stack another one -- surface it so the app can ask
  -- the user whether to resume checkout on the old one or cancel it first.
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
    -- Lost the race described above -- another request for this user
    -- inserted its pending row first.
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

  -- TODO(payments): there is no real payment gateway wired up yet, so this
  -- call just marks the subscription paid with no charge attached. Any
  -- authenticated user can activate their own pending subscription for
  -- free by calling this directly. Accepted as a known, temporary gap for
  -- this sprint -- must be replaced with a server-verified charge (e.g. a
  -- payment provider webhook) before this goes anywhere near production.
  --
  -- The `and status = 'pending'` guard below is still load-bearing even
  -- with the mock payment: it makes the call idempotent (calling it again
  -- on an already-active subscription does nothing) and, combined with
  -- `user_id = v_user_id`, it stops a caller from activating someone
  -- else's subscription by guessing/enumerating subscription ids.
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
