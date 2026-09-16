-- create_event_reservation: the only way a row gets written to
-- event_reservations from the client. `total_price` is computed
-- server-side and is NOT a function parameter -- there is no path for a
-- caller to supply their own price, by construction, not just by
-- convention.
--
-- This also closes a gap the table's own RLS left open: event_reservations
-- already had an "insert own rows" policy for `authenticated` (unlike
-- subscriptions/usage_allowances/door_access_logs, which were RPC-only
-- from the start -- see decision #4/#16). That policy let a client insert
-- a row directly with whatever `total_price` it wanted, completely
-- bypassing server-side pricing. This migration drops that policy so
-- this function becomes the only INSERT path, the same way every other
-- money-shaped table in this project already works.
--
-- Security model, same pattern as every prior RPC (start_subscription,
-- cancel_subscription, confirm_subscription_payment, expire_subscriptions,
-- log_door_access):
--
--  * SECURITY DEFINER with `search_path` pinned to `public`.
--  * Reads auth.uid() itself rather than accepting a user_id argument.
--  * EXECUTE is revoked from PUBLIC *and*, explicitly, from `anon`
--    (Supabase grants EXECUTE to `anon` per-function regardless of a
--    bare `revoke ... from public` -- decision #16).
--
-- Two checks this function does NOT trust the client for:
--
--  1. Guest count: the design's own stated range is 5-100 guests for a
--     private event booking (a wholly different field from the Door
--     Access screen's 0-2 "guests you're bringing in" -- decision #33
--     called this naming collision out explicitly so the two are never
--     conflated).
--  2. Event date: rejects anything before today. Not layered with any
--     availability/double-booking logic -- that's a separate feature this
--     project doesn't have, not attempted here.
--
-- Deliberately inserts with status = 'confirmed', not 'pending', even
-- though `reservation_status` has a 'pending' value: no screen in this
-- app has any approval/review workflow for event reservations, so a
-- 'pending' status would just be a permanent dead end with nothing to
-- ever move it to 'confirmed'. Logged as decision #36 rather than
-- building an approval flow nobody asked for and no screen would ever
-- act on.
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

  return v_reservation_id;
end;
$$;

revoke execute on function public.create_event_reservation(text, date, time, numeric, integer) from public;
revoke execute on function public.create_event_reservation(text, date, time, numeric, integer) from anon;
grant execute on function public.create_event_reservation(text, date, time, numeric, integer) to authenticated;

-- Close the direct-insert bypass described above.
drop policy if exists "Users can create own reservations" on public.event_reservations;
