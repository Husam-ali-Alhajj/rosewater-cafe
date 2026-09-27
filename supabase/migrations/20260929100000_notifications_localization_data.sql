-- Sprint 9 Task 1 follow-up: notifications in the user's language.
--
-- `title`/`body` (20260928100000) are English sentences baked at insert
-- time, so an Arabic user would read "Membership Activated" -- and a
-- language switch could never re-translate an existing row. Rather than
-- adding title_ar/body_ar (duplicating the app's Arabic event-type names
-- in SQL, and a new column pair per future language), each row now also
-- stores the FACTS it reports, in `data`, and the app builds the text in
-- whatever language is active from its own translation files (see
-- lib/utils/notification_localization.dart). `title`/`body` stay as an
-- English fallback for any type the app doesn't know yet.
--
-- `data` is written only by the two SECURITY DEFINER functions below,
-- from the same values they already validated/computed, never anything
-- else client-supplied. It is NOT client-updatable: the column-level
-- `grant update (is_read)` from 20260928100000 still covers only
-- is_read, and a new column gets no UPDATE grant of its own.
--
--   subscription_activated:      {plan_name, valid_until}
--   event_reservation_confirmed: {event_type, event_date, start_time (HH24:MI), guest_count}
--
-- Both functions below are 20260928100000's versions verbatim except the
-- notification insert, which now also fills `data`.

alter table public.notifications
  add column data jsonb not null default '{}'::jsonb;

comment on column public.notifications.data is
  'The facts this notification reports (shape depends on `type` -- see this migration''s header), so the app can render it in the user''s language. Server-written only.';

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
  returning id, plan_id into v_found_id, v_plan_id;

  if v_found_id is null then
    raise exception 'subscription_not_found_or_not_pending';
  end if;

  insert into public.usage_allowances (user_id, period_start, period_end)
  values (v_user_id, current_date, v_valid_until::date);

  -- Sprint 9 Task 1: a real notification for the payment that just
  -- happened -- the plan name and valid_until are read back from what
  -- this function itself just resolved/computed above, not re-derived
  -- from anything the client could influence.
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

create or replace function public.create_event_reservation(
  p_event_type text,
  p_event_date date,
  p_start_time time,
  p_duration_hours numeric,
  p_guest_count integer
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  -- Placeholder flat pricing, pending real numbers from the company (see
  -- docs/decisions.md #33/#36). One named constant here means plugging in
  -- real pricing later is a one-line change in one place, not a hunt
  -- through the codebase for every place a price was computed.
  c_price_per_hour constant numeric := 150.00;
  v_total_price numeric;
  v_reservation_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_guest_count is null or p_guest_count < 5 or p_guest_count > 100 then
    raise exception 'guest_count_out_of_range'
      using detail = json_build_object(
        'min', 5,
        'max', 100,
        'requested', p_guest_count
      )::text;
  end if;

  if p_event_date is null or p_event_date < current_date then
    raise exception 'event_date_in_past';
  end if;

  v_total_price := p_duration_hours * c_price_per_hour;

  insert into public.event_reservations (
    user_id, event_type, event_date, start_time, duration_hours, guest_count, status, total_price
  )
  values (
    v_user_id, p_event_type, p_event_date, p_start_time, p_duration_hours, p_guest_count, 'confirmed', v_total_price
  )
  returning id into v_reservation_id;

  -- Sprint 9 Task 1: same pattern as confirm_subscription_payment above
  -- -- a real notification from what this call already validated
  -- (event type/date/guest count), inside the same transaction as the
  -- reservation it's reporting.
  -- `to_char` has no overload for a bare `time` (no implicit cast to
  -- anything it accepts) -- (p_event_date + p_start_time) combines them
  -- into a real `timestamp` first, the standard Postgres `date + time`
  -- operator, so the time-of-day formats correctly.
  insert into public.notifications (user_id, type, title, body, related_id, data)
  values (
    v_user_id,
    'event_reservation_confirmed',
    'Event Reservation Confirmed',
    'Your ' || p_event_type || ' reservation on ' || to_char(p_event_date, 'Mon DD, YYYY') ||
      ' at ' || to_char(p_event_date + p_start_time, 'HH12:MI AM') || ' for ' || p_guest_count || ' guests is confirmed.',
    v_reservation_id,
    jsonb_build_object(
      'event_type', p_event_type,
      'event_date', p_event_date,
      'start_time', to_char(p_start_time, 'HH24:MI'),
      'guest_count', p_guest_count
    )
  );

  return v_reservation_id;
end;
$$;

revoke execute on function public.create_event_reservation(text, date, time, numeric, integer) from public;
revoke execute on function public.create_event_reservation(text, date, time, numeric, integer) from anon;
grant execute on function public.create_event_reservation(text, date, time, numeric, integer) to authenticated;
