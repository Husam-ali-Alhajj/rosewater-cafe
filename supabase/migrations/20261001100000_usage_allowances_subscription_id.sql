-- Sprint 10 Task 1: usage_allowances.subscription_id -- a real FK linking
-- each usage row to the subscription it belongs to, instead of picking
-- "whichever usage_allowances row for this user has the latest
-- period_start" and hoping that's the current one. That heuristic
-- (decision #28) happened to work while a user only ever had one row, but
-- breaks the moment it doesn't: a lapsed member whose subscription expired
-- would still show their last period's leftover hookah/drink counts as if
-- they were current, and a same-day-upgrade's reused row (decision #75's
-- same-day fix) has no way to prove *which* subscription it now belongs to
-- other than "it happens to be the newest".

-- ------------------------------------------------------------
-- 1. Add the column, nullable at first (existing rows have none yet)
-- ------------------------------------------------------------
alter table public.usage_allowances
  add column subscription_id uuid references public.subscriptions (id) on delete cascade;

-- ------------------------------------------------------------
-- 2. Backfill existing rows, best-effort
-- ------------------------------------------------------------

-- Pass 1: an EXACT date match first. Every usage_allowances row this app
-- has ever inserted (confirm_subscription_payment, upgrade_subscription)
-- was written in the same transaction, from the same `now()`/`current_date`,
-- as the subscription row it belongs to -- so period_start/period_end and
-- that subscription's started_at/valid_until (cast to date) line up
-- exactly. This has to run BEFORE the looser overlap pass below, because a
-- same-day upgrade leaves two subscriptions (the just-cancelled old one and
-- the new active one) whose date ranges both genuinely overlap a reused
-- usage row -- only the exact match tells them apart correctly (the
-- reused row keeps the OLD row's period_start, but the trigger's own
-- ON CONFLICT re-points it to the NEW subscription, so it's the new one
-- that should exact-match after that upsert).
-- (Written as a scalar subquery in SET rather than `FROM LATERAL`: the
-- UPDATE target's own columns, like `ua.user_id` below, are only in scope
-- for a correlated subquery in SET/WHERE, not for a FROM-list item, even a
-- LATERAL one.)
update public.usage_allowances ua
set subscription_id = (
  select s.id
  from public.subscriptions s
  where s.user_id = ua.user_id
    and s.started_at is not null
    and s.valid_until is not null
    and s.started_at::date = ua.period_start
    and s.valid_until::date = ua.period_end
  order by (s.status = 'active') desc, s.started_at desc
  limit 1
)
where ua.subscription_id is null;

-- Pass 2: no exact match (older/messier historical data) -- fall back to
-- any subscription for the same user whose date range overlaps this
-- usage period at all, preferring an active one, then the closest
-- started_at.
update public.usage_allowances ua
set subscription_id = (
  select s.id
  from public.subscriptions s
  where s.user_id = ua.user_id
    and s.started_at is not null
    and s.valid_until is not null
    and s.started_at::date <= ua.period_end
    and s.valid_until::date >= ua.period_start
  order by (s.status = 'active') desc, abs(s.started_at::date - ua.period_start) asc, s.started_at desc
  limit 1
)
where ua.subscription_id is null;

-- Pass 3: truly best-effort last resort -- no overlapping subscription at
-- all (e.g. hand-inserted test data). Link to whichever of that user's
-- subscriptions started closest to this period, overlap or not, rather
-- than leave it unmatched.
update public.usage_allowances ua
set subscription_id = (
  select s.id
  from public.subscriptions s
  where s.user_id = ua.user_id
    and s.started_at is not null
  order by abs(s.started_at::date - ua.period_start) asc, s.started_at desc
  limit 1
)
where ua.subscription_id is null;

-- ------------------------------------------------------------
-- 3. Lock it down -- fail loudly, don't silently leave a gap, if any row
--    truly couldn't be matched (a user with a usage row but no
--    subscription at all ever -- shouldn't exist, since these rows are
--    only ever inserted alongside a subscription insert/update in the
--    same transaction).
-- ------------------------------------------------------------
do $$
declare
  v_missing integer;
begin
  select count(*) into v_missing from public.usage_allowances where subscription_id is null;
  if v_missing > 0 then
    raise exception
      'usage_allowances_subscription_id backfill incomplete: % row(s) have no subscription at all for their user_id -- resolve manually before this migration can proceed',
      v_missing;
  end if;
end $$;

alter table public.usage_allowances
  alter column subscription_id set not null;

create index idx_usage_allowances_subscription_id on public.usage_allowances (subscription_id);

-- ------------------------------------------------------------
-- 4. Both RPCs that insert a usage_allowances row now set subscription_id
--    to the subscription they themselves just created/activated -- never
--    a second lookup, since each already has that id in hand.
-- ------------------------------------------------------------

-- Same body as 20260929100000's confirm_subscription_payment, plus
-- subscription_id in the insert (v_found_id is the subscription this
-- function itself just activated, via `returning id ... into v_found_id`).
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

  insert into public.usage_allowances (user_id, subscription_id, period_start, period_end)
  values (v_user_id, v_found_id, current_date, v_valid_until::date);

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

-- Same body as 20260930170000's upgrade_subscription, plus subscription_id
-- in the insert (v_new_sub_id, the subscription this function itself just
-- created). Also added to the ON CONFLICT branch: a same-day second
-- upgrade (or a same-day payment-then-upgrade) reuses the existing row,
-- and that row must be re-pointed at the NEW subscription -- otherwise it
-- would keep pointing at whichever subscription originally created it,
-- now cancelled, defeating the whole point of this column.
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

  insert into public.usage_allowances (user_id, subscription_id, period_start, period_end)
  values (v_user_id, v_new_sub_id, current_date, v_valid_until::date)
  on conflict (user_id, period_start) do update
    set subscription_id = excluded.subscription_id,
        period_end = excluded.period_end,
        hookah_used = 0,
        drinks_used = 0,
        hookah_alert_sent = false,
        drinks_alert_sent = false;

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
