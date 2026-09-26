-- Sprint 9 Task 1 -- answers the open question decision #33/#41 left
-- standing ("Notifications feed and its backing schema... all
-- undecided"): a notification is a payment activation or an event
-- reservation confirmation, in-app only, read/unread tracked by a real
-- `is_read` flag. The `notifications` table itself already existed
-- (initial_schema.sql) but was never actually written to by anything --
-- this migration is what makes it real, and locks it down properly now
-- that it's about to hold real content.
--
-- Three things happen here, in one migration because they're one
-- feature, not three independent changes:
--
--  1. `related_id` -- a nullable pointer at whatever server-side row
--     caused a notification (a subscription or an event reservation).
--     Not a foreign key: a single column can only reference one table,
--     and this one needs to point at either depending on `type`, so
--     referential integrity here is enforced by the inserting function
--     below (it always sets this to a row id it just wrote or updated
--     itself in the same transaction), not by the schema.
--
--  2. Locking down client access, tighter than the table's original
--     "fully user-managed except DELETE" policies:
--
--     * INSERT: dropped entirely, no replacement. Same pattern as
--       `subscriptions`/`usage_allowances`/`door_access_logs` -- with
--       RLS already enabled and zero INSERT policies left, Postgres
--       denies every client INSERT by default. This is proven for this
--       exact shape already, not just assumed: decision #16 impersonated
--       `authenticated` against `subscriptions` (RLS on, no INSERT
--       policy) and got a real `42501 row violates row-level security
--       policy`, not a silent pass.
--
--     * UPDATE: the existing "own row" USING/WITH CHECK policy already
--       correctly restricts WHICH ROWS a client can touch, so it's left
--       alone -- but RLS row policies can't restrict WHICH COLUMNS an
--       UPDATE touches, and this table's only legitimately
--       client-editable field is `is_read`. Left as RLS-only, a client
--       could legally UPDATE `title`/`body`/`type` on a row it owns --
--       rewriting "Your payment failed" into "Your payment succeeded",
--       say. The real fix is a column-level GRANT: revoke the blanket
--       UPDATE Supabase grants `authenticated` by default on every new
--       table, then grant UPDATE back on `is_read` alone, so Postgres
--       itself rejects the statement with a real permission error the
--       instant any other column appears in a client's SET list --
--       before RLS is even consulted (verified: `permission denied for
--       table notifications`, not a silent success or a row-filtered
--       no-op).
--
--  3. `confirm_subscription_payment` and `create_event_reservation`
--     (both already SECURITY DEFINER, both already the only path that
--     can write their respective real-content tables) each get one more
--     `insert` into `notifications`, inside the same function, same
--     transaction -- no new trigger mechanism, no separate job. Content
--     comes from what each function itself just validated/computed
--     (the real plan name, the real valid_until it set; the real event
--     type/date/guest count it already range-checked), never anything
--     else client-supplied.

-- ------------------------------------------------------------
-- 1. Schema
-- ------------------------------------------------------------

alter table public.notifications
  add column related_id uuid;

comment on column public.notifications.related_id is
  'Points at the subscriptions.id or event_reservations.id that triggered this notification, depending on `type`. Not a foreign key (see this migration''s own header comment) -- always set by the SECURITY DEFINER function that inserts the row, never client-supplied.';

-- ------------------------------------------------------------
-- 2. Locking down client access
-- ------------------------------------------------------------

drop policy "Users can create own notifications" on public.notifications;

revoke update on public.notifications from authenticated;
revoke update on public.notifications from anon;
grant update (is_read) on public.notifications to authenticated;

-- ------------------------------------------------------------
-- 3. Real notifications, written by the functions that already know
--    a real payment/reservation just happened
-- ------------------------------------------------------------

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

  insert into public.notifications (user_id, type, title, body, related_id)
  values (
    v_user_id,
    'subscription_activated',
    'Membership Activated',
    'Your ' || v_plan_name || ' membership is now active until ' || to_char(v_valid_until, 'Mon DD, YYYY') || '.',
    v_found_id
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
  insert into public.notifications (user_id, type, title, body, related_id)
  values (
    v_user_id,
    'event_reservation_confirmed',
    'Event Reservation Confirmed',
    'Your ' || p_event_type || ' reservation on ' || to_char(p_event_date, 'Mon DD, YYYY') ||
      ' at ' || to_char(p_event_date + p_start_time, 'HH12:MI AM') || ' for ' || p_guest_count || ' guests is confirmed.',
    v_reservation_id
  );

  return v_reservation_id;
end;
$$;

revoke execute on function public.create_event_reservation(text, date, time, numeric, integer) from public;
revoke execute on function public.create_event_reservation(text, date, time, numeric, integer) from anon;
grant execute on function public.create_event_reservation(text, date, time, numeric, integer) to authenticated;
