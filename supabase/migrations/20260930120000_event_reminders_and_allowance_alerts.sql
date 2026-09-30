-- Event reminders and low-allowance alerts, as in-app notifications. Both skip users who turned
-- that switch off (no preferences row means on).
--
-- - Event reminders: a job every 15 minutes sends one reminder per confirmed reservation once it's
-- within the next 24 hours.
-- - Allowance alerts: a trigger on usage_allowances sends one alert per period (hookah and drinks
-- separately) when 3 or fewer are left. Unlimited plans never get one.
--
-- Note: the app doesn't record usage yet (there's no staff tool), so alerts only fire if usage is
-- updated some other way.

-- The cafe's timezone

-- Reservations store a local date and time, so the reminder job needs the cafe's timezone. Change
-- this if the cafe isn't in New York (daylight saving is handled automatically).
create or replace function public.cafe_timezone()
returns text
language sql
immutable
as $$ select 'America/New_York' $$;

comment on function public.cafe_timezone() is
  'The café''s IANA timezone. Event reservation dates/times are local to it.';

-- Event reminders

-- Set when the reminder is sent, so deleting the reminder notification doesn't cause a second one.
alter table public.event_reservations
  add column reminder_sent_at timestamptz;

create or replace function public.send_event_reminders()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
  v_sent integer := 0;
begin
  for r in
    select er.*
    from public.event_reservations er
    where er.status = 'confirmed'
      and er.reminder_sent_at is null
      -- Local date + time, read in the cafe's timezone
      and (er.event_date + er.start_time) at time zone public.cafe_timezone()
          between now() and now() + interval '24 hours'
      and coalesce(
        (select np.event_reminders from public.notification_preferences np where np.user_id = er.user_id),
        true
      )
    for update of er skip locked  -- never process the same row twice at once
  loop
    insert into public.notifications (user_id, type, title, body, related_id, data)
    values (
      r.user_id,
      'event_reminder',
      'Event Reminder',
      'Your ' || r.event_type || ' reservation is coming up on ' || to_char(r.event_date, 'Mon DD, YYYY') ||
        ' at ' || to_char(r.event_date + r.start_time, 'HH12:MI AM') || ' for ' || r.guest_count || ' guests.',
      r.id,
      jsonb_build_object(
        'event_type', r.event_type,
        'event_date', r.event_date,
        'start_time', to_char(r.start_time, 'HH24:MI'),
        'guest_count', r.guest_count
      )
    );
    update public.event_reservations set reminder_sent_at = now() where id = r.id;
    v_sent := v_sent + 1;
  end loop;
  return v_sent;
end;
$$;

-- Runs over every user, so no app role may call it; only the scheduled job below does.
revoke execute on function public.send_event_reminders() from public;
revoke execute on function public.send_event_reminders() from anon;
revoke execute on function public.send_event_reminders() from authenticated;

do $$
begin
  if exists (select 1 from cron.job where jobname = 'send-event-reminders') then
    perform cron.unschedule('send-event-reminders');
  end if;
end;
$$;

select cron.schedule(
  'send-event-reminders',
  '*/15 * * * *',
  $$select public.send_event_reminders()$$
);

-- Allowance alerts

-- One alert per period for each kind. A new period is a new row, so these start as false again.
alter table public.usage_allowances
  add column hookah_alert_sent boolean not null default false,
  add column drinks_alert_sent boolean not null default false;

create or replace function public.check_low_allowance()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  c_threshold constant integer := 3;  -- alert at 3 or fewer left
  v_hookah_limit integer;
  v_drinks_limit integer;
  v_remaining integer;
begin
  select mp.hookah_limit, mp.drinks_limit
  into v_hookah_limit, v_drinks_limit
  from public.subscriptions s
  join public.membership_plans mp on mp.id = s.plan_id
  where s.user_id = new.user_id and s.status = 'active'
  order by s.started_at desc nulls last
  limit 1;

  if not found then
    return new;  -- no active plan, nothing to compare
  end if;

  if not coalesce(
    (select np.allowance_alerts from public.notification_preferences np where np.user_id = new.user_id),
    true
  ) then
    return new;  -- turned off: send nothing and leave the flags unset
  end if;

  if v_hookah_limit is not null and not new.hookah_alert_sent then
    v_remaining := greatest(v_hookah_limit - new.hookah_used, 0);
    if v_remaining <= c_threshold then
      insert into public.notifications (user_id, type, title, body, related_id, data)
      values (
        new.user_id,
        'allowance_low',
        'Low Allowance Alert',
        case when v_remaining = 0
          then 'You have used all your hookah sessions this month.'
          else 'You have only ' || v_remaining || ' hookah sessions remaining this month.'
        end,
        new.id,
        jsonb_build_object('kind', 'hookah', 'remaining', v_remaining, 'limit', v_hookah_limit)
      );
      new.hookah_alert_sent := true;
    end if;
  end if;

  if v_drinks_limit is not null and not new.drinks_alert_sent then
    v_remaining := greatest(v_drinks_limit - new.drinks_used, 0);
    if v_remaining <= c_threshold then
      insert into public.notifications (user_id, type, title, body, related_id, data)
      values (
        new.user_id,
        'allowance_low',
        'Low Allowance Alert',
        case when v_remaining = 0
          then 'You have used all your drinks this month.'
          else 'You have only ' || v_remaining || ' drinks remaining this month.'
        end,
        new.id,
        jsonb_build_object('kind', 'drinks', 'remaining', v_remaining, 'limit', v_drinks_limit)
      );
      new.drinks_alert_sent := true;
    end if;
  end if;

  return new;
end;
$$;

revoke execute on function public.check_low_allowance() from public;
revoke execute on function public.check_low_allowance() from anon;
revoke execute on function public.check_low_allowance() from authenticated;

-- BEFORE, so the "already sent" flag is saved in the same update.
create trigger trg_usage_allowances_low_alert
before update of hookah_used, drinks_used on public.usage_allowances
for each row execute function public.check_low_allowance();
