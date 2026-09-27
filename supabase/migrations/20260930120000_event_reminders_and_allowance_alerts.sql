-- Notifications roadmap, step 3: the "Event Reminders" and "Allowance
-- Alerts" toggles on Notification Settings now control real in-app
-- notifications (decision #70). Both are created server-side, like every
-- other notification, and both skip users who switched that toggle off
-- (`notification_preferences`, decision #67 -- no row means defaults, on).
--
--  * Event reminders: a pg_cron job every 15 minutes sends ONE reminder
--    per confirmed reservation once it starts within the next 24 hours
--    (the design's example reads "coming up tomorrow at 7:00 PM").
--  * Allowance alerts: a trigger on usage_allowances sends ONE alert per
--    billing period per kind (hookah / drinks) the moment what's left
--    drops to 3 or fewer (the design's example: "only 3 hookah sessions
--    remaining"). Unlimited plans (NULL limit) never get one.
--    NOTE: nothing in the app records usage yet (no staff / point-of-sale
--    tool increments hookah_used/drinks_used), so this can only fire when
--    usage is updated some other way -- it's ready for when that exists.

-- ------------------------------------------------------------
-- The café's timezone, in one place
-- ------------------------------------------------------------

-- Reservations store a local date + time with no timezone ("Oct 4,
-- 7:30 PM"), while now() is an absolute instant, so the reminder job must
-- know which timezone that local time is in. IANA name, so daylight-saving
-- changes are handled by Postgres. Change here at handoff if the café
-- isn't in New York.
create or replace function public.cafe_timezone()
returns text
language sql
immutable
as $$ select 'America/New_York' $$;

comment on function public.cafe_timezone() is
  'The café''s IANA timezone. Event reservation dates/times are local to it.';

-- ------------------------------------------------------------
-- Event reminders
-- ------------------------------------------------------------

-- Set when a reminder is sent. A column on the reservation rather than
-- "does a reminder notification exist" -- the user can delete that
-- notification, which must not cause a second reminder.
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
      -- the local date + time, read as café time -> an absolute instant
      and (er.event_date + er.start_time) at time zone public.cafe_timezone()
          between now() and now() + interval '24 hours'
      and coalesce(
        (select np.event_reminders from public.notification_preferences np where np.user_id = er.user_id),
        true
      )
    for update of er skip locked -- never two overlapping runs on one row
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

-- A batch job over every user's rows -- no client role may call it (same
-- as expire_subscriptions); only the pg_cron schedule below runs it.
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

-- ------------------------------------------------------------
-- Allowance alerts
-- ------------------------------------------------------------

-- Once per billing period per kind: a new period is a new usage_allowances
-- row, so these start false again automatically.
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
  c_threshold constant integer := 3; -- "3 or fewer left" (decision #70)
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
    return new; -- no active plan, nothing to measure against
  end if;

  if not coalesce(
    (select np.allowance_alerts from public.notification_preferences np where np.user_id = new.user_id),
    true
  ) then
    return new; -- switched off: send nothing, and leave the flags unset
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

-- BEFORE, so the "already sent" flag is set on the same row write that
-- triggered the alert (an AFTER trigger would need a second UPDATE).
create trigger trg_usage_allowances_low_alert
before update of hookah_used, drinks_used on public.usage_allowances
for each row execute function public.check_low_allowance();
