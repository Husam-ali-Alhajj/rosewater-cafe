-- Notifications in the user's language.
--
-- The title and body are fixed English text, so each notification now also stores its details in
-- `data`, and the app builds the text in the current language (see
-- lib/utils/notification_localization.dart). The English text stays as a fallback.
--
-- `data` is only written by the functions below; users can't change it (they can only update
-- `is_read`).
--
-- subscription_activated:      {plan_name, valid_until}
-- event_reservation_confirmed: {event_type, event_date, start_time (HH24:MI), guest_count}
--
-- The functions below are unchanged except that their notification insert also fills `data`.

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
  returning id, plan_id into v_found_id, v_plan_id;

  if v_found_id is null then
    raise exception 'subscription_not_found_or_not_pending';
  end if;

  insert into public.usage_allowances (user_id, period_start, period_end)
  values (v_user_id, current_date, v_valid_until::date);

  -- Notify the user about the payment, using the plan name and date this function just set.
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
  -- Placeholder price until the company gives real numbers. Change it here only (the app uses the
  -- same value for its estimate).
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

  -- Notify the user about the reservation. to_char can't format a plain `time`, so the date and
  -- time are combined into a timestamp first.
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
